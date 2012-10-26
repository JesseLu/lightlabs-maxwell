%% maxwell_terminate_cluster 
% Terminate a Maxwell cluster.

%%% Syntax
%  maxwell_terminate_cluster('cluster-name')

%%% Description
% Terminate a Maxwell cluster. Termination can be manually supervised via the
% EC2 management console (https://console.aws.amazon.com/ec2).

function maxwell_terminate_cluster(cluster_name, varargin)

    % Used verbosity = 1 for debug, 0 for normal mode.
    if isempty(varargin)
        verbosity = 0;
    else 
        verbosity = varargin{1};
    end

    % Get AWS credentials.
    [aws_id, aws_key] = maxwell_aws_credentials();

    % Run the command.
    [status, response] = maxwell_command(aws_id, aws_key, 'TERMINATE', ...
                                        cluster_name, 0, verbosity);
    
    % Destroy the entry in the dns look-up table.
    my_clusterlocate(cluster_name, {});

end


