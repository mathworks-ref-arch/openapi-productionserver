# Customization/Extending

To customize the generator simply edit `Software/MATLAB/+prodserver/openapi.m` in place. While it is technically also possible to derive from the class and then overload or extend methods; the class was not designed with *such* extensibility in mind. The class is designed to be relatively simple and straightforward: it tries to basically fill out the OpenAPI document as a template. And the idea is that this "template" can be edited in place. Most of the MATLAB code is literally just writing out lines of OpenAPI YAML code while filling out the correct names and values. The remainder of the MATLAB code is mostly about iterating through all archives, functions and types.

## YamlWriter

In order to be able to edit the generator, it is important to understand the `YamlWriter` class it uses internally. Type the following in the MATLAB Command Window to learn more:

```matlabsession
>> help prodserver.internal.YamlWriter
```

[//]: #  (Copyright 2023-2024 The MathWorks, Inc.)