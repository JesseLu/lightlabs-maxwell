%% maxwell_clusterlocate
% Remembers where the master is for various clusters.
function [varargout] = maxwell_clusterlocate(varargin)
    mlock
    persistent alias data % Store values in alias-data pairs.
    if nargin == 2 % Store data
        k = length(alias) + 1;
        alias{k} = varargin{1};
        data{k} = varargin{2};
    elseif nargin == 1 % Return credentials.
        matches = find(strcmp(alias, varargin{1}));
        if isempty(matches)
            error('Could not find a cluster by that name.')
        elseif isempty(data{matches(end)})
            error('Could not find a cluster by that name.')
        else
            varargout = data{matches(end)};
        end
    else
        error('Invalid number of input parameters.')
    end
end



