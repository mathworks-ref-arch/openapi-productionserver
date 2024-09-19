classdef openapi < handle
%prodserver.openapi Generates OpenAPI specs based on MATLAB Production Server
%discovery JSON documents
%
% prodserver.openapi Methods:
%
%   prodserver.openapi - constructor
%   generate           - generates the spec
%
% prodserver.openapi Properties:
%
%   OAuth - Specifies whether the server requires authentication. If set
%       to true authentication information is included in the OpenAPI
%       spec; set AuthorizationUrl and TokenUrl to specify 
%       authentication details.
%   AuthorizationUrl - The authorization URL to include in the
%       authentication configuration if OAuth is set to true.
%   TokenUrl - The token URL to include in the
%       authentication configuration if OAuth is set to true.
%   Async - Specifies whether or not to include the asynchronous interface
%       in the generated OpenAPI spec.
%   Server - Server address to include in the OpenAPI spec.
%   Version - Version to include in OpenAPI info object.
%   OpenAPIVersion - OpenAPI Version to use for the spec.
%   HeterogeneousArraySpecifier - Whether to use anyOf or oneOf in 
%       heterogeneous array item definitions.
%
% Example: read discovery information, create an prodserver.openapi instance and
% generate the OpenAPI spec.
%
%   discovery = webread('http://localhost:9910/api/discovery');
%   m = prodserver.openapi();
%   openApi = m.generate(discovery);

% Copyright 2023-2024 The MathWorks, Inc.

    properties
        % Specifies whether the server requires OAuth authentication. If so
        % and set to true, OAuth authentication information is included in
        % the generated OpenAPI spec; set AuthorizationUrl and TokenUrl to
        % specify authentication details.
        OAuth logical = false
        % The authorization URL to include in the authentication 
        % configuration if OAuth is set to true.
        AuthorizationUrl string = "https://www.example.com/auth"
        % The token URL to include in the authentication configuration if
        % OAuth is set to true.
        TokenUrl string = "https://www.example.com/token"
        % Specifies whether to include the asynchronous interface in the
        % generate OpenAPI spec.
        Async logical = false
        % Server address to include in the generated OpenAPI spec.
        Server string = "http://localhost:9910/"
        % Version to include in OpenAPI info object. This is not the
        % OpenAPI version but the version of the API. Typically the version
        % changes if functions are added or removed of if any of the inputs
        % of functions change. Since the tooling cannot automatically
        % determine whether any of this has changed, set this Version
        % manually.
        Version string = "1.0.0"
        % OpenAPI Version to generate spec for.
        OpenAPIVersion string {mustBeMember(OpenAPIVersion, ["3.0.3","3.1.0"])} = "3.0.3"
        % Whether to use anyOf or oneOf in heterogeneous array item
        % definitions.
        HeterogeneousArraySpecifier string {mustBeMember(HeterogeneousArraySpecifier,["anyOf","oneOf"])} = "anyOf"
    end
    properties (Access={?prodserver.openapi, ?matlab.unittest.TestCase})
        root
        y
    end

    methods
        function obj = openapi(options)
            %prodserver.openapi constructor
            % m = prodserver.openapi() instantiates a new generator
            %
            % m = prodserver.openapi(...'Server','https://example.com/') specifies
            % the server URL to include in the spec.
            %
            % m = prodserver.openapi(...,'Async', true,...) adds the asynchronous
            % interface to the generated spec.
            %
            % m = prodserver.openapi(...,'OAuth', true,...
            %       'AuthorizationUrl', 'https://www.example.com/auth', ...
            %       'TokenUrl', 'https://www.example.com/token', ...) adds
            % authentication information to the generated spec.
            arguments
                options.?prodserver.openapi
            end
            for p = string(fieldnames(options))'
                obj.(p) = options.(p);
            end
            
            obj.y = prodserver.internal.YamlWriter();
        end
        function out = generate(obj,context)
            %GENERATE generates the OpenAPI spec based on provided context
            %
            % openApi = generate(obj,context) generates the spec based on the
            % given context where context is a (jsondecoded) struct
            % representing the MATLAB Production Server discovery document.
            %
            % Examples:
            %
            %   % Read MPS discovery information from a file
            %   s = jsondecode(fileread('discovery.json'))
            %   % Create the prodserver.openapi instance
            %   mps_oas = prodserver.openapi();
            %   % Generate the document
            %   openApi = mps_oas.generate(s)

            % Check the input
            if ~isstruct(context)
                error('prodserver:openapi:notstruct','Expected context to be a structure.\nHint: JSONDECODE can be used to parse a string discovery document into a structure.');
            end
            

            % Reset the document generator to avoid duplicate documents if
            % running the generator multiple times
            obj.y = prodserver.internal.YamlWriter();

            obj.root = context;
            obj.createDocument();
            out = obj.y.ToString;
        end
    end
    methods (Access={?prodserver.openapi, ?matlab.unittest.TestCase})
        %% Main Generator
        function createDocument(obj)
