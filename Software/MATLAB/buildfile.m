function plan = buildfile
% BUILDFILE MATLAB Build Tool definition to run the unit tests

% Copyright 2023-2024 The MathWorks, Inc.

    plan = buildplan;
    import matlab.buildtool.tasks.TestTask
    plan("test") = TestTask("test",TestResults="results.xml");