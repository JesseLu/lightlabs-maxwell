%% Maxwell Documentation
% Welcome to the official documentation for Maxwell!
% If something seems to be missing, just use <http://ask.lightlabs.co>.
%%

%% Hello! from the creators of Maxwell.
% 
% Hi, we're Jesse and Wonseok, co-founders at Lightlabs.co and the guys behind Maxwell. We built Maxwell to turbo-charge our research as PhD students at Stanford, and we hope it boosts whatever your working on as well!
% 
% We continue to work hard on making Maxwell the most powerful and enjoyable tool in your computational toolbox, and so if you ever have any questions, or if there's ever anything you need help with regarding Maxwell, please bring it up on <ask.lightlabs.co>, which is forwarded to our inboxes.
%
% 
% Thank you for taking the time to get to know Maxwell!

%% A quick taste of Maxwell
% 
% Okay, let's cut straight to the chase and give you a little taste of Maxwell right off the bat.
%
% First, here's an overview of what a (short) Maxwell session might look like.

eval(urlread('http://m.lightlabs.co/pre-release')) % Load Maxwell.

% Get your Amazon Web Services (AWS) Credentials ready.
maxwell.aws_credentials('access-key-id', 'secret-access-key'); 

% Launch a Maxwell cluster on Amazon's Elastic Compute Cloud (EC2) service.
maxwell.launch('cluster1', 4); % A 4-node cluster.

% Solve an electromagnetic simulation on the cluster.
maxwell.solve('cluster1', 4, {simulation_parameters});% Use all 4-nodes.

% Terminate the Maxwell cluster.
maxwell.terminate('cluster1');

%%
% Now, as an overview, you've reached the documentation of Maxwell, which consists only of the five |maxwell.*| commands above. However, when you load Maxwell, a powerful dynamic grid interface is also included.
%
% Just a few things you should know to get your hands around Maxwell:
%
% * Maxwell must be loaded everytime you start Matlab, use |eval(urlread('http://m.lightlabs.co/pre-release'))| to load Maxwell in just one command.
% * Maxwell is open-source, you can access the code yourself at <http://www.github.com/JesseLu/lightlabs-maxwell>.
% * This document has three main sections: Quick-start/tutorial, a cloud-computing deep-dive, and a numerical electromagnetics deep-dive. Use the deep-dive sections to really understand what's going on beneath the hood.
% * If you ever have any questions, use <http://ask.lightlabs.co>.
%

%% Quick-start
% Now that you have an idea of how Maxwell is used, why don't we guide you through an actual simulation on your Matlab session, so you can see how things look live?
%
% Just to make sure we're on the same page, you probably already have Maxwell loaded, but if you're ever doubtful, running the following never hurts:

eval(urlread('http://m.lightlabs.co/pre-release')) % One-command load.

%% 
% *First off, you'll need your AWS Access Credentials*, which you can obtain at <https://portal.aws.amazon.com/gp/aws/securityCredentials#access_credentials>. In particular, you're looking for an active _Access Key ID_ and it's corresponding _Secret Access Key_. Of course, if you don't have an AWS account you'll need to sign up for one first.
% 
% Once you have your eye on your AWS credentials, then you'll want to copy-and-paste them into Maxwell's |aws_credentials| function like so:
% 
%   maxwell.aws_credentials('access-key-id', 'secret-access-key');
%
% Take the following as an example:

maxwell.aws_credentials('AKIAJLYFDI6ZYE6WKU', '0Mi2d8MT9Uo8+P0VVmOVV2XdbOxv5UarS2rSaI');

%%
% Believe it or not, that's the only adminstrative task that we make you do. So with that our of the way, let's get on with the fun stuff, like actually launching a cluster!
%
% *To launch a cluster*, just choose a name for it, and the number of computational nodes you want it to have. Having a cluster name allows you to juggle multiple clusters (when you want to get fancy), and, as expected, the more worker nodes a cluster has, the more computational power is at its disposal.
%
% For our purposes, let's call our cluster 'cluster1', and boot it up with 2 worker nodes.

% This is how we launch clusters on Amazon EC2. Takes about 5 minutes.
maxwell.launch('cluster1', 2); % Yes, that's it. Really.

