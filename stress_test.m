function [cb] = stress_test(n, params)


    for i = 1 : n
        fprintf('%d: ', i);
        cb{i} = maxwell(params{:}, 'text');
        fprintf('\n');
    end

    done = false * ones(n, 1);
    while ~all(done)
        fprintf('%d/%d: ', length(find(done)), n);
        for i = 1 : n
            [done(i), E, H, err] = cb{i}(10); 
        end
        pause(60);
        fprintf('\n');
    end

%     done = false * ones(n, 1);
%     cnt = 0;
%     num_done = 0;
% 
%     while ~all(done)
%         % Throw in another simulation.
%         if cnt < n
%             cnt = cnt + 1;
%             fprintf('\n%d: ', cnt);
%             cb{cnt} = maxwellFDS(params{:});
%         end
% 
%         % Check the simulations that we have going.
%         for i = 1 : cnt
%             for k = 1 : 12
%                 [done(i), E, H, err] = cb{i}();
%             end
%         end
% 
%         if numel(find(done)) > num_done
%             num_done = numel(find(done));
%             fprintf('\n%d completed.', num_done);
%         else
%             fprintf('.');
%         end
%     end
end
