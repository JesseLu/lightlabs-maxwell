%% maxwell_aws_credentials
% Store Amazon Web Services (AWS) security credentials needed to launch and
% terminate Maxwell clusters.
% To obtain your AWS credentials go to 
% https://portal.aws.amazon.com/gp/aws/securityCredentials#access_credentials
% or find the tutorial screencast at
% http://www.iorad.com/?a=app.embed&remote=true&accessCode=GUEST&module=4897&mt=How-to-get-your-AWS-credentials

%%% Syntax
%  maxwell_aws_credentials('aws-access-key-id', 'aws-secret-access-key');

function [varargout] = maxwell_aws_credentials(varargin)
    mlock % Prevents deletion of persistent variables.
    persistent id key

    if nargin == 2 % Store credentials.
        id = varargin{1};
        key = varargin{2};

        % Include the Maxwell java library as well.
        javaaddpath('http://s3.amazonaws.com/lightlabs-maxwell/Maxwell1.jar');

    elseif nargin == 0 % Return credentials.
        if isempty(id) || isempty(key)
            error('No credentials available.')
        end
        varargout = {id, key};

    else
        error('Invalid number of input parameters.')
    end
end