archives = fieldnames(obj.root.archives);
            obj.y.WL('openapi: "%s"',obj.OpenAPIVersion);
            obj.y.WL('info:');
            obj.y.WL('  title: "API for MPS archives %s."',strjoin(archives,","));
            obj.y.WL('  version: "%s"',obj.Version);
            obj.y.WL('servers:');
for i=1:length(obj.Server)
            obj.y.WL('- url: "%s"',obj.Server(i));
end            
            obj.y.WL('paths:');
for archiveName = string(archives)'
    archive = obj.root.archives.(archiveName);
    for funcName = string(fieldnames(archive.functions))'
        func = archive.functions.(funcName);
            obj.y.WL('  /%s/%s:',archiveName,funcName);
            obj.y.WL('    post:');
            obj.y.WL('      tags:');
            obj.y.WL('      - %s',archiveName);
            obj.y.WL('      summary: "%s function in %s package."',funcName,archiveName);
        sig = func.signatures;
            obj.y.WL('      description: |');
            obj.addHelp(sig);
            obj.y.WL('      operationId: "post_%s_%s"',archiveName,funcName);
if obj.OAuth
            obj.y.WL('      security:');
            obj.y.WL('      - oauth2: []');
end
if obj.Async
            obj.y.WL('      parameters:');
            obj.y.WL('      - $ref: "#/components/parameters/ModeParameter"');
            obj.y.WL('      - $ref: "#/components/parameters/ClientParameter"');
end
            obj.y.WL('      requestBody:');
            obj.y.WL('        content:');
            obj.y.WL('          application/json:');
            obj.y.WL('            schema:');
            obj.y.WL('              type: "object"');
            obj.y.WL('              properties:');
            obj.y.WL('                rhs:');
            obj.y.WL('                  type: "array"');
switch obj.OpenAPIVersion
    case "3.0.3"

            obj.y.WL('                  items:');
            obj.y.WL('                    %s:',obj.HeterogeneousArraySpecifier);
        for inputIndex = 1:length(sig.inputs)
            input = getItem(sig.inputs,inputIndex);
            obj.y.WL('                    - type: "object"');
            obj.addMWArray(input,archiveName);
        end
            obj.y.WL('                  minItems: 0');
        if ~hasVarargin(sig.inputs)
            obj.y.WL('                  maxItems: %d',length(sig.inputs));
        end
    case "3.1.0"
        if ~hasVarargin(sig.inputs)
            obj.y.WL('                  items: false');
        end            
            obj.y.WL('                  prefixItems:');
        for inputIndex = 1:length(sig.inputs)
            input = getItem(sig.inputs,inputIndex);
            obj.y.WL('                  - type: "object"');
            obj.addMWArray(input,archiveName);
        end
end                    
            obj.y.WL('                nargout:');
            obj.y.WL('                  type: "integer"');
            obj.y.WL('                  format: "int64"');
            obj.y.WL('                  minimum: 0');
if ~hasVarargout(sig.outputs)
            obj.y.WL('                  maximum: %d',length(sig.outputs));
end
            obj.y.WL('                outputFormat:');
            obj.y.WL('                  $ref: "#/components/schemas/OutputFormat"');
            obj.y.WL('              required:');
            obj.y.WL('              - rhs');
            obj.y.WL('              - nargout');
            obj.y.WL('      responses:');
            obj.y.WL('        200:');
            obj.y.WR('          description: "');
