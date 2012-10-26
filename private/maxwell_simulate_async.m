%% maxwell_simulate_async
% Simulate!
 
function [sim_finish] = maxwell_simulate_async(cluster_name, num_nodes, ...
                            omega, d_prim, d_dual, s_prim, s_dual, ...
                            mu, epsilon, E, J, ...
                            max_iters, err_thresh, view_progress)

    % Check to make sure num_nodes is valid.
    [dns, pwd, cert, max_nodes] = my_clusterlocate(cluster_name);
    if num_nodes > max_nodes
        error(sprintf('Cluster %s consists of only %d nodes.', ...
                        cluster_name, max_nodes));
    end


        %
        % Create input file.
        %

    %% Make sure hdf5 compression is available.
    if ~H5Z.filter_avail('H5Z_FILTER_DEFLATE') || ...
        ~H5ML.get_constant_value('H5Z_FILTER_CONFIG_ENCODE_ENABLED') || ...
        ~H5ML.get_constant_value('H5Z_FILTER_CONFIG_DECODE_ENABLED') || ...
        ~H5Z.get_filter_info('H5Z_FILTER_DEFLATE')
        error('HDF5 gzip filter not available!') 
    end
        
        %
        % Verify inputs.
        %

    % Check omega.
    if numel(omega) ~= 1 
        error('OMEGA must be a scalar.');
    end

    % Check shapes of mu, epsilon, J.
    % Specifically, make sure all component fields have shape xx-yy-zz.
    shape = size(epsilon{1}); % Make sure all 3D fields have this shape.
    if any([numel(mu), numel(epsilon), numel(E), numel(J)] ~= 3)
        error('All 3D vector fields (MU, EPSILON, E, J) must have three cell elements.');
    end
    fields = [mu, epsilon, E, J];
    for k = 1 : length(fields)
        if any(size(fields{k}) ~= shape)
            error('All 3D vector fields (MU, EPSILON, E, J) must have the same shape.');
        end
    end

    % Check shapes of d_prim, d_dual, s_prim, and s_dual.
    % Specifically, each array of each must have length xx, yy, and zz respectively.
    if any([numel(d_prim), numel(d_dual), numel(s_prim), numel(s_dual)] ~= 3)
        error('D_PRIM, D_DUAL, S_PRIM, and S_DUAL must each have three cell elements.');
    end
    for k = 1 : 3
        d_prim{k} = d_prim{k}(:);
        d_dual{k} = d_dual{k}(:);
        s_prim{k} = s_prim{k}(:);
        s_dual{k} = s_dual{k}(:);
        if (length(d_prim{k}) ~= shape(k)) || (length(d_dual{k}) ~= shape(k) || ...
            length(s_prim{k}) ~= shape(k)) || (length(s_dual{k}) ~= shape(k))
            error('The lengths of D_PRIM, D_DUAL, S_PRIM, and S_DUAL vectors must be xx, yy, and zz, in that order.')
        end
    end

    % Make sure the value for max_iters is valid.
    if mod(max_iters,1) ~= 0 || max_iters <= 0 || ~isreal(max_iters)
        error('MAX_ITERS must be a positive integer.');
    end

    % Make sure the value for err_thresh is valid.
    if ~isfloat(err_thresh) || err_thresh <= 0 || err_thresh >= 1 || ~isreal(err_thresh)
        error('ERR_THRESH must be a positive number between 0 and 1.');
    end

    % Make sure the value for view_progress is valid.
    if all(~strcmp(view_progress, {'plot', 'text', 'none'}))
        error('VIEW_PROGRESS must be either ''plot'', ''text'', or ''none''.');
    end


    %% Construct the exportable hdf5 file.
    % Make all cells use the same write-out function.
        
    % Choose a filename. TODO: Randomize filename to allow for parallelization.
    filename = ['.maxwell.', ...
                strrep(num2str(clock), ' ', ''), ...
                num2str(abs(randn(1)))];

    % Open the hdf5 file, use read-write mode.
    file = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');

    % Write omega to the input file. 
    h5write_complex(file, 'omega', omega)

    % Write d_prim, d_dual, s_prim, and s_dual to the input file.
    h5write_field(file, 'd_prim', d_prim);
    h5write_field(file, 'd_dual', d_dual);
    h5write_field(file, 's_prim', s_prim);
    h5write_field(file, 's_dual', s_dual);

    % Write mu, epsilon, E, and J to the input file.
    h5write_field(file, 'mu', mu);
    h5write_field(file, 'epsilon', epsilon);
    h5write_field(file, 'E', E);
    h5write_field(file, 'J', J);

    % Write out max_iters and err_thresh.
    hdf5write(filename, 'max_iters', int64(max_iters), 'WriteMode', 'append');
    hdf5write(filename, 'err_thresh', double(err_thresh), 'WriteMode', 'append');

    H5F.close(file) % Close file, flushing to storage.

        
        % 
        % Send input file to server.
        %

    % Obtain the cluster's information.
    [dns, pwd, cert] = my_clusterlocate(cluster_name);

    % POST parameters used to send the simulation to the cluster.
    url = ['https://', dns, ':29979'];
    params = {'username', 'maxwell_user', ...
                'password', pwd, ...
                'nodes', num2str(floor(2*num_nodes))}; % Two GPUs on each node.

    % Make sure we have access to java. Needed for network http connections.
    if ~usejava('jvm')
       error('MATLAB:urlreadpost:NoJvm','URLREADPOST requires Java.');
    end

    % Be sure the proxy settings are set.
    com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings


        %
        % SEND simulation.
        %

    send_start = tic;

    % Create a urlConnection.
    [urlConnection, errorid, errormsg] = maxwell_urlreadwrite(url, cert);
    if isempty(urlConnection)
        error(['Could not connect to url: ', url]);
    end

    urlConnection.setDoOutput(true); % Sets the request mode to POST.
    boundary = '*** maxwell_client boundary ***';
    urlConnection.setRequestProperty('Content-Type',...
        ['multipart/form-data; boundary=', boundary]);

    eol = [char(13),char(10)]; % End-of-line character.

    % Build the header, body and footer of the POST request.
    header = [];
    for k = 1 : 2 : length(params) % Form data for text parameters.
        header = [header, '--', boundary, eol, ...
                    'Content-Disposition: form-data; name="', params{k}, '"', ...
                    eol, eol, params{k+1}, eol];
    end
    header = java.lang.String([header, '--', boundary, eol, ...
                'Content-Disposition: form-data; name="in"; filename="dummy"', eol, ...
                'Content-Type: application/octet-stream', eol, eol]); 
                % Form data for binary data (the simulation file.
    file = java.io.File(filename);
    footer = java.lang.String([eol, '--', boundary, '--', eol]);

    % We used a streaming connection, crucial for large files.
    total_length = header.length + file.length() + footer.length;
    urlConnection.setFixedLengthStreamingMode(total_length);
    outputStream = java.io.DataOutputStream(urlConnection.getOutputStream);

    outputStream.write(header.getBytes(), 0, header.length); % Send the header.

    fprintf('Sending...'); % Send the file.
    infile = java.io.FileInputStream(file);
    stream_send({infile}, {outputStream}, 'sent');

    outputStream.write(footer.getBytes(), 0, footer.length); % Send the footer.

    infile.close(); % Close off the message.
    outputStream.flush();
    delete(filename); % Delete file.

    % Check for a response code error.
    % This usually means that one of the parameters that we send was 
    % invalid.
    if (urlConnection.getResponseCode() ~= 200)
        error('%s', char(urlConnection.getHeaderField(0)));
    end

    % Okay, we have a valid response then.
    % Look at the headers in the response message to get the information
    % we need to download the result files.
    k = 1;
    redirect_to = {url}; % Default redirect that is tried last.
    while true
        % Get the next header.
        key = char(urlConnection.getHeaderFieldKey(k));
        field = char(urlConnection.getHeaderField(k));
        if isempty(key) && isempty(field) % No more headers.
            break
        end

        % Process header information.
        switch key
            case 'Maxwell-Redirect' % Redirect addresses for faster downloads.
                redirect_to{end+1} = field;
            case 'Maxwell-Name' % Server-side name of the results files.
                job_name = field;
        end
        k = k + 1;
    end

    
    % Prepare variables for use by the sim_callback function.
    inputStream = urlConnection.getInputStream(); 
    reader = java.io.BufferedReader(java.io.InputStreamReader(inputStream));
    res_log = []; % Stores the history of residual information.
    E = {}; % Stores E-field result.
    H = {}; % Stores H-field result.
    recent_line = ''; % Remembers the last status line.
    is_executing = true; 
    is_done = false; % Persistent variable for is_finished.
    is_success = []; % Persistent variable for success.

    % This is an inline function used to query the state of the simulation.
    % If this simulation is finished, then this function will also retrieve
    % the results of the simulation.
    % This function attempts to exit after INTERVAL seconds, but there is no
    % guarantee of this feature.
    function [is_finished, E_out, H_out, residuals, success] = ...
                sim_callback(interval, figure_handle)

        start_time = tic; % Timer to evaluate when we should exit.
        d = ''; 

        % While simulation is running, read in status updates.
        if is_executing
            while toc(start_time) < interval
                c = reader.readLine(); % Get the next status update.
              
                if isempty(c) && isnumeric(c) % Simulation done (EOF).
                    is_executing = false;
                    break
                else % Received the next status update.
                    d = char(c);
                    state = d(1:4);
                    data = d(5:end);
                    if strcmp(state, 'EXEC') % Process EXEC status.
                        if ~isnan(str2double(strtok(data))) % Found a residual.
                            res_log(end+1) = str2double(strtok(data));
                        elseif ~isempty(strfind(data, 'success')) % Sim result.
                            is_success = true;
                        elseif ~isempty(strfind(data, 'fail'))
                            is_success = false; 
                        end
                    end
                end
            end
        end

        if ~isempty(d) % Remember the most recent status update.
            recent_line = d;
        end

        % Finished getting status updates, plot residual data.
        if isempty(res_log) % No residual data.
            plot_data(1) = 1; % Default data, single point at (1,1).
        else
            plot_data = res_log;
		end
		set(0, 'CurrentFigure', figure_handle);
		ha = gca;
        semilogy(plot_data, 'b-'); % Plot with a red 'x' at the most recent point.
        hold(ha, 'on'); semilogy(length(plot_data), plot_data(end), 'rx'); hold(ha, 'off');
%         hold on; semilogy(length(plot_data), plot_data(end), 'rx'); hold off;
        title(recent_line);
        ylabel('residual');
        xlabel('iterations');
        drawnow


        if is_executing % Simulation not yet done, exit without downloading.
            is_finished = false;
            success = is_success;
            residuals = res_log;
            E_out = {};
            H_out = {};
            return
        end

        % Simulation is finished, close connection.
        reader.close();
        inputStream.close();
        outputStream.close();


            %
            % Retrieve simulation results.
            %

        if ~is_done % Only do this if not yet retrieved.

            % Generate endings (i.e. Ex_real, Ex_imag, Ey_real, ...).
            [r, u, A] = ndgrid('ri', 'xyz', 'EH');
            fields = strcat(cellstr(A(:)), cellstr(u(:)), cellstr(r(:)));
            endings = [strrep(strrep(fields, 'r', '_real'), 'i', '_imag')];
            N = length(endings);

            % Try the various redirect locations.
            % TODO: Implement Cloudfront.
            for l = length(redirect_to) : -1 : 1
                try
                    url = redirect_to{l};

                    % Create a new urlConnection.
                    [urlConnection, errorid, errormsg] = maxwell_urlreadwrite(url, cert);
                    if isempty(urlConnection)
                        error(['Could not connect to url: ', url]);
                    end

                     % Open up http connections.
                    for k = 1 : N
                        urlConnections{k} = maxwell_urlreadwrite(...
                            [url, '/.maxwell.', job_name, '.', endings{k}], cert);
                        if isempty(urlConnections{k})
                            error(['Could not connect to url: ', url]);
                        end
                        urlConnections{k}.connect();
                        if (urlConnections{k}.getResponseCode() ~= 200)
                            error('Could not find file (invalid simulation input).');
                        end
                        inputStreams{k} = urlConnections{k}.getInputStream();
                        fnames{k} = [filename, '.', endings{k}];
                        files{k} = java.io.FileOutputStream(fnames{k});
                        
                    end
                catch ME
                    % The redirect location didn't work, try the next one.
                    if l > 1
                        continue % Try next redirect url.
                    else % No more locations to try...
                        fprintf('\n');
                        error(ME.message)
                    end
                end
                
                fprintf('Connected to %s\n', url); % Redirect location worked!
                break 
            end

            % Download the simulation result files.
            fprintf('Receiving...');
            stream_send(inputStreams, files, 'received');
            for k = 1 : N % Close the files and connections.
                inputStreams{k}.close()
                files{k}.close()
            end

            % Load the result files into memory.
            my_load = @(f1, f2) permute(double(hdf5read(f1, '/data')) + ...
                                        i * double(hdf5read(f2, '/data'))...
                                            , [3 2 1]);
            E = {my_load(fnames{1}, fnames{2}), ...
                my_load(fnames{3}, fnames{4}), ...
                my_load(fnames{5}, fnames{6})};
            H = {my_load(fnames{7}, fnames{8}), ...
                my_load(fnames{9}, fnames{10}), ...
                my_load(fnames{11}, fnames{12})};

            % Delete the result files.
            for k = 1 : length(fnames)
                delete(fnames{k})
            end

            is_done = true; % Download successfully completed.
        end
     
        % Final output parameters.
        is_finished = is_done;
        success = is_success;
        residuals = res_log;
        E_out = E;
        H_out = H;

    end % End of inline function sim_callback().
    
    % Return the callback function to let the user complete the simulation.
    sim_finish = @(hf) sim_callback(0.3, hf);
    return
end

% Function used to stream data from multiple input streams to (corresponding)
% multiple output streams.
function stream_send (in, out, action_name)

    copier = MaxwellCopier; % Requires the Maxwell.jar library to be loaded.

    if length(in) ~= length(out)
        error('Unequal number of input and output streams.');
    end


    N = length(in);
    running = true;
    start_time = tic;
    status_time = start_time;
    prevlen = 0;

    while any(running)
        for k = 1 : N % Transfer some data.
            running = copier.copy(in{k}, out{k});
        end

        if toc(status_time) > 0.3 || all(~running) % Periodically give updates.
            megabytes = copier.total_bytes_transferred / 1e6;
            status_line = sprintf('[%1.2f MB %s (%1.2f MB/s)]', ...
                megabytes, action_name, megabytes/toc(start_time));
            fprintf([repmat('\b', 1, prevlen), status_line]); % Write-over.
            prevlen = length(status_line);
            status_time = tic;
        end
    end
    fprintf('\n');
end

%% Write a complex 3D vector-field to an hdf5 file.
function h5write_field(file, name, data)
    xyz = 'xyz'; 
    for k = 1 : numel(data)
        h5write_complex(file, [name, '_', xyz(k)], data{k});
    end
end

%% Write a complex-valued 1D or 3D array to an hdf5 file.
function h5write_complex(file, name, data)
 
    % Format data.
    if (ndims(data) == 2) && (size(data,2) == 1) % 1D data detected.
        N = 1;
        data = data;
        dims = numel(data);
        chunk_dims = dims;

    elseif ndims(data) == 3 % 3D data detected.
        N = 3;
        data = permute((data), [ndims(data):-1:1]); % Make data row-major.
        dims = fliplr(size(data)); % Size of the array.
        chunk_dims = [1 dims(2:3)]; % Should heavily affect compression.

    else
        error('Only 1-D or 3-D arrays accepted.')
    end


    % Create the dataspace.
    space = H5S.create_simple(N, dims, []);

    % Set dataspace properties.
    dcpl = H5P.create('H5P_DATASET_CREATE');
    H5P.set_deflate(dcpl, 1); % Deflation level: 0 (none) to 9 (most).
    H5P.set_chunk(dcpl, chunk_dims);

    % Create dataset and write to file.
    dset = H5D.create(file, [name, '_real'], 'H5T_IEEE_F64BE', space, dcpl); % Real part.
    H5D.write(dset, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', real(data));
    dset = H5D.create(file, [name, '_imag'], 'H5T_IEEE_F64BE', space, dcpl); % Imaginary part.
    H5D.write(dset, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', imag(data));

    % Close resources.
    H5P.close(dcpl);
    H5D.close(dset);
    H5S.close(space);
end




