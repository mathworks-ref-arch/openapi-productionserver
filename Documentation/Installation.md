# Installation

The package is a pure MATLAB implementation without any further dependencies, so it can be "installed" by simply cloning the repository (or downloading as ZIP-file and extracting) and then running `startup.m` from the `Software/MATLAB` directory to add the relevant directories to the [MATLAB path](https://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html).

It is then possibly to permanently add these directories to the MATLAB path by using `savepath` after which `startup.m` does not have to be rerun again. Alternatively simply do rerun `startup.m` in new MATLAB session if the package is needed in that session.

[//]: #  (Copyright 2023-2024 The MathWorks, Inc.)