if obj.Async
            obj.y.WR('When working in synchronous mode: ');
end
            obj.y.WR('Function output or error"\n');
            obj.y.WL('          content:');
            obj.y.WL('            application/json:');
            obj.y.WL('              schema:');
            obj.y.WL('                oneOf:');
            obj.y.WL('                - type: "object"');
            obj.y.WL('                  properties:');
            obj.y.WL('                    lhs:');
switch obj.OpenAPIVersion
    case "3.0.3"
            obj.y.WL('                      type: "array"');
            obj.y.WL('                      items:');
            obj.y.WL('                        %s:',obj.HeterogeneousArraySpecifier);
        for outputIndex = 1:length(sig.outputs)
            output = getItem(sig.outputs,outputIndex);
            obj.y.WL('                        - type: "object"');
            obj.addMWArray(output,archiveName);
        end
    case "3.1.0"
            obj.y.WL('                      type: "array"');
if ~hasVarargout(sig.outputs)            
            obj.y.WL('                      items: false');            
end
            obj.y.WL('                      prefixItems:');
        for outputIndex = 1:length(sig.outputs)
            output = getItem(sig.outputs,outputIndex);
            obj.y.WL('                      - type: "object"');
            obj.addMWArray(output,archiveName);
        end

end

            obj.y.WL('                - $ref: "#/components/schemas/ErrorResponse"');
if obj.Async
            obj.y.WL('        201:');
            obj.y.WL('          description: "When working in asynchronous mode: Request created successful."');
            obj.y.WL('          content:');
            obj.y.WL('            application/json:');
            obj.y.WL('              schema:');
            obj.y.WL('                $ref: "#/components/schemas/AsyncRequestInfo"');
end
            obj.y.WL('        400:');
            obj.y.WL('          description: Invalid request. Possibly request body is invalid JSON.');
    end
end
if obj.Async
            obj.y.CurrentIndent = 2;
            obj.addAsyncEndpoints;
end
            
            obj.y.WL('components:');
            obj.y.WL('  schemas:');
if obj.Async
            obj.addAsyncSchemas;
end
            obj.y.WL('    ErrorResponse:');
            obj.y.WL('      type: "object"');
            obj.y.WL('      properties:');
            obj.y.WL('        error:');
            obj.y.WL('          type: "object"');
            obj.y.WL('          properties:');
            obj.y.WL('            id:');
            obj.y.WL('              type: "string"');
            obj.addExample('"myFunction:errorId"');
            obj.y.WL('            message:');
            obj.y.WL('              type: "string"');
            obj.addExample('"Some Error Message."');
            obj.y.WL('            stack:');
            obj.y.WL('              type: "array"');
            obj.y.WL('              items:');
            obj.y.WL('                type: "object"');
            obj.y.WL('                properties:');
            obj.y.WL('                  file:');
            obj.y.WL('                    type: "string"');
            obj.addExample('"myFunction.m"');
            obj.y.WL('                  name:');
            obj.y.WL('                    type: "string"');
            obj.addExample('"myFunction"');
            obj.y.WL('                  line:');
            obj.y.WL('                    type: "integer"');
            obj.addExample('23');
            obj.y.WL('            type:');
            obj.y.WL('              type: "string"');
            obj.y.WL('              enum:');
            obj.y.WL('              - "matlaberror"');
            obj.y.WL('    OutputFormat:');
            obj.y.WL('      description: |');
            obj.y.WL('        Specify whether the MATLAB output in the response should be returned');
            obj.y.WL('        using large or small JSON notation, and whether NaN and Inf should be');
            obj.y.WL('        represented as a JSON string or object.');
            obj.y.WL('        ');
            obj.y.WL('        If used, set `mode` to `large` for the output to comply with this OpenAPI spec.');
            obj.y.WL('      type: "object"');
            obj.y.WL('      properties:');
            obj.y.WL('        mode:');
            obj.y.WL('          type: string');
            obj.y.WL('          enum:');
            obj.y.WL('          - large');
            obj.y.WL('        nanInfFormat:');
            obj.y.WL('          type: string');
            obj.y.WL('          enum:');
            obj.y.WL('          - "string"');
            obj.y.WL('          - "object"');
