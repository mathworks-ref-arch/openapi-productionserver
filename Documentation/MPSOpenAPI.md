# OpenAPI representations of MATLAB Production Server Types and Methods

OpenAPI Specification Version 3.0.3 appears to have mainly been designed with modern request and response bodies in mind where these bodies are JSON objects with multiple different *fields* to represent multiple different in- or outputs. For example, for a MATLAB function like:

```matlab
function [a,b] = myFun(x,y,z)
    a = "Hello " + x;
    b = y + z;
```

A typical modern REST interface for the input would look something like:

```json
{
    "x": "value1",
    "y": [2,20,200],
    "z": [3,30,300]
}
```

And responses which look something like:

```json
{
    "a": "Hello value1",
    "b": [5,50,500],
}
```

However, this is not what the actual MATLAB Production Server REST interface looks like, it is somewhat older and was designed before specs like the ones above became commonplace. MATLAB Production Server's actual interface for the function above, in [large notation](https://www.mathworks.com/help/mps/restfuljson/json-representation-of-matlab-data-types.html) is:

```json
{
    "nargout": 2,
    "rhs": [
        {"mwtype": "string", "mwsize": [1,6], "mwdata": "value1"},
        {"mwtype": "double", "mwsize": [1,3], "mwdata": [2,20,200]},
        {"mwtype": "double", "mwsize": [1,3], "mwdata": [3,30,300]}
    ]
}
```

or in small notation:

```json
{
    "nargout": 2,
    "rhs": [
        "value1",
        [2,20,200],
        [3,30,300]
    ]
}
```

It *is* a JSON object as well, with fields like `nargout` (to specify the number of requested outputs) and `rhs`. But the actual function inputs are represented in one single ordered array in the `rhs` field. And unfortunately, OpenAPI 3.0.3 is limited with regards to how accurately arrays can be described: it is not possible to explicitly describe the order of the array elements, you can describe how many elements there are and you can describe the data types which the array may contain, *and* each type description has to be unique.

So, for the small notation example above, in OpenAPI 3.0.3 you can*not* say: `rhs` is an array with 3 elements and the elements are of primitive types: "string", "array of doubles" and "array of doubles". You may not say "array of doubles" *twice*, the type descriptions of array elements must be unique. So the best you *can* say here is that it is an array with 3 elements and the elements are a mix of primitive types "strings" and "arrays of doubles". You cannot say that it is "string" once and "array of double" twice, let alone that you would be able to say that it is specifically the first element which is the "string" and then the second and third are "array of double". Therefore small notation is *not* supported by the package. While it is possible to describe the API in a way which is *not wrong*, the description it is also *not accurate enough* to actually be useful. 

For the large notation, luckily it is possible to describe each array element with an unique type description, even if there are duplicate underlying MATLAB types. In large notation, each array element is a JSON object rather than a JSON primitive and JSON objects can be described much more elaborately (with additional metadata) than primitives, which allows us to make sure each type description is unique. Strictly speaking we still cannot prescribe the exact order of the elements, but most OpenAPI tools/client generators will just keep the order in which the types were described in the first place.

In OpenAPI Specification Version 3.1.0, `prefixItems` was added to array descriptions which do allow describing exact array elements in their exact order, including duplicate type definitions if necessary. In that sense the MATLAB Production Server REST APIs can be more accurately described in version 3.1.0. And 3.1.0 should thus theoretically also allow describing the small notation accurately enough to become useful. Support for small notation has not been added to the package (yet) though. Also do note that many of the OpenAPI tooling/client generators do not (fully) support version 3.1.0 yet.

Similarly, in order to be able to accurately describe the in- and outputs, the generated specs may include `oneOf` and/or `anyOf` schemas where the level of support for `oneOf` and `anyOf` varies in different OpenAPI tooling/client generators.

## Heterogenous array item definition

According to the OpenAPI 3.0.3 spec <https://spec.openapis.org/oas/v3.0.3#properties>:

> items - Value _MUST_ be an object and not an array. Inline or referenced schema _MUST_ be of a Schema Object and not a standard JSON Schema. `items` MUST be present if the type is `array`.

Meaning that in order to be able to describe an heterogenous array (which `lhs` and `rhs` typically are), an `anyOf` or `oneOf` object needs to be used. The spec is not entirely clear however, on which of the two options should be used (when). For example, for a definition as follows:

```yaml
type: array
items:
  oneOf:
  - type: string
  - type: integer
```

*   Some people and tooling (see for example <https://www.baeldung.com/openapi-array-of-varying-types>) say this definition means that *for the entire array* you may choose **one of** the two options `string` or `integer`, essentially giving homogeneous arrays. So, for example, `["a",",b","c"]` or `[1,2,3]` would be valid array instances, but `["a",2,"c"]` would not be. And these tools then say you should use `anyOf` instead, if you *do* want to allow a heterogeneous array with a mix of element types.

*   Other people and tooling (see for example [Mixed-Type Arrays section in the Swagger documentation](https://swagger.io/docs/specification/data-models/data-types/#mixed-array)) say that you are *not* describing the *entire* array here at all, you are describing the _items_ instead. So, the definition above then actually means that for *each and every* separate *item* in the array you may *independently* choose **one of** the options `string` or `integer`. So then, an heterogenous array with a mix of types (like `[1,"b",3]`) is simply already allowed with `oneOf`. And these tools then basically also say that `oneOf` is the only option you ever need, and you never use `anyOf` at all here.

By default the OpenAPI Interface for MATLAB Production Server generates specs including `anyOf`, i.e. following the first reasoning; but this *is* configurable.

In OpenAPI 3.1.0, this problem does not exist, for this version `prefixItems` is used instead of `items`. `prefixItems` is more accurate in the sense that it also really prescribed the order of the elements in the array. And, `prefixItems` does not require the usage of `oneOf` or `anyOf` in the first place.

[//]: #  (Copyright 2023-2024 The MathWorks, Inc.)