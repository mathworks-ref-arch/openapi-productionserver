function productionServerOpenAPI(infile,outfile)
% PRODUCTIONSERVEROPENAPI example MATLAB function which can be compiled
% into a MATLAB Compiler Standalone application which can then be used to
% translate MATLAB Production Server discovery documents into OpenAPI
% specs.
%
% The code below can be updated to configure the generator according to
% your own needs (e.g. the OpenAPI version can be changed).
%
% To compile:
%
% >> compiler.build.standaloneApplication("productionServerOpenAPI")
%
% Then from a Windows or Linux command prompt:
%
% > productionServerOpenAPI "http://localhost:9910/api/discovery" "openapi.yaml"

% Copyright 2023-2024 The MathWorks, Inc.

    if startsWith(infile,"http")
        % If the input starts with http use "webread" to read the discovery
        % information
        discovery = webread(infile);
    else
        % If it does not start with http, assume a local file and read it
        discovery = jsondecode(fileread(infile));
    end
    % Create the generator instance
    openapiGenerator = prodserver.openapi();
    % Optional: configure settings, for example enable the asynchronous
    % interface
    openapiGenerator.Async = true;
    % Run the generator
    openApiSpec = openapiGenerator.generate(discovery);
    % Write the output to the specified output file
    f = fopen(outfile,'w');
    fwrite(f,openApiSpec);
    fclose(f);