%%
% Cluster launches on EC2 take about 5 minutes, so while you're waiting let us tell you more about what the cluster actually consists of.
%
% Each cluster consists of one master node, and as many worker nodes as you want (or Amazon will let you have). Specifically, each worker node contains two Nvidia GPUs and, in EC2 lingo, are |cg1.4xlarge| spot request instances. Maxwell actually uses these GPUs to accelerate our solver, more on that in a later section though.
%
% While the cluster is still booting up, please visit <https://console.aws.amazon.com/ec2/home?region=us-east-1#s=Instances> where you can manually monitor the launch process (also try clicking on "Spot Requests" on the left sidebar).
%
% When the launch is successfully completed, you are ready (after only two lines of Matlab mind you!) to start solving electromagnetic simulations! We'll show you how to do this in two ways, first using the _synchronous_ solve function and then using its _asynchronous_ sibling.
%
% Now, just so you know, we won't cover the nitty-gritty of how we describe electromagnetic simulations until a later section; instead, we'll use the |example_simulation_parameters| function that comes with your Maxwell toolbox to generate them for us.
%
% *So, without further ado, let's solve an electromagnetic simulation!*

params = example_simulation_parameters([60 60 60]); % Let's start small (60x60x60 cells).
[E, H] = maxwell.solve('cluster1', 1, params{:}); % Go baby, go! Notice that we only use 1 node.

%% 
% You should get a plot similar to the one below.
%
% <<60x60x60.png>>
%
% And upon inspecting the solution using