if obj.Async
            obj.y.WL('  parameters:');
            obj.addAsyncParameters;
end
if obj.OAuth
            obj.y.WL('  securitySchemes:');
            obj.y.WL('    oauth2:');
            obj.y.WL('      type: oauth2');
            obj.y.WL('      flows:');
            obj.y.WL('        authorizationCode:');
            obj.y.WL('          authorizationUrl: %s', obj.AuthorizationUrl);
            obj.y.WL('          tokenUrl: %s', obj.TokenUrl);
            obj.y.WL('          scopes: {}');
end
        end
        %% Helpers for adding snippets and types
        function obj = addHelp(obj, context)
            obj.y.push(2);
            if isfield(context,'help') && ~isempty(context.help)
                lines = splitlines(string(context.help));
                for l = 1:length(lines)
                    obj.y.WL(lines(l));
                end
            else
                obj.y.WL("No description provided");
            end
            obj.y.pop;
        end
        function obj = addExample(obj,format,varargin)
            obj.y.push();
            switch obj.OpenAPIVersion
                case "3.0.3"
                    obj.y.WL("example: " + format, varargin{:});
                case "3.1.0"
                    obj.y.WL("examples:");
                    obj.y.WL("- " + format, varargin{:});
            end
            obj.y.pop();
        end
        function obj = addOASType(obj,matlabtype)
            obj.y.push();
            switch string(matlabtype)
            case {"char","string"}
                obj.y.WL('type: "string"');
            case "double"
                obj.y.WL('type: "number"');
                obj.y.WL('format: "double"');
            case "single"
                obj.y.WL('type: "number"');
                obj.y.WL('format: "float"');
            case "logical"
                obj.y.WL('type: "boolean"');
            case {"uint8","int8","uint16","int16","uint32","int32","uint64","int64"}
                obj.y.WL('type: "integer"');
                obj.y.WL('format: "%s"',matlabtype);
            case "struct"
                obj.y.WL('type: "struct"');
            case "cell"
                obj.y.WL('type: "cell"');
            otherwise
                obj.y.WL('type: "object"');    
            end
            obj.y.pop();
        end

        function obj = addStruct(obj,typedef,archiveName,parent)
obj.y.push();
context = obj.root.archives.(archiveName).typedefs.(typedef);
            obj.y.WL('type: "object"');
            obj.y.WL('description: |');
            obj.addHelp(context);
            obj.y.WL('properties:');
for fieldIndex = 1:length(context.fields)
    field = getItem(context.fields,fieldIndex);
            obj.y.WL('  %s:',field.name);
            obj.y.WL('    type: "array"');
            obj.y.WL('    items:');
            obj.y.WL('      type: "object"');
            obj.addMWArray(field,archiveName);
    if isfield(parent,'mwsize') && ~isempty(parent.mwsize)
            obj.y.WL('    minItems: %d',prod(parent.mwsize));
            obj.y.WL('    maxItems: %d',prod(parent.mwsize));
    end
end
obj.y.pop();
        end

        function obj = addCell(obj,typedef,archiveName)
obj.y.push();
context = obj.root.archives.(archiveName).typedefs.(typedef);
if length(context.elements) > 1 % heterogenous cell array
            obj.y.WL('description: |');
            obj.addHelp(context);
            obj.y.WL('%s:',obj.HeterogeneousArraySpecifier);
    for elementIndex = 1:length(context.elements)
        element = getItem(context.elements,elementIndex);
            obj.y.WL('- type: "object"');
            element.name = string(elementIndex);
            obj.addMWArray(element,archiveName);
    end
else % homogenous cell array
            element = context.elements;
            element.name = "1";
            obj.y.WL('type: "object"');
            obj.addMWArray(element,archiveName);
end
obj.y.pop();
        end

        function obj = addMWArray(obj,context,archiveName)
obj.y.push();
            obj.y.WL('description: |');
            obj.addHelp(context);
            obj.y.WL('title: "%s"',context.name);
            obj.y.WL('properties:');
            obj.y.WL('  mwtype:');
            obj.y.WL('    type: "string"');
