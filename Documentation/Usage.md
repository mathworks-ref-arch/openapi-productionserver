# Usage

The package main functionality is implemented as a MATLAB class `prodserver.openapi` with various configuration options and a `generate` method which generates a YAML OpenAPI specification based on a MATLAB Production Server Discovery document (imported as MATLAB structure); the document is returned as string.

It is possible to build your own higher level functionality, which for example first downloads and parses the discovery document into a struct and which writes the resulting document to file, on top of this.

An example wrapper function is included in the package which can help deploying the functionality as an endpoint to MATLAB Production Server itself, also see [](./DeployToMPS.md).

## prodserver.openapi

The `prodserver.openapi` class has various properties with which the behavior of the generator can be configured.

:OpenAPIVersion: Generate an OpenAPI Specification compatible with the specified OpenAPI version.\
    *Type: `string`*\
    *Default: `"3.0.3"`*\
    *Valid options: `"3.0.3"`, `"3.1.0"`*

:Version: Sets the version of the OpenAPI document (which is distinct from the the OpenAPI Specification Version as set by `OpenAPIVersion`). It for example makes sense to change this version number if CTFs are added or removed from the server or if functions are added or removed from a package or if the in- or outputs of a function change, i.e. anything which changes the "interface" of the RESTful API which consumers can call. This allows consumers of the APIs to clearly recognize when the interfaces have changed and they can for example more easily recognize that they might be working with a outdated copy of the specification (and they need to obtain a new version). Since the package cannot automatically track what may- or may not have changed over time on the MATLAB Production Server instance, the version number which is included in the generated document must be manually configured through this property.\
    *Type: `string`*\
    *Default: `"1.0.0"`*

:Server: Specifies the server addresses to be included in the specification. This is a hint to the consumers of the specification to indicate which server(s) they can work with when consuming your API. Consumers can choose to ignore this and can typically connect to other instances (serving the same functionality) as well.\
    *Type: `string` scalar or array*\
    *Default: `"http://localhost:9910/"`*

