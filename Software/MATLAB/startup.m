function startup(varargin)
    %% STARTUP - Script to add my paths to MATLAB path
    % This script will add the paths below the root directory into the MATLAB
    % path. You may modify undesired path
    % filter to your desire.

    % Copyright 2022-2024 The MathWorks, Inc.

    if ~isdeployed()
        here = fileparts(mfilename('fullpath'));
        rootDirs = ...
	{ ...
            fullfile(here,'app', 'functions');...
            fullfile(here,'app', 'system');...
            fullfile(here,'examples');...
        };

        % Loop through the paths and add the necessary subfolders to the MATLAB path
        for pCount = 1:length(rootDirs)
            rootDir=rootDirs{pCount};
            iSafeAddToPath(rootDir);
        end
    end

end

%% Helper function to add to MATLAB path.
function iSafeAddToPath(pathStr)

    % Add to path if the file exists
    if exist(pathStr,'dir')
        disp(['Adding ',pathStr]);
        addpath(pathStr);
    else
        disp(['Skipping ',pathStr]);
    end

end