if context.name ~= "varargin" && context.name ~= "varargout"
            obj.y.WL('    enum:');
            obj.y.WL('    - "%s"',context.mwtype);
end
            obj.y.WL('  mwsize:');
            obj.y.WL('    type: "array"');
            obj.y.WL('    items:');
            obj.y.WL('      type: "integer"');
            obj.y.WL('      format: "int64"');
if isfield(context,'mwsize') && ~isempty(context.mwsize)
            obj.y.WL('      minimum: %d',min(context.mwsize));
            obj.y.WL('      maximum: %d',max(context.mwsize));
end
if isfield(context,'mwsize') && ~isempty(context.mwsize)
            obj.y.WL('    minItems: %d',length(context.mwsize));
            obj.y.WL('    maxItems: %d',length(context.mwsize));
            obj.addExample('[%s]',strjoin(string(context.mwsize),","));
else
            obj.y.WL('    minItems: 2');
    if context.mwtype == "char"
            obj.addExample('[1,6]');
    end
end
            obj.y.WL('  mwdata:').Indent;
if context.mwtype == "struct"
            obj.addStruct(context.typedef,archiveName,context);
else % cell or primitive
    if context.mwtype == "char"
            obj.addExample('["string"]');
    end   
            obj.y.WL('    type: "array"');
            obj.y.WL('    items:').Indent;
    if context.mwtype == "cell"
            obj.addCell(context.typedef,archiveName);
    else
            obj.addOASType(context.mwtype);
    end
    if isfield(context,'mwsize') && ~isempty(context.mwsize)
            obj.y.WL('    minItems: %d',prod(context.mwsize));
            obj.y.WL('    maxItems: %d',prod(context.mwsize));
    end
end
obj.y.pop();
        end
        
        %% Helpers for adding Async interfaces
        function obj = addAsyncEndpoints(obj)
obj.y.push();
            obj.y.WL('/~{instance-uuid}/requests/{request-id}/result:');
            obj.y.WL('  get:');
            obj.y.WL('    tags:');
            obj.y.WL('      - "Asynchronous API"');
            obj.y.WL('    summary: "Retrieve results of request."');
            obj.y.WL('    description: "Use a GET method to retrieve the results of a request from the server. The URI of the self field serves as the addressable resource for the method."');
            obj.y.WL('    operationId: "get_async_result"');
if obj.OAuth
            obj.y.WL('    security:');
            obj.y.WL('    - oauth2: []');
end
            obj.y.WL('    parameters:');
            obj.y.WL('    - $ref: "#/components/parameters/InstanceUUID"');
            obj.y.WL('    - $ref: "#/components/parameters/RequestID"');
            obj.y.WL('    responses:');
            obj.y.WL('      200:');
            obj.y.WL('        content:');
            obj.y.WL('          application/json:');
            obj.y.WL('            schema:');
            obj.y.WL('              type: "object"');
            obj.y.WL('        description: |');
            obj.y.WL('          Results represented in JSON.');
            obj.y.WL('          ');
            obj.y.WL('          The response body will vary based on the function which has been called asynchronously');
            obj.y.WL('          and will be the same as if that function had been called synchronously. Refer to the');
            obj.y.WL('          separate function declarations above which describe these synchronous response bodies in details.');
            obj.y.WL('      400:');
            obj.y.WL('        description: "Request ID is not a valid request ID format at all."');
            obj.y.WL('      404:');
            obj.y.WL('        description: "Request not found. Format is correct but no ID with this request found. Request may never have existed at all or it may have been cancelled or deleted."');
            obj.y.WL('/~{instance-uuid}/requests/{request-id}/info:');
            obj.y.WL('  get:');
            obj.y.WL('    tags:');
            obj.y.WL('      - "Asynchronous API"');
            obj.y.WL('    summary: "Get state information of request."');
            obj.y.WL('    description: "Use a GET method to get information about the state of a request. The URI of the self field serves as the addressable resource for the method. Possible states are: READING, IN_QUEUE, PROCESSING, READY, ERROR, and CANCELLED."');
            obj.y.WL('    operationId: "get_async_request_state"');
if obj.OAuth
            obj.y.WL('    security:');
            obj.y.WL('    - oauth2: []');
