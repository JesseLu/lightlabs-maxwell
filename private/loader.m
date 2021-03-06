% Script to install Maxwell.
% A useful command to zip up files is
%     zip -r ~/maxwell.zip . -x *.git*

version = 'pre-release';

%% Generic install script.
fprintf('Loading Maxwell (%s)...', version);

% Some constants.
maxwelldir = [tempdir, filesep, 'lightlabs-maxwell'];

% Make the directory.
try 
    warning off;
    rmdir(maxwelldir, 's');
    warning on;
end
mkdir(maxwelldir);

% Get the zip files.
unzip(['http://nodeload.github.com/JesseLu/lightlabs-maxwell/zip/', version], maxwelldir);
unzip(['http://nodeload.github.com/wsshin/maxwell-dyn/zip/', version], maxwelldir);
path(genpath(maxwelldir), path);
fprintf('done\n');
