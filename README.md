# *OpenAPI Interface for* MATLAB Production Server

## Introduction

This package offers a MATLAB® interface which can be used to translate the proprietary JSON format of [MATLAB Production Server's Discovery Service](https://www.mathworks.com/help/mps/restfuljson/restful-api-for-discovery-and-diagnostics.html#mw_d710d743-384a-434f-b4ab-2b5941e56ca8) into OpenAPI™ specifications. The functionality can be used inside MATLAB, deployed into a standalone application using MATLAB Compiler™ or even be deployed as an endpoint to MATLAB Production Server™ itself.

## Requirements

### MathWorks Products (https://www.mathworks.com)

* MATLAB R2019b or newer
* A MATLAB Production Server Instance with [Discovery Service](https://www.mathworks.com/help/mps/restfuljson/restful-api-for-discovery-and-diagnostics.html#mw_d710d743-384a-434f-b4ab-2b5941e56ca8) [enabled](https://www.mathworks.com/help/mps/server/mps.configuration-properties.html#propname_enable-discovery)
* (optional) MATLAB Compiler (for deploying as a standalone application)
* (optional) MATLAB Compiler SDK™ (for deploying to MATLAB Production Server)

## Installation

Run `startup.m` in the `Software/MATLAB` directory to add the package directories to the MATLAB path.

For further details see [Installation](https://mathworks-ref-arch.github.io/openapi-productionserver/Installation.html) in the [documentation](https://mathworks-ref-arch.github.io/openapi-productionserver).

## Usage

The generator is implemented as a MATLAB class, first create an instance of this class:

```matlab
openapiGenerator = prodserver.openapi();
```

Then configure relevant settings on the object:

```matlab
% For example, specify the version of the API
openapiGenerator.Version = "3.14.0";
% For example, specify that the asynchronous interface should be included in the spec
openapiGenerator.Async = true;
```
*For a full overview of all options and settings see [Usage](https://mathworks-ref-arch.github.io/openapi-productionserver/Usage.html) in the [documentation](https://mathworks-ref-arch.github.io/openapi-productionserver).*

Finally, use the `generate` method on a MATLAB Production Server Discovery document imported as MATLAB structure:

```matlab
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

For further usage details see [Usage](https://mathworks-ref-arch.github.io/openapi-productionserver/Usage.html) in the [documentation](https://mathworks-ref-arch.github.io/openapi-productionserver).

## Limitations

* The package *translates* the proprietary discovery JSON format to OpenAPI specs. Therefore it can only generate OpenAPI specs for functionality for which discovery information has in fact been included in the archive(s). Also, the accuracy of the generated OpenAPI specs will depend on the accuracy of the discovery information. Including (accurate) discovery information is the responsibility of the archive authors. The package does not verify whether included discovery information, and therefore generated OpenAPI spec, is correct in practice.

* Since the original discovery format does not allow describing `enumeration` and `datetime` formats in enough detail to be able to generate a meaningful OpenAPI description, both `enumeration` and `datetime` data types are *not* supported by the package.

* The package can generate specs in OpenAPI Specification version 3.0.3 and 3.1.0. Older specification versions like 2.0 are not supported. Older OpenAPI Specifications versions do not allow representing the MATLAB Production Server REST API accurately enough to be useful.

* The generated specs are for the **large** [JSON Representation of MATLAB Data Types](https://www.mathworks.com/help/mps/restfuljson/json-representation-of-matlab-data-types.html) only. Small notation is not supported. The small notation simply can*not* accurately be represented in OpenAPI Specification version 3.0.3. It may be feasible to accurately represent the small notation in OpenAPI Specification version 3.1.0 but this is not supported in the package (yet).

## License

The license for the *OpenAPI Interface for* MATLAB Production Server is available in the LICENSE.txt file in this repository.

## Enhancement Requests

Provide suggestions for additional features or capabilities using the following link:
https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html

## Support

Please create a GitHub issue.

[//]: #  (Copyright 2023-2024 The MathWorks, Inc.)