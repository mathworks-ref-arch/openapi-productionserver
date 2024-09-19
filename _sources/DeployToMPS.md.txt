# Deploy as endpoint to MATLAB Production Server

It is possible to add a live endpoint to MATLAB Production Server which can return the OpenAPI spec for the functionality deployed to the instance. It is for example possible to wrap the OpenAPI spec generator in a [Custom Routes and Payloads function](https://www.mathworks.com/help/releases/R2024a/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html) which first queries the server's discovery endpoint, then uses the generator to translate this to an OpenAPI spec and then returns the OpenAPI YAML document.

An *example* wrapper is included in the package:

```{literalinclude} ../Software/MATLAB/examples/mps/openapiEndpoint.m
:language: matlab
:caption: Software/MATLAB/examples/mps/openapiEndpoint.m
```

This is "just an example" as it is meant to be customized. For example it is possible to configure whether or not to include the asynchronous interface, or to add authentication information, etc. Most importantly however, the code which queries the discovery endpoint may have to be customized; see the next section.

## Querying the discovery endpoint

There is no dedicated internal or loopback endpoint or function inside MATLAB Production Server which allows retrieving the discovery document directly from MATLAB code running on the instance. And so, the wrapper MATLAB code will have to query the "external" `/api/discovery` endpoint in the same way as any other MATLAB Production Server client would.

```{hint}
The discovery endpoint needs to be enabled for it to be available, see [`--enable-discovery`](https://www.mathworks.com/help/mps/server/mps.configuration-properties.html#propname_enable-discovery).
```

From the MATLAB wrapper point of view, the easiest option is to query the discovery endpoint over `http` (and not `https`), and ideally the server can simply refer to itself by `localhost` (or `127.0.0.1`). In that case the code does not have to be customized *per MATLAB Production Server instance* and the same CTF-archive can be used across different MATLAB Production Server instances.

*   If `http` is **enabled** on the instance anyway, this should indeed simply work.

*   If `http` has been **disabled** on the instance and it is configured to listen on `https` *only*:

    *   It may be worth considering simply enabling `http` again. Note that it is possible to configure the instance to only listen on a specific network interface (see the [--http **host**:port](https://www.mathworks.com/help/mps/server/mps.configuration-properties.html#buf0ewd) option), i.e. it is possible to enable `http` for `localhost` or `127.0.0.1` *only* such that only *local* applications on the same machine can access the instance over `http` but all *external* traffic still has to go over `https`. And/or it is possible to configure the `http` endpoint to listen on a port which is explicitly blocked for all external traffic. Some firewalls may even be able to limit the internal traffic and only allow specific processes to access the port or only allow local communication between processes *running under the same user account*.

    *   It is also possible to query the `/discovery/api` endpoint over `https` but:

        *   It is unlikely then that the instance can be referenced by `localhost` as the https certificate is unlikely to be valid for hostname `localhost`. Ensure to update the code to refer to the correct hostname.

        *   If the https certificate is self-signed (or at least not signed by an certificate authority which MATLAB trusts *by default*) the request will have to be configured to accept the server certificate explicitly.

            1.  Download the certificate in PEM-format and for example save it as `YourServerCertificate.pem`.

            2.  Update the MATLAB code to accept this certificate when querying the endpoint:
                
                ```matlab
                opts = weboptions('CertificateFilename','YourServerCertificate.pem');
                discovery = webread('https://example.com/api/discovery',opts);
                ```

        ````{note}
        Technically it is also possible to disable certificate trust validation altogether by setting `CertificateFilename` to an empty string `''`.  And it is even possible to disable host name verification when switching to working with the [HTTP interface in MATLAB](https://www.mathworks.com/help/matlab/http-interface.html):

        ```matlab
        % DANGER: Disable both hostname as well as certificate trust validation
        opts = matlab.net.http.HTTPOptions('CertificateFilename','','VerifyServerName',false);
        % Start a new request
        req = matlab.net.http.RequestMessage();
        % Perform the request with the specified options
        result = req.send('https://localhost:9920/api/discovery',opts);
        % Obtain the response body data
        discovery = result.Body.Data;
        ```

        These options are not recommended however and should only be considered for temporary testing.
        ````

### Summary

The following points can be taken into consideration when choosing how to access the discovery endpoint. It is important however that in the end *you* make *your own* security assessment and *you* choose the option(s) which meet(s) *your* requirements.

1.  `http` is easier from the MATLAB wrapper point of view, there are no certificates in play and the instance should be able to simply refer to itself as `localhost`. Also this requires just a single CTF-archive which can be used across different MATLAB Production Server instances.

2.  In general `https` communication is more secure but involves certificates which will likely require customization of the wrapper. The customization will likely differ *per MATLAB Production Server instance*. Each instance may require a custom CTF-archive specifically build for that specific instance.

3.  Some security concerns related to using `http` may be mitigated by simply binding the http listener to `localhost` only. This is done through a simple configuration option on the MATLAB Production Server instance.

4.  Concerns with `http` which are not addressed by 3. may require further (more complex) firewall configurations. In that case, due to this added complexity, the advantages of 1. may no longer outweigh the disadvantages of 2. and it might be easier to stick/switch to working over `https` only.


## Customizing other aspects of the wrapper

As shown in the example, other aspects of the wrapper can be customized as well. It is possible to configure the various [options for the OpenAPI spec generator](./Usage.md#prodserveropenapi). It is possible to customize the "interface" of the endpoint, e.g. add additional query parameters to allow configuring the behavior. See [Write MATLAB Functions for Web Request Handler](https://www.mathworks.com/help/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html) in the MATLAB Production Server documentation to learn more about implementing these kinds of functions.

## URL Routes

A custom route must be configured to make the endpoint work correctly. As [documented](https://www.mathworks.com/help/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html#mw_1c57566a-9876-44ca-9f07-f67709bfb3f1), routes can be configured on an instance level or archive level (in releases R2023b and newer). The easiest option is to make use of archive level routes as this requires no further configuration and restart of the MATLAB Production Server instance(s). An example archive level routes file is included as `routes.json`:

```{literalinclude} ../Software/MATLAB/examples/mps/routes.json
:language: matlab
:caption: Software/MATLAB/examples/mps/routes.json
```

If an instance level configuration is desired/required, update the routes configuration file (typically `config/routes.json`) on the instance(s).

## Compile

To build the CTF-archive with archive level routes, use:

```matlab
compiler.build.productionServerArchive(...
    'openapiEndpoint.m',...
    ArchiveName='openapi',...
    RoutesFile='routes.json');
```

Note that with archive level routes, the endpoint will become `http(s)://example.com/`*`ArchiveName`*`/`*`RouteAsDefinedInRoutesFile`*. 

Choose `ArchiveName` and configure the routes file appropriately to make the functionality available at the desired endpoint. E.g. with the routes file as included in the example and the archive name used above, the final endpoint becomes `http://example.com/openapi/spec`.

## Deploy

As with any other component, copy the resulting CTF-archive to the `auto_deploy` folder of the MATLAB Production Server instance(s). If working with instance level routes, restart the MATLAB Production Server instance after having updated the routes configuration file.

[//]: #  (Copyright 2023-2024 The MathWorks, Inc.)