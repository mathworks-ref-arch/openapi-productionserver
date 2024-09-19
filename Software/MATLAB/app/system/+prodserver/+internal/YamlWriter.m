classdef YamlWriter < handle
%YAMLWRITER helper class for producing YAML documents
%
%   The main usage of this class is through its WL (Write Line) method. The
%   basic idea is that this method is called with actual indents in the
%   input string and only use the Indent and UnIndent methods sparingly
%   (these are meant for *extra* indents when nesting documents). For
%   example:
%
%       y = YamlWriter;
%       y.WL("abc:");
%       y.WL("  def: Hello");
%       y.WL("  ghi: World");
%
%   In this way you can *see* the actual document forming in the code.
%
%   Further there is a so called "indent stack". Whenever WL is called, the
%   class actually counts the current indent, we can then push this current
%   indent on the stack. Then consecutive WL calls will prepend the strings
%   with this indent. pop removes the lastest indent from the stack. This
%   allows you to add "sub documents" using functions. For example:
%
%       % Same example as before
%       y = YamlWriter;
%       y.WL("abc:");
%       y.WL("  def: Hello");
%       y.WL("  ghi: World");
%       % Now call a function to add a sub document
%       addJKL(y)
%   
%       function addJKL(y)
%           % Push the current indent to the stack
%           y.push()
%           % Now we can start from the beginning again and not have to
%           % prepend all these lines with additional indents
%           y.WL("jkl:");
%           y.WL("  mno: Example");
%           % Remove the indent from the stack
%           y.pop()
%
%   Will produce:
%
%       abc:
%         def: Hello
%         ghi: World
%         jkl:
%           mno: Example
%
% YamlWriter Methods:
%
%   WL       - (Write Line) writes a line to the output buffer.
%   WR       - (Write) writes
%   Indent   - Increases current indent count
%   UnIndent - Decreases current indent count
%   push     - pushes current indent on the stack
%   pop      - pops current indent from the stack

% Copyright 2023-2024 The MathWorks, Inc.
    properties
        CurrentIndent
        IndentStack
    end
    properties (Access={?prodserver.openapi.internal.YamlWriter, ?matlab.unittest.TestCase})
        StringBuffer
    end
    methods
        function obj = YamlWriter()
            %YAMLWRITER constructor
            % Instantiates a new YamlWriter with empty buffer and stack.
            obj.StringBuffer = "";
            obj.CurrentIndent = 0;
            obj.IndentStack = 0;
        end
        function obj = WR(obj,format,varargin)
            %WR WRite output to the buffer without indent or newline
            %
            %   The method takes a FPRINTF/SPRINTF input style where the
            %   first input is the format and it is followed by the data
            %   used in the format.
            %
            %   Indent is not added or counted. No newline characters are
            %   automatically added.
            arguments
                obj
                format string
            end
            arguments (Repeating)
                varargin
            end
            obj.StringBuffer = obj.StringBuffer + sprintf(format,varargin{:});
        end
        function obj = WL(obj,format,varargin)
            %WL Write Line writes line in the output buffer with a newline
            %and adds indent from the stack.
            %
            %   The method takes a FPRINTF/SPRINTF input style where the
            %   first input is the format and it is followed by the data
            %   used in the format.
            %
            %   Lines are automatically prepended with the indent from the
            %   stack and a newline character is automatically added on the
            %   end.
            %
            %   The method automatically counts the indent of the line such
            %   that it can be pushed to the stack.            
            arguments
                obj
                format string
            end
            arguments (Repeating)
                varargin
            end
            obj.countIndent(format);
            obj.StringBuffer = obj.StringBuffer + blanks(obj.IndentStack(end)) + sprintf(format + "\n",varargin{:});
        end
        function obj = push(obj,extraIndent)
            %PUSH push current indent to the stack
            %
            %   Optionally provide an input to specify any additional indent
            %   to add to the current indent before pushing to the stack.
            arguments
                obj
                extraIndent = 0
            end
            obj.IndentStack(end+1) = obj.IndentStack(end) + obj.CurrentIndent + extraIndent;
        end
        function obj = pop(obj)
            %POP removes latest indent from the stack
            obj.IndentStack(end) = [];
        end
        function result = ToString(obj)
            %TOSTRING returns the output buffer as string
            result = obj.StringBuffer;
        end
        function ToFile(obj,filename)
            %TOFILE writes the output buffer to file
            f = fopen(filename,"w");
            fwrite(f,obj.StringBuffer);
            fclose(f);
        end
        function obj = Indent(obj)
            %INDENT increases the current indent count
            obj.CurrentIndent = obj.CurrentIndent + 2;
        end
        function obj = UnIndent(obj)
            %UNINDENT decreases the current indent count
            obj.CurrentIndent = obj.CurrentIndent - 2;
        end        
    end
    methods (Access={?prodserver.openapi.internal.YamlWriter, ?matlab.unittest.TestCase})
        function countIndent(obj,str)
            n = find( ~(isspace(str) | char(str) == '-') );
            if isempty(n)
                obj.CurrentIndent = 0;
            else
                obj.CurrentIndent = n(1)-1;                
            end
        end
    end
end