% Script to install Maxwell.
% Use by only un-commenting out the version that is desired,
% then upload to m.lightlabs.co as the file named VERSION.

version = 'pre-release';

% Generic install script.
fprintf('Loading Maxwell (%s)...', version);
zipfile = [tempdir, filesep, 'maxwell.zip'];
urlwrite(['http://m.lightlabs.co/', version, '.zip'], zipfile);
unzip(zipfile, tempdir);
path(genpath([tempdir, filesep, 'lightlabs-maxwell']), path);
fprintf(' done\n');