imagesc(real(E{3}(:,:,30)')); axis equal tight;

%%
% you should obtain the (near-field) radiation pattern of a dipole.
%
% <<60x60x60_Ez.png>>
%

%% 
% Now that you're getting the hang of simulating, why not try something bigger?

params = example_simulation_parameters([200 200 60]); 
[E, H] = maxwell.solve('cluster1', 1, params{:}); % Solve using 1 node.
[E, H] = maxwell.solve('cluster1', 2, params{:}); % Now solve using 2 nodes (faster!).

%%
% So what's going on now? Well, besides simulating a larger space, we're comparing using either 1 or 2 nodes of the cluster (which has a total of 2 nodes) to solve the simulation. Naturally, the simulation which uses 2 nodes should run faster, although not nearly twice as fast (there is some communication cost which cannot be hidden).
%
% At this point, you may be wondering why anyone would _not_ use all the worker nodes available for each simulation. Great question! To answer it, let me introduce you to Maxwell's asynchronous solve capabilities.
%
% *Maxwell's asynchronous solve accepts the same input parameters*, but instead of blocking until the simulation is completed, a callback function is returned. This callback function should then be repeatedly called in order to get updates on the progress of the simulation, and to download the result once the simulation is completed. 
%
% This is illustrated with the simple example below:

params = example_simulation_parameters([200 200 60]);  
sim_finish = maxwell.solve_async('cluster1', 1, params{:}); % Asynchronous solve!
while ~sim_finish(); end % Loop until sim_finish() returns true, signalling simulation completion.
[is_done, E, H] = sim_finish(); % Download the solution fields.

%%
% What's so great about the asynchronous solve function is that it enables you to run multiple simulations in parallel!
%
% Take a look at this next example, which utilizes our 2-node cluster to simulate 2 simulations in parallel (1 node each):

params = example_simulation_parameters([200 200 60]);  

% Note that the subplot commands are needed so that the progress plots display in separate axes.
subplot 121; sim1 = maxwell.solve_async('cluster1', 1, params{:}); % Send a simulation to cluster1,
subplot 122; sim2 = maxwell.solve_async('cluster1', 1, params{:}); % and immediately send another, before the first even completes.

while ~all([sim1(), sim2()]); end % Monitor simulations until completed.

% Get our results.
[is_done1, E1, H1] = sim1();
[is_done2, E2, H2] = sim2();

%%
% We hope you are starting to get excited about the possibilities that Maxwell opens up! Namely, that supercomputer-like powers are available from simple Matlab sessions!
%
% Now, we want you to try one more thing before we finish up. Remember how our cluster consists of only 2 nodes? What happens if we over-subscribe our cluster by asking it to solve two simulations using 2 nodes each? Try it out for yourself!

params = example_simulation_parameters([200 200 60]);  
subplot 121; sim1 = maxwell.solve_async('cluster1', 2, params{:}); % This simulation asks for 2 nodes now.
subplot 122; sim2 = maxwell.solve_async('cluster1', 2, params{:}); % as does this one.

while ~all([sim1(), sim2()]); end % Monitor simulations until completed.

%%
% *As you've probably guessed, Maxwell clusters have a built-in scheduling system*. This system stores all simulation requests in a queue, and then executes them on various nodes as these become available. In other words, you can basically throw as many simulations as you like at a Maxwell cluster, and they will all eventually be processed! This allows you to fully utilize the cluster by making sure it is always busy. And, of course, you don't need to wait for any simulations to finish if you use the asynchronous solve function.

%%
% *Now that you've seen how Maxwell works, we can terminate our cluster*. To manually monitor cluster termination, use <http://console.aws.amazon.com/ec2/>. Once you have your browser there, click on |Instances| in the left side-bar, and then terminate your cluster (from Matlab, of course) like so:

maxwell.terminate('cluster1'); % Bye-bye for now.

%%
% Just a couple more words about cluster termination. If a launch is botched, be sure to still attempt a termination, so that the failed launch will be cleaned up. And that's it! Congrats on completing Maxwell's quick-start!

%% Understanding Maxwell: using the Amazon Elastic Compute Cloud (EC2)
%
% Maxwell makes use of Amazon's Elastic Compute Cloud (EC2) service in order to deliver supercomputer-like powers to your local Matlab installation. The purpose of this section is to help you understand exactly how this happens.
%
% *The first thing to understand is that Maxwell uses your own Amazon Web Services (AWS) account to launch/terminate clusters*. Although we operate a control server to aid in this process, the clusters are run using your AWS account (that's why you can monitor launches manually through your own AWS console, for instance). This also means that all billing runs through Amazon, we never touch or see your charge card.
%
% *Secondly, know that Maxwell is cryptographically secure*. All the communication involved in Maxwell is encrypted, from the launch/terminate commands to the uploading/downloading of simulation information.
%
% With the understanding of these two basic ideas, you should be well prepared to understand how Maxwell uses Amazon EC2.
%
% *What is a Maxwell cluster made of?* A Maxwell cluster is made up of 1 master node, and a variable number of worker nodes that you choose. In Maxwell terminology, a 2-node cluster consists of 1 master and 2 worker nodes.
%
% While the master node does not take part in computational tasks, it serves as a critical central repository for input and output simulation files. In EC2 terminology, it is an on-demand m1.large instance.
%
% The worker nodes is where all the numerical computation takes place. Each worker node is an EC2 GPU Cluster Compute instance (|cg1.4xlarge|). This means that each worker node contains two Nvidia M2050 GPUs, where most of Maxwell's numerical computation occurs. As opposed to the master node which is launched as an on-deman instance, Maxwell's worker nodes are launched as spot request instances (<http://aws.amazon.com/ec2/spot-instances/>), in order to take advantage of large cost-savings (>50%).
%
% The drawback to using spot request instances for the worker nodes is that there is the chance of sudden termination of these instances. This happens rather infrequently, but when it does, there is no need to panic. All that is lost is the simulations which had not yet completed. The master will still be available, so all previously completed but un-downloaded simulations will still be available.
%
% If a sudden termination should occur, simply download the finished simulations (using the callback function for asynchronous calls), terminate the cluster (in order to terminate the master), launch a new cluster and resume simulating.
%
% *Much of the functionality of the cluster is provided by StarCluster* (<http://star.mit.edu/cluster>), including the master-worker setup and the scheduling system. Starcluster is a great resource, and we highly encourage you to use it for your own scientific application on AWS.
%
% *Lastly, but most importantly is pricing*. More details to follow shortly.


%% Understanding Maxwell: the finite-difference frequency-domain (FDFD) method
%
% Now that you have an understanding of how Maxwell uses Amazon EC2, all you need to understand is how Maxwell forms electromagnetic simulation problems. Note: referring to Wonseok's paper (<http://dx.doi.org/10.1016/j.jcp.2012.01.013>) will be helpful for this section if you want to dig _real_ deep.
%
% *Maxwell solves the finite-difference frequency-domain (FDFD) method for electromagnetics*, which involves solving the following time-harmonic equation for the electric field, $E$:
% 
% $$ (\nabla \times \mu^{-1} \nabla \times - \omega^2 \epsilon) E = -i \omega J. $$
%
% As opposed, to a finite-difference time-domain (FDTD) solver, Maxwell solves the electromagnetic wave equation above for a fixed frequency (now you know where the second 'F' in FDFD signifies). There are many advantages to an FDFD or frequency-domain approach:
%
% * direct access to the frequency-domain data,
% * precise mathematical definition of simulation error,
% * simple sourcing and measurement of input and output modes in the simulation,
% * explicit definition of material dispersion, and
% * ability to precisely calculate eigenmodes of the system.
%
% We hope that you will come to appreciate these advantages as you continue to use Maxwell.
%
% *For now, we want to show you how Maxwell gives you complete control over all simulation parameters*. These are the input parameters that are used in the |maxwell.solve| and |maxwell.solve_async| functions. So without further ado...
%
% * |omega|: This is the angular frequency of of the simulation and is equal to $2 \pi f$ where $f$ is the frequency of the simulation. This parameter must be a complex scalar.
% * |d_prim, d_dual|: These parameters define the FDFD grid spacing for Maxwell. These parameters are usually the hardest to understand for newcomers to FDFD, so get ready... and take a look at the Yee grid, which Maxwell uses in the FDFD equation:
%
% <<yee.png>>
%
% Notice that all the $E$ and $H$ vector field components are not co-located and are actually shifted by half a grid length in various directions. A little complicated right? Well, it's the job of |d_prim| and |d_dual| to sort all these distances out.
%
% First, both |d_prim| and |d_dual| are 3-element cell arrays, where each element is a vector corresponding to the grid distances in the x-, y-, and z-directions. Secondly, |d_prim| refers to distances between adjacent $E$-field vectors, while |d_dual| refers to distances between adjacent $H$-field vectors.
%
% Specifically, |d_prim{1}| is a vector denoting the distances between adjacent $E_x$ vectors in the x-direction, |d_prim{2}| denotes the distances between $E_y$ vectors in the y-direction, and |d_prim{3}| gives the distances between $E_z$ vectors in the z-direction. |d_dual| is similar, just replace $E$ with $H$.
%
% Congratulations, you're _almost_ there. There's only one more thing that you need to know. Boundary conditions.
%
% Maxwell works on a periodic wrap-around grid. This affects |d_prim| and |d_dual| because they also denote the wrap-around distance between the last and first components in the grid. Specifically, the _first_ element of the |d_prim| vectors corresponds to the distance between the corresponding last and first element, while the _last_ element of the |d_dual| vectors corresponds to the distance between the appropriate last and first elements. Okay, it's easy from here on out.
%
% One last note though, you'll most likely want to supply a absorbing boundary condition for your simulation. In that case, make sure you implement the stretched-coordinate perfectly-matched layer (sc-PML) scheme as outlined in Wonseok's paper (<http://dx.doi.org/10.1016/j.jcp.2012.01.013>). The values for |d_prim| and |d_dual| can be complex.
%
% * |mu, epsilon, E, J|: These parameters are all also 3-element cell arrays. However, each element is a 3-dimensional array representing the x-, y-, or z-component of the corresponding vector field, in that order. Other than that, these values are pretty straightforward; |mu| and |epsilon| represent the permeability and permittivity of the simulation space, respectively. |E| denotes the starting value for the simulation (all zeros usually works, if not try random); and |J| denotes the current source.
% * |max_iters|: This positive integer simply tells the solver to quit after so many iterations, even if convergence has not been reached.
% * |err_thresh|: A positive number (usually |1e-6|) at which the solver terminates. The error is calculater as $\|Ax - b\| / \|b\|$; where $A = (\nabla \times \mu^{-1} \nabla \times - \omega^2 \epsilon)$, $x = E$, and $b = -i \omega J$.
%

%%
% *Lastly, the output parameters for the solve functions are*:
%
% * |is_finished|: Only used for the asynchronous solve function. Set to |true| if the simulation is finished, |false| otherwise.
% * |E, H|: These are the solution vector fields to the electromagnetic wave equation and are 3-element cell arrays where each element is a 3-dimensional array. 
% * |err|: The error value at each iteration of the solve process.
% * |success|: Set to |true| if convergence was attained, set to |false| otherwise.
%

%% Conclusion
% So we hope that you are now off to the races with Maxwell!
%
% Once again, if anything is unclear or missing feel free to post on <http://ask.lightlabs.co> which we check feverishly! Happy simulating!
