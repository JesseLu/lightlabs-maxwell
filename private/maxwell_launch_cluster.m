%% maxwell_launch_cluster
% Launch a Maxwell cluster.

%%% Syntax
%  maxwell_launch_cluster('cluster-name', 2); % Create a 2-node cluster.

%%% Description
% Launches a Maxwell cluster on AWS. The cluster consists of 1 master and
% multiple nodes. The number of nodes must be a positive integer and may
% be limited to the number of cg1.4xlarge spot instances that your AWS
% account is allotted by Amazon (typically 10). You can request more
% instances at http://aws.amazon.com/contact-us/ec2-request/.
%
% Cluster launches typically take around 5 minutes and all clusters can be
% monitored from the Elastic Compute Cloud (EC2) management console at:
% https://console.aws.amazon.com/ec2/.
% If needed clusters can also be manually terminated from the EC2 management
% console.
%
% Lastly, the master Amazon Machine Image (AMI) must be purchased at ***.

function maxwell_launch_cluster(cluster_name, num_nodes, varargin)
    
    % Verbosity = 1 is debug mode, 0 is normal mode.
    if isempty(varargin)
        verbosity = 0;
    else 
        verbosity = varargin{1};
    end

    % Check number of nodes.
    if num_nodes <= 0
        error('Must request a positive integer number of nodes.')
    end

    % Get AWS credentials.
    [aws_id, aws_key] = maxwell_aws_credentials();

    % Send the command.
    [status, response] = maxwell_command(aws_id, aws_key, 'LAUNCH', ...
                                        cluster_name, num_nodes+1, verbosity);

    % Regular expression for extracting the dns_name, password, and 
    % SSL certificate data for the cluster from the launch response.
    tokens = regexp(response, 'maxwell-server/startup\ (.*?amazonaws\.com) (.*?)''.*(-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----)', 'tokens');
    
    % Store the cluster data.
    if ~isempty(tokens)
        data = {tokens{1}{1}, tokens{1}{2}, tokens{1}{3}, num_nodes};
        my_clusterlocate(cluster_name, data);
    else
        error('Launch failure, could not retrieve cluster data.');
    end

end

