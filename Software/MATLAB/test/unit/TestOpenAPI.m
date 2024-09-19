classdef TestOpenAPI < matlab.unittest.TestCase
    % TestOpenAPI Unit tests

    % Copyright 2023-2024 The MathWorks, Inc.
    methods (TestClassSetup)
        % Shared setup for the entire test class
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)

        %% Test running the generator
        function TestNonStructError(testCase)
            % Verifies that the generator throws an apporiate error when
            % called with a non-structure input
            generator = prodserver.openapi();
            discovery = fileread(fullfile(fileparts(mfilename('fullpath')),'fixtures','structandcell.json'));
            testCase.verifyError(@()generator.generate(discovery),'prodserver:openapi:notstruct');
        end


        function TestStructAndCells(testCase)
            % This calls the generator with a discovery document with cells
            % and structs as input. This test does *not* verify that the
            % generated spec is 100% correct; this would amount to a string
            % compare or a huge string and would not be a good unit test.
            %
            % The individual tests below verify that correct snippets are
            % generated for different in- and output types, etc.
            %
            % The aim of this particular test here is just to quickly
            % confirm that the generator runs without error (for a
            % relatively complex input).
            generator = prodserver.openapi();
            discovery = fileread(fullfile(fileparts(mfilename('fullpath')),'fixtures','structandcell.json'));
            spec = generator.generate(jsondecode(discovery));
            % Do verify that "something" was generated
            testCase.verifyNotEmpty(spec);
        end

        %% Test private methods

        function TestAddHelp(testCase)
            % Empty context, should write No description provided with
            % correct indent
            generator = prodserver.openapi();
            generator.addHelp(struct);
            c = char(generator.y.StringBuffer);
            % verify indent at start and newline at end
            testCase.verifyEqual(c(1:2),'  ');
            testCase.verifyEqual(c(end),newline)
            % With context, should include text from context
            generator = prodserver.openapi();
            generator.addHelp(struct('help','help text'));
            c = char(generator.y.StringBuffer);
            testCase.verifyEqual(c,['  help text' newline]);
        end

        function TestAddOASType(testCase)
            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("char").y.StringBuffer,...
                "type: ""string""" + newline);
           
            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("string").y.StringBuffer,...
                "type: ""string""" + newline);            

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("struct").y.StringBuffer,...
                "type: ""struct""" + newline);            

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("cell").y.StringBuffer,...
                "type: ""cell""" + newline);            

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("double").y.StringBuffer,...
                "type: ""number""" + newline +...
                "format: ""double""" + newline);

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("single").y.StringBuffer,...
                "type: ""number""" + newline +...
                "format: ""float""" + newline);

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("int8").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""int8""" + newline);

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("uint8").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""uint8""" + newline);            

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("int16").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""int16""" + newline);

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("uint16").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""uint16""" + newline);            

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("int32").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""int32""" + newline);

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("uint32").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""uint32""" + newline);            

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("int64").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""int64""" + newline);

            generator = prodserver.openapi();
            testCase.verifyEqual(generator.addOASType("uint64").y.StringBuffer,...
                "type: ""integer""" + newline +...
                "format: ""uint64""" + newline);            

        end

        %% Test Local functions
        function TestLastItem(testCase)
            generator = prodserver.openapi();
            fh = generator.get_local_functions();
            lastItem = fh('lastItem');
            % Scalar
            testCase.verifyEqual(lastItem(3.14),3.14)
            testCase.verifyEqual(lastItem("foo"),"foo")
            % Array
            testCase.verifyEqual(lastItem([3.14,42.0]),42.0)
            testCase.verifyEqual(lastItem(["foo","bar"]),"bar")
            % Single Cell
            testCase.verifyEqual(lastItem({3.14}),3.14)
            testCase.verifyEqual(lastItem({"foo"}),"foo")
            % Cell Array
            testCase.verifyEqual(lastItem({3.14,42.0}),42.0)
            testCase.verifyEqual(lastItem({"foo","bar"}),"bar")
        end

        function TestGetItem(testCase)
            generator = prodserver.openapi();
            fh = generator.get_local_functions();
            getItem = fh('getItem');
            % Scalar
            testCase.verifyEqual(getItem(3.14,1),3.14)
            testCase.verifyEqual(getItem("foo",1),"foo")
            % Array
            testCase.verifyEqual(getItem([3.14,42.0,2.17],2),42.0)
            testCase.verifyEqual(getItem(["foo","bar","foobar"],2),"bar")
            % Single Cell
            testCase.verifyEqual(getItem({3.14},1),3.14)
            testCase.verifyEqual(getItem({"foo"},1),"foo")
            % Cell Array
            testCase.verifyEqual(getItem({3.14,42.0,2.17},2),42.0)
            testCase.verifyEqual(getItem({"foo","bar","foobar"},2),"bar")            
        end

        function TestHasVarargIn(testCase)
            generator = prodserver.openapi();
            fh = generator.get_local_functions();
            hasVarargin = fh('hasVarargin');
            % Scalar struct
            testCase.verifyFalse(hasVarargin(struct('name','foo')))
            testCase.verifyTrue(hasVarargin(struct('name','varargin')))
            % Struct array
            testCase.verifyFalse(hasVarargin(struct('name',{'foo','bar'})))
            testCase.verifyTrue(hasVarargin(struct('name',{'foo','varargin'})))
            % Cell array of struct
            testCase.verifyFalse(hasVarargin({struct('name','foo'),struct('name','bar')}))
            testCase.verifyTrue(hasVarargin({struct('name','foo'),struct('name','varargin')}))
        end        

        function TestHasVarargOut(testCase)
            generator = prodserver.openapi();
            fh = generator.get_local_functions();
            hasVarargout = fh('hasVarargout');
            % Scalar struct
            testCase.verifyFalse(hasVarargout(struct('name','foo')))
            testCase.verifyTrue(hasVarargout(struct('name','varargout')))
            % Struct array
            testCase.verifyFalse(hasVarargout(struct('name',{'foo','bar'})))
            testCase.verifyTrue(hasVarargout(struct('name',{'foo','varargout'})))
            % Cell array of struct
            testCase.verifyFalse(hasVarargout({struct('name','foo'),struct('name','bar')}))
            testCase.verifyTrue(hasVarargout({struct('name','foo'),struct('name','varargout')}))
        end                
    end

end