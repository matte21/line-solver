function [t, yt_e] = ode_solve(ode_h, trange, y0, ode_opt, options)
% [T, YT_E] = SOLVEODE(Y0)

if ode_opt.AbsTol <= 1e-3
    [t, yt_e] = feval(options.odesolvers.accurateOdeSolver, ode_h, trange, y0, ode_opt);
else
    [t, yt_e] = feval(options.odesolvers.fastOdeSolver, ode_h, trange, y0, ode_opt);
end
end

