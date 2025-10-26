function h = root_raised_cosine(beta, L, T, eta)
%ROOT_RAISED_COSINE (Root raised cosine filter impulse response)
%
%   h = root_raised_cosine(beta, L, T, eta) returns the impulse response
%   samples of a root-raised-cosine (RRC) filter.
%
%   Inputs:
%     beta  - roll-off factor (0 <= beta <= 1)
%     L     - filter length in symbols (total span)
%     T     - symbol period (time units)
%     eta   - oversampling factor (samples per symbol, integer)
%
%   Output:
%     h     - impulse response samples (vector). The pulse is normalized
%             so that its discrete energy corresponds to unit symbol energy.
%
%   Notes:
%   - Time axis t is expressed in symbol intervals (multiples of T).
%   - Special-case formulas are used to avoid 0/0 at t == 0 and when
%     4 *beta* t == +/-1, matching the analytical limits of the RRC formula.
%   - The final normalization accounts for sampling: sum(h.^2) * (T/eta)
%     approximates continuous pulse energy over the truncated window.

    % time vector in symbol intervals, centered on zero:
    % from -L/2 to +L/2 (exclusive of the endpoint) with eta samples per symbol
    t = (-L/2*eta : L/2*eta-1) / eta;

    % helper term used in the closed-form expression
    bt = 4 * beta .* t;

    % numerator and denominator of the general RRC expression
    h1 = bt .* cos(pi * t * (1 + beta)) + sin(pi * t * (1 - beta));
    h2 = pi * t .* (1 - bt .* bt);

    % general sample values (will be fixed at singular points below)
    h = h1 ./ h2;

    % handle removable singularity at t == 0 (use analytical limit)
    % exact comparison to zero is acceptable because t is rational here
    h(t == 0) = 1 - beta + 4*beta/pi;

    % handle case where |4*beta*t| == 1 (another removable singularity)
    % use the known closed-form limit for these points
    idx = abs(bt) == 1;
    if any(idx)
        h(idx) = (beta / sqrt(2)) * ( (1 + 2/pi) * sin(pi/(4*beta)) + (1 - 2/pi) * cos(pi/(4*beta)) );
    end

    % scale by sqrt(T) to place units consistently (optional convention)
    h = h / sqrt(T);

    % normalize the truncated discrete pulse so that its sampled energy
    % corresponds to unit energy per symbol:
    % discrete energy = sum(h.^2) * (T/eta) approximates integral |h(t)|^2 dt
    h = h ./ sqrt(sum(h .* h) * T / eta);
end
