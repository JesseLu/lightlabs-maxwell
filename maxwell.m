classdef maxwell
    % MAXWELL provides the following methods to perform electromagnetic 
    % simulations on Amazon's Elastic Compute Cloud (EC2).
    %
    % MAXWELL Methods:
    %    maxwell.aws_credentials - Description 
    %    maxwell.launch - Description 
    %    maxwell.solve - Description 
    %    maxwell.solve_async - Description 
    %    maxwell.terminate - Description 

    methods (Static)

function aws_credentials(id, key)
% MAXWELL.AWS_CREDENTIALS
% Store Amazon Web Services (AWS) security credentials needed to launch and
% terminate Maxwell clusters.
% To obtain your AWS credentials go to 
% https://portal.aws.amazon.com/gp/aws/securityCredentials#access_credentials
% or find the tutorial screencast at
% http://www.iorad.com/?a=app.embed&remote=true&accessCode=GUEST&module=4897&mt=How-to-get-your-AWS-credentials

%%% Syntax
%  maxwell.aws_credentials('aws-access-key-id', 'aws-secret-access-key');
    maxwell_aws_credentials(id, key)
end

%% maxwell.launch
% Launch a Maxwell cluster.

%%% Syntax
%  maxwell.launch('cluster-name', 2); % Create a 2-node cluster.

%%% Description
% Launches a Maxwell cluster on AWS. The cluster consists of 1 master and
% multiple nodes. The number of nodes must be a positive integer and may
% be limited to the number of cg1.4xlarge spot instances that your AWS
% account is allotted by Amazon (typically 10). You can request more
% instances at http://aws.amazon.com/contact-us/ec2-request/.
%
% Cluster launches typically take around 5 minutes and all clusters can be
% monitored from the Elastic Compute Cloud (EC2) management console at:
% https://console.aws.amazon.com/ec2/.  If needed clusters can also be manually 
% terminated from the EC2 management console. 
% 
% Note that Maxwell uses Spot EC2 instances in order to return considerable 
% cost savings to users. For more information on spot instances see 
% http://aws.amazon.com/ec2/spot-instances/ . The caveat is that there is a chance
% that the cluster will be abruptly terminated by Amazon, without warning.
% If this occurs simply terminate the cluster and launch a new one.
%
% Lastly, the master Amazon Machine Image (AMI) must be purchased at ***.
function launch(cluster_name, num_nodes)
    maxwell_launch_cluster(cluster_name, num_nodes);
end

%% maxwell.solve
% Solve an electromagnetic simulation.

%%% Syntax
%  [E, H, err, success] = maxwell.solve('cluster-name', num_nodes, ...
%                                         omega, ...
%                                         d_prim, d_dual, s_prim, s_dual, ...
%                                         mu, epsilon, E, J, ...
%                                         max_iters, err_thresh);

%%% Description
% Uploads a simulation to a Maxwell cluster, waits for the simulation to 
% finish, and then download the simulation back into Matlab.

%%% Example
% TODO: Put a really good and easy example here!!!!!
function [E, H, err, success] = solve(varargin)
    sim_finish = maxwell_simulate_async(varargin{:});
	hf = figure;
    while ~sim_finish(hf) % Wait for simulation to finish.
	end
    [is_finished, E, H, err, success] = sim_finish(hf);
end

%% maxwell.solve_async
% Solve an electromagnetic simulation asynchronously.

%%% Syntax
%  finish_solve = maxwell.solve_async(<<same inputs as maxwell.solve>>);
%  [is_finished, E, H, err, success] = finish_solve();

%%% Description
% Asynchronous version of maxwell.solve. The simulation is uploaded, and
% the method returns before the simulation is completed. Instead of returning
% the result, a callback function is returned which the user can query to
% retrieve the solution once it is available.
%
% The first output parameter of the callback function is set to true (1) 
% once the simulation is completed, at this point the remaining output
% parameters of the callback function (E, H, err, success) are then valid.

%%% Example
% TODO: Put example similar to maxwell.solve example here.
function [finish_solve] = solve_async(varargin)
    finish_solve = maxwell_simulate_async(varargin{:});
end

%% maxwell.terminate
% Terminate a Maxwell cluster.

%%% Syntax
%  maxwell.terminate('cluster-name')

%%% Description
% Terminate a Maxwell cluster. Termination can be manually supervised via the
% EC2 management console (https://console.aws.amazon.com/ec2).

function terminate(cluster_name)
    maxwell_terminate_cluster(cluster_name);
end


    end % End methods.
end % End classdef.