:HeterogeneousArraySpecifier: Specifies how items are defined for heterogenous arrays in 3.0.3 format. This can be done using an `anyOf` or `oneOf` schema. The official OpenAPI 3.0.3 is unclear about which option should be used (also see [](./MPSOpenAPI.md#heterogenous-array-item-definition)) therefore this can be user configured.\
    *Type: `string`*\
    *Default: `"anyOf"`*\
    *Valid options: `"anyOf"`, `"oneOf"`*

:Async: Specifies whether or not to include the [asynchronous interface](https://www.mathworks.com/help/mps/restfuljson/restful-api.html#bvnvw_3) in the generated spec. Note that since the output of the [result](https://www.mathworks.com/help/mps/restfuljson/getresultofrequest.html) endpoint depends on which function the result is being retrieved for, its response cannot be accurately described in the generated spec and is therefore simply defined as to return "an object" with no further details. For documentation purposes it *does* refer back to the outputs of the synchronous versions of the function calls.\
    *Type: `logical`*\
    *Default: `false`*

:OAuth: Includes authentication information in the spec. For example, enable this if the server is configured with [OAuth based Application Access Control](https://www.mathworks.com/help/mps/server/access_control.html). When enabling this options, also configure `AuthorizationUrl` and `TokenUrl`.\
    *Type: `logical`*\
    *Default: `false`*

:AuthorizationUrl:  When `OAuth` == `true` specifies the Authorization URL to include with the authentication information in the spec.\
    *Type: `string`*\
    *Default: `"https://www.example.com/auth"`*

:TokenUrl:  When `OAuth` == `true` specifies the Token URL to include with the authentication information in the spec.\
    *Type: `string`*\
    *Default: `"https://www.example.com/token"`*



Properties can be set after instantiating the object instance:

```matlab
openapiGenerator = prodserver.openapi();
openapiGenerator.Version = "3.14.0";
openapiGenerator.Async = true;
```

Or alternatively it is also possible to pass the properties and their desired values as name-value pairs to the constructor, for example:

```matlab
openapiGenerator = prodserver.openapi('Version', '3.14.0', 'Async', true);
```

or:

```matlab
openapiGenerator = prodserver.openapi(Version="3.14.0", Async=true);
```

## Examples

```matlab
%% Create the generator instance
openapiGenerator = prodserver.openapi();

%% Configure the generator instance
% For example, specify the version of the API
openapiGenerator.Version = "3.14.0";
% For example, specify that the asynchronous interface should be included in the spec
openapiGenerator.Async = true;

%% Use the generate method on a MATLAB Production Server Discovery document imported as MATLAB structure
% For example, query the live discovery endpoint of a MATLAB Production Server Instance
discovery = webread("http://localhost:9910/api/discovery");
% Or alternatively, it is also possible to read a previously downloaded document
% discovery = jsondecode(fileread("discovery.json"));

% Call the generate method on the structure
openApiSpec = openapiGenerator.generate(discovery);

% This returned a string representation of the OpenAPI spec in YAML format.
% For example, display it
disp(openApiSpec)
```

## Important Notes

As noted in the main package description, the package *translates* the proprietary JSON format of [MATLAB Production Server's Discovery Service](https://www.mathworks.com/help/mps/restfuljson/restful-api-for-discovery-and-diagnostics.html#mw_d710d743-384a-434f-b4ab-2b5941e56ca8) into OpenAPI specifications. It is therefore important to note that it will only be able to generate OpenAPI specs for functionality for which discovery information _is_ in fact available. It is up to archive authors to ensure this information is included in the archive and the included information is correct. If a function is not included in the discovery document it will not show up in the generated OpenAPI spec. If an archive does not contain discovery information at all, the entire archive will not show up in the generated OpenAPI spec either.

Similarly, the accuracy of the generated OpenAPI spec will depend on the accuracy of the discovery information. For example, if the size of a variable is not specified in the discovery document, the generated OpenAPI spec will also lack this piece of information.

Also, if there are mistakes in the discovery information, the generated OpenAPI spec will likely be inaccurate as well. The package does not dynamically verify the validity of the discovery document before translation, nor does it verify the correctness of the generated OpenAPI spec after generation. I.e. it does *not* try to invoke the function based on the original or generated spec to verify its correctness against the deployed functionality.

## Further usage

### Deployed as endpoint on MATLAB Production Server

To learn more about how to deploy the OpenAPI generator as an endpoint on MATLAB Production Server itself, see [](./DeployToMPS.md).

### As MATLAB Compiler standalone application

To be able to use the tooling outside of MATLAB without needing a MATLAB license, it is possible to first write a wrapper function, for example:

```{literalinclude} ../Software/MATLAB/examples/standalone/productionServerOpenAPI.m
:language: matlab
:caption: Software/MATLAB/examples/standalone/productionServerOpenAPI.m
```

And then compile this into a [MATLAB Compiler standalone application](https://www.mathworks.com/help/compiler/standalone-applications.html):

```matlabsession
>> compiler.build.standaloneApplication("productionServerOpenAPI.m")
```

This can then be used on any system with the correct [MATLAB Runtime](https://www.mathworks.com/products/compiler/matlab-runtime.html) version installed. For example, on Linux:

```console
$ ./productionServerOpenAPI "http://localhost:9910/api/discovery" "myspec.yaml"
```

or on Windows:

```doscon
C:\Work>productionServerOpenAPI.exe "http://localhost:9910/api/discovery" "myspec.yaml"
```

The wrapper can be further customized to configure the generator differently or for example, print the output rather than write it to file or allow end-user to specify addition/other inputs on the command line.

### In CI/CD pipelines

To use the generator in CI/CD pipelines it is possible to first compile the generator into a standalone application as discussed in the [previous](#as-matlab-compiler-standalone-application) section and then call the standalone application from a CI/CD script.

Alternatively, it is possible to simply run as MATLAB code inside MATLAB see the [Continuous Integration (CI)
](https://www.mathworks.com/help/matlab/continuous-integration.html) section in the MATLAB documentation to learn more about using MATLAB in CI/CD pipelines.

[//]: #  (Copyright 2023-2024 The MathWorks, Inc.)