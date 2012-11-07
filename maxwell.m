classdef maxwell
% MAXWELL provides the following methods to perform electromagnetic 
% simulations on Amazon's Elastic Compute Cloud (EC2).
%
% MAXWELL Methods:
%    maxwell.aws_credentials - Store AWS Access credentials.
%    maxwell.launch - Launch a Maxwell cluster. 
%    maxwell.solve - Solve an electromagnetic simulation. 
%    maxwell.solve_async - Asynchronous version of the maxwell.solve method.
%    maxwell.terminate - Terminate a cluster.

    methods (Static)

function aws_credentials(id, key)
% MAXWELL.AWS_CREDENTIALS -- store AWS credentials
%
% Amazon Web Services (AWS) Access Credentials are needed to launch and
% terminate Maxwell clusters. Must be run before any other maxwell commands.
% 
% Obtain your AWS credentials <a href="https://portal.aws.amazon.com/gp/aws/securityCredentials#access_credentials">here</a>, or checkout the <a href="http://www.iorad.com/?a=app.embed&remote=true&accessCode=GUEST&module=4897&mt=How-to-get-your-AWS-credentials">tutorial</a>.
%
% Syntax:
%   MAXWELL.AWS_CREDENTIALS('access-key-id', 'secret-access-key');
%
% Example:
%   MAXWELL.AWS_CREDENTIALS('AKIAI53CHNXFFHNBUJFQ', '0Mi2d8MT9Uo2+P04VVmMVV8XdbOyv0UarS2rSaIz');

    maxwell_aws_credentials(id, key)
end

function launch(cluster_name, num_nodes)
% MAXWELL.LAUNCH -- launch a Maxwell cluster
%
% Maxwell clusters are launched on Amazon's Elastic Compute Cloud (EC2) and
% are directly connected to your Matlab session.
%
% Maxwell clusters consist of 1 master and multiple nodes.
% 
% Syntax:
%   MAXWELL.LAUNCH('cluster-name', num_nodes);
%
% Example:
%   MAXWELL.LAUNCH('cluster1', 4); % Launch a 4-node cluster.
%
% The number of nodes must be a positive integer and may
% be limited to the number of cg1.4xlarge spot instances that your AWS
% account is allotted by Amazon (typically 10). You can request more
% instances at http://aws.amazon.com/contact-us/ec2-request/. Ask specifically
% for an increase in the maximum limit of cg1.4xlarge spot instance requests.
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

    maxwell_launch_cluster(cluster_name, num_nodes);
end

function [E, H, err, success] = solve(varargin)
% MAXWELL.SOLVE -- solve an electromagnetic simulation
%
% Solve a finite-difference frequency-domain electromagnetic simulation
% on a Maxwell cluster. Does so by uploading a simulation to a Maxwell cluster, 
% waiting for the simulation to finish, and then downloading the simulation back 
% to Matlab.
%
% Syntax:
%   [E, H, err, success] = MAXWELL.SOLVE('cluster-name', num_nodes, ...
%                                         omega, ...
%                                         d_prim, d_dual, s_prim, s_dual, ...
%                                         mu, epsilon, E, J, ...
%                                         max_iters, err_thresh);
%
% Example:
%   Not yet available...

    
    sim_finish = maxwell_simulate_async(varargin{:}, gcf);
    while ~sim_finish() % Wait for simulation to finish.
	end
    [is_finished, E, H, err, success] = sim_finish();
end

function [finish_solve] = solve_async(varargin)
% MAXWELL.SOLVE_ASYNC -- asynchronous version of maxwell.solve
%
% Instead of waiting for the simulation to finish, this function ends after
% the uploading process is complete. Simulation is monitored and completed
% using the returned callback function.
% 
% Syntax:
%   finish_solve = maxwell.solve_async(<<same inputs as maxwell.solve>>);
%   [is_finished, E, H, err, success] = finish_solve();
%
% Mention plot functionality...
    finish_solve = maxwell_simulate_async(varargin{:});
end

function terminate(cluster_name)
% MAXWELL.TERMINATE -- terminate a Maxwell cluster
%
% Terminate a Maxwell cluster. Termination can be manually supervised via the
% EC2 management console (https://console.aws.amazon.com/ec2).
%
% Syntax:
%   MAXWELL.TERMINATE('cluster-name')
%
% Example:
%   MAXWELL.TERMINATE('cluster1') 

    maxwell_terminate_cluster(cluster_name);
end


    end % End methods.
end % End classdef.