end
            obj.y.WL('    parameters:');
            obj.y.WL('    - $ref: "#/components/parameters/InstanceUUID"');
            obj.y.WL('    - $ref: "#/components/parameters/RequestID"');
            obj.y.WL('    responses:');
            obj.y.WL('      200:');
            obj.y.WL('        content:');
            obj.y.WL('          application/json:');
            obj.y.WL('            schema:');
            obj.y.WL('              type: "object"');
            obj.y.WL('              properties:');
            obj.y.WL('                request:');
            obj.y.WL('                  type: "string"');
            obj.y.WL('                  description: "URI to current request."');
            obj.addExample('"/~ea9859eb-c900-492d-afc0-ce6dc0f36e8d/requests/798eab4b-7b64-4105-94b2-75fe0718454d"');
            obj.y.WL('                lastModifiedSeq:');
            obj.y.WL('                  type: "number"');
            obj.y.WL('                  format: "integer"');
            obj.y.WL('                  description: "Number indicating when the current request was last modified."');
            obj.addExample('42');
            obj.y.WL('                state:');
            obj.y.WL('                  type: "string"');
            obj.y.WL('                  description: "State of current request."');
            obj.y.WL('                  enum:');
            obj.y.WL('                  - "READING"');
            obj.y.WL('                  - "IN_QUEUE"');
            obj.y.WL('                  - "PROCESSING"');
            obj.y.WL('                  - "READY"');
            obj.y.WL('                  - "ERROR"');
            obj.y.WL('                  - "CANCELLED"');
            obj.y.WL('        description: "State of the asynchronous request."');
            obj.y.WL('      400:');
            obj.y.WL('        description: "Request ID is not a valid request ID format at all."');
            obj.y.WL('      404:');
            obj.y.WL('        description: "Request not found. Format is correct but no ID with this request found. Request may never have existed at all or it may have been cancelled or deleted."');
            obj.y.WL('/~{instance-uuid}/requests/{request-id}:');
            obj.y.WL('  delete:');
            obj.y.WL('    tags:');
            obj.y.WL('      - "Asynchronous API"');
            obj.y.WL('    summary: "Delete request from server."');
            obj.y.WL('    description: "Use a DELETE method to delete a request on the server. You cannot retrieve the information of a deleted request."');
            obj.y.WL('    operationId: "delete_async_request"');
if obj.OAuth
            obj.y.WL('    security:');
            obj.y.WL('    - oauth2: []');
end
            obj.y.WL('    parameters:');
            obj.y.WL('    - $ref: "#/components/parameters/InstanceUUID"');
            obj.y.WL('    - $ref: "#/components/parameters/RequestID"');
            obj.y.WL('    responses:');
            obj.y.WL('      204:');
            obj.y.WL('        description: "Success. No Content."');
            obj.y.WL('      400:');
            obj.y.WL('        description: "Request ID is not a valid request ID format at all."');
            obj.y.WL('      404:');
            obj.y.WL('        description: "Request not found. Format is correct but no ID with this request found. Request may never have existed at all or it may have been cancelled or deleted."');
            obj.y.WL('/~{instance-uuid}/requests/{request-id}/cancel:');
            obj.y.WL('  post:');
            obj.y.WL('    tags:');
            obj.y.WL('      - "Asynchronous API"');
            obj.y.WL('    summary: "Cancel request which has not yet completed."');
            obj.y.WL('    description: "Use a POST method to cancel a request. You can cancel only those requests that have not already completed."');
            obj.y.WL('    operationId: "post_async_cancel"');
if obj.OAuth
            obj.y.WL('    security:');
            obj.y.WL('    - oauth2: []');
