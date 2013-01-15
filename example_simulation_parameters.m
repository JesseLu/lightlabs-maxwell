function [params] = example_simulation_parameters(dims)

    omega = 0.3;
    [s_prim, s_dual] = make_scpml(omega, dims, 10);
    f = {ones(dims), ones(dims), ones(dims)}; 
    E = {zeros(dims), zeros(dims), zeros(dims)}; 
    J = E;
    J{1}(dims(1)/2, dims(2)/2, dims(3)/2) = 1;
    params = {omega, s_prim, s_dual, f, f, E, J, 5e4, 1e-6};
end



%% Calculates s_prim and s_dual for a regularly spaced grid of dimension DIMS.
% Grid spacing assumed to be 1.
function [s_prim, s_dual] = make_scpml(omega, dims, t_pml)
    % Helper functions.
    pos = @(z) (z > 0) .* z; % Only take positive values.
    l = @(u, n) pos(t_pml - u) + pos(u - (n - t_pml)); % Distance to nearest pml boundary.

    % Compute the stretched-coordinate grid spacing values.
    for k = 1 : 3
        s_prim{k} = 1 - i * (4 / omega) * (l(0:dims(k)-1, dims(k)) / t_pml).^4;
        s_dual{k} = 1 - i * (4 / omega) * (l(0.5:dims(k)-0.5, dims(k)) / t_pml).^4;
    end
end
