function res = openapiEndpoint(req)
%OPENAPIENDPOINT MATLAB Production Server wrapper for prodserver.openapi 
%
% This wrapper facilitates adding a live endpoint to MATLAB Production
% Server which returns an OpenAPI spec for the functionality served on the
% server. This is accomplished by first querying the server's discovery
% endpoint, translating the proprietary discovery format to OpenAPI format
% and then returning the OpenAPI YAML document.
%
% IMPORTANT: the code in this example may need to be customized, especially
% the part which queries the live MATLAB Production Server discovery
% endpoint. There is no dedicated internal endpoint for this and therefore
% this wrapper will need to query the generic (external) endpoint. How this
% can or should be done will depend on the specific MATLAB Production
% Server deployment. It for example matters whether the server is
% accessible over HTTP or over HTTPS only and for HTTPS it may be relevant
% which certificate is used.
%
% Other parts of the implementation can be changed as well, it is for
% example possible to choose whether or not to include the asynchronous
% interface (by default) or to include authentication information, etc.
%
% Further, the implementation uses Custom Routes and Payloads in order to
% be able to directly return the YAML document and not output the data in
% MATLAB Production Server JSON format.

% Copyright 2023-2024 The MathWorks, Inc.

%% Parse the request
% In this example we allow the endpoint to be queried with a query
% parameter 'async' which can be set to true or false (default = false),
% i.e. you can query http://localhost:9910/api/openapi?async=true
% In that case we include the asynchronous interface in the OpenAPI
% spec. This can be customized, e.g. the default can be changed, the option
% can be removed entirely, or you can add additional other options in a
% similar way to allow configuring other aspects of the OpenAPI spec
% generation.

% Parse the Path of the request into a MATLAB URI 
uri = matlab.net.URI(req.Path);
% Which then allows easy access to query parameters
q = uri.Query;
% If there is a parameter 'async' and it is set to true, enable including
% the async interface in the spec
if ~isempty(q) && any([q.Name]=="async") && q([q.Name]=="async").Value == "true"
    async = true;
else % if not set, default to false
    async = false;
end

%% Query the discovery endpoint
% In most cases, just use default weboptions, but this can be customized
% for example to allow working with a self-signed certificate if working
% over https.
opts = weboptions();
% Query the discovery endpoint with the specified options. This may have to
% be updated to work over https and/or the server name may have to be
% changed.
discovery = webread('http://localhost:9910/api/discovery', opts);

%% Translate discovery document to OpenAPI spec
% In this example the Async setting is configurable through a query
% parameter, pass along the chosen value to the generator. This can be
% changed/customized, the settings can always be turned on or off or other
% options can be set, either hardcoded or also configurable through a query
% parameter.
openapiGenerator = prodserver.openapi(Async=async);
spec = openapiGenerator.generate(discovery);

%% Return the OpenAPI spec
% This should not require any customization; this simply returns the
% generated spec in the correct encoding, with the right HTTP headers set.
res = struct( ...
    'HttpCode',200, ...
    'HttpMessage',matlab.net.http.StatusCode(200).getReasonPhrase, ...
    'Headers',{{'Content-Type','application/openapi+yaml'}}, ...
    'Body',unicode2native(spec,'UTF-8'));