end
            obj.y.WL('    parameters:');
            obj.y.WL('    - $ref: "#/components/parameters/InstanceUUID"');
            obj.y.WL('    - $ref: "#/components/parameters/RequestID"');
            obj.y.WL('    responses:');
            obj.y.WL('      204:');
            obj.y.WL('        description: "Success. No Content"');
            obj.y.WL('      410:');
            obj.y.WL('        description: "Failure. Request already completed and can no longer be cancelled."');
            obj.y.WL('      400:');
            obj.y.WL('        description: "Request ID is not a valid request ID format at all."');
            obj.y.WL('      404:');
            obj.y.WL('        description: "Request not found. Format is correct but no ID with this request found. Request may never have existed at all or it may have been cancelled or deleted."');
            obj.y.WL('/~{instance-uuid}/requests:');
            obj.y.WL('  get:');
            obj.y.WL('    tags:');
            obj.y.WL('      - "Asynchronous API"');
            obj.y.WL('    summary: "View a collection of requests."');
            obj.y.WL('    description: "Use a GET method to view a collection of requests on the server. The URI of the up field serves as the addressable resource for the method."');
            obj.y.WL('    operationId: "get_async_request_collection"');
if obj.OAuth
            obj.y.WL('    security:');
            obj.y.WL('    - oauth2: []');
end
            obj.y.WL('    parameters:');
            obj.y.WL('    - $ref: "#/components/parameters/InstanceUUID"');
            obj.y.WL('    - description: "`createdSeq` or `lastModifiedSeq` as returned by previous requests."');
            obj.y.WL('      in: "query"');
            obj.y.WL('      name: "since"');
            obj.y.WL('      required: true');
            obj.y.WL('      schema:');
            obj.y.WL('        format: "integer"');
            obj.y.WL('        type: "number"');
            obj.y.WL('    - description: "`clientId` string. Required if `ids` is not specified"');
            obj.y.WL('      in: "query"');
            obj.y.WL('      name: "clients"');
            obj.y.WL('      required: false');
            obj.y.WL('      schema:');
            obj.y.WL('        type: "string"');
            obj.y.WL('    - description: |');
            obj.y.WL('        Request `id`s as returned by the "POST Asynchronous Request" or other operations. Required if `clients` is not specified.');
            obj.y.WL('      in: "query"');
            obj.y.WL('      name: "ids"');
            obj.y.WL('      required: false');
            obj.y.WL('      schema:');
            obj.y.WL('        type: "string"');
            obj.y.WL('    responses:');
            obj.y.WL('      200:');
            obj.y.WL('        content:');
            obj.y.WL('          application/json:');
            obj.y.WL('            schema:');
            obj.y.WL('              type: "object"');
            obj.y.WL('              properties:');
            obj.y.WL('                createdSeq:');
            obj.y.WL('                  type: "number"');
            obj.y.WL('                  format: "integer"');
            obj.y.WL('                  description: "Number indicating the server state. The requests included in the data collection are the requests that have gone through some state change between since and createdSeq."');
            obj.y.WL('                data:');
            obj.y.WL('                  type: "array"');
            obj.y.WL('                  description: "Collection of MATLAB® execution requests that match a query."');
            obj.y.WL('                  items:');
            obj.y.WL('                    $ref: "#/components/schemas/AsyncRequestInfo"');
            obj.y.WL('        description: "Collection of asynchronous requests on the server."');
            obj.y.WL('      400:');
            obj.y.WL('        description: "Missing query parameters or no match found for given parameters."');
