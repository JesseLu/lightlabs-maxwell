function [cb] = stress_test(n, params)


    for i = 1 : n
        fprintf('%d: ', i);
        cb{i} = maxwellFDS(params{:});
    end

    done = false * ones(n, 1);
    while ~all(done)
        [done(i), E, H, err] = cb{i}(); 
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
