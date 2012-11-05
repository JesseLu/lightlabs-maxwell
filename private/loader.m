% Script to install Maxwell.
% A useful command to zip up files is
%     zip -r ~/maxwell.zip . -x *.git*

version = 'pre-release';

%% Generic install script.
fprintf('Loading Maxwell (%s)...', version);

% Some constants.
zipfile_prefix = [tempdir, filesep, 'maxwell-'];
maxwelldir = [tempdir, filesep, 'lightlabs-maxwell'];

% Get the zip files.
urlwrite(['http://m.lightlabs.co/', version, '.zip'], zipfile);
unzip(zipfile, maxwelldir);
path(genpath(maxwelldir), path);
fprintf('done\n');