obj.y.pop();
        end
        function obj = addAsyncSchemas(obj)
            obj.y.push(2);
            obj.y.WL('AsyncRequestInfo:');
            obj.y.WL('  type: "object"');
            obj.y.WL('  properties:');
            obj.y.WL('    id:');
            obj.y.WL('      type: "string"');
            obj.y.WL('      description: "ID of a particular request."');
            obj.addExample('"798eab4b-7b64-4105-94b2-75fe0718454d"');
            obj.y.WL('    self:');
            obj.y.WL('      type: "string"');
            obj.y.WL('      description: "URI of particular request. Use the URI in other asynchronous execution requests such as retrieving the state of the request or result of request."');
            obj.addExample('"/~ea9859eb-c900-492d-afc0-ce6dc0f36e8d/requests/798eab4b-7b64-4105-94b2-75fe0718454d"');
            obj.y.WL('    up:');
            obj.y.WL('      type: "string"');
            obj.y.WL('      description: "URI of a collection of requests."');
            obj.addExample('"/~ea9859eb-c900-492d-afc0-ce6dc0f36e8d/requests"');
            obj.y.WL('    lastModifiedSeq:');
            obj.y.WL('      type: "number"');
            obj.y.WL('      format: "integer"');
            obj.y.WL('      description: "Number indicating when a request represented by self was last modified."');
            obj.addExample('42');
            obj.y.WL('    state:');
            obj.y.WL('      type: "string"');
            obj.y.WL('      enum:');
            obj.y.WL('      - "READING"');
            obj.y.WL('      - "IN_QUEUE"');
            obj.y.WL('      - "PROCESSING"');
            obj.y.WL('      - "READY"');
            obj.y.WL('      - "ERROR"');
            obj.y.WL('      - "CANCELLED"');
            obj.y.WL('      description: "State of a request."');
            obj.y.WL('    client:');
            obj.y.WL('      type: "string"');
            obj.y.WL('      description: "Client id or name that was specified as a query parameter while initiating a request."');
            obj.addExample('"myClientID"');
            obj.y.pop();
        end
        function obj = addAsyncParameters(obj)
            obj.y.push(2);
            obj.y.WL('ClientParameter:');
            obj.y.WL('  description: "If working in asynchronous mode: an ID or name for the client making the request."');
            obj.y.WL('  in: "query"');
            obj.y.WL('  name: "client"');
            obj.y.WL('  required: false');
            obj.y.WL('  schema:');
            obj.y.WL('    type: "string"');
            obj.y.WL('ModeParameter:');
            obj.y.WL('  description: "Omit entirely for synchronous request. Set to `async` to perform an asynchronous request."');
            obj.y.WL('  in: "query"');
            obj.y.WL('  name: "mode"');
            obj.y.WL('  required: false');
            obj.y.WL('  schema:');
            obj.y.WL('    enum:');
            obj.y.WL('    - "async"');
            obj.y.WL('    type: "string"');
            obj.y.WL('InstanceUUID:');
            obj.y.WL('  description: |');
            obj.y.WL('    The Instance UUID is assigned to a MATLAB Production Server instance at startup.');
            obj.y.WL('    The Instance UUID remains the same for the lifetime of the instance and changes');
            obj.y.WL('    when the instance is restarted.');
            obj.y.WL('    ');
            obj.y.WL('    The UUID can be found back in the `self` field in the response');
            obj.y.WL('    when the request was initially created or in the response of');
            obj.y.WL('    "View a collection of requests".');
            obj.y.WL('    ');
            obj.y.WL('    The `self` field will have the format: `~{instance-uuid}/requests/{request-id}`');
            obj.y.WL('  in: "path"');
            obj.y.WL('  name: "instance-uuid"');
            obj.y.WL('  required: true');
            obj.y.WL('  schema:');
            obj.y.WL('    type: "string"');
            obj.y.WL('RequestID:');
            obj.y.WL('  description: |');
            obj.y.WL('    The Request ID as identified by the `id` field in the response');
            obj.y.WL('    when the request was initially created or in the response of');
            obj.y.WL('    "View a collection of requests".');
            obj.y.WL('  in: "path"');
            obj.y.WL('  name: "request-id"');
            obj.y.WL('  required: true');
            obj.y.WL('  schema:');
            obj.y.WL('    type: "string"');
            obj.y.pop();
        end
    end
    methods (Hidden)
        function h = get_local_functions(~)
            fhs = localfunctions();
            h = containers.Map();
            for i=1:length(fhs)
                h(functions(fhs{i}).function) = fhs{i};
            end
        end
    end
end

%% Cell/Array helpers
function item = lastItem(cellOrArray)
    % lastItem returns last item in an array or cell array
    if iscell(cellOrArray)
        item = cellOrArray{end};
    else
        item = cellOrArray(end);
    end
end
function item = getItem(cellOrArray,index)
    % getItem returns specified item from array or cell array
    if iscell(cellOrArray)
        item = cellOrArray{index};
    else
        item = cellOrArray(index);
    end
end        
%% Helpers to be used in IF-statements
function tf = hasVarargin(inputs)
    last = lastItem(inputs);
    tf = last.name == "varargin";
end
function tf = hasVarargout(outputs)
    last = lastItem(outputs);
    tf = last.name == "varargout";
end