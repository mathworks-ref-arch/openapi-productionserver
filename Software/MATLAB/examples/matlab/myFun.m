function out = myFun(in1,in2)
%MYFUN example MATLAB function for MATLAB Production Server using various
%input and output types.
%
% The function has two inputs, the first is a struct with fields field1 and
% field2 which are scalar doubles. The second input is a scalar double. The
% output is a cell array with 2 cells. This demonstrates how various (more
% complex) MATLAB types map to OpenAPI specs.
% 
% Example usage in MATLAB:
%
%   in1.field1 = 1;
%   in1.field2 = 2;
%   in2 = 3;
%   out = myFun(in1,in2);
    
% Copyright 2023-2024 The MathWorks, Inc.

    out{1} = in1.field1 + in2;
    out{2} = in1.field2 + in2;
    
