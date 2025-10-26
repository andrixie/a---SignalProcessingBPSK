function detected_bits = Dec_dev(inbound)
%DEC_DEV Nearest-constellation detection (default: BPSK)
%   detected_bits = Dec_dev(inbound)
%   - inbound : vector or matrix of received samples (real or complex)
%   - detected_bits : int64 array of same size as inbound with detected bit
%                     values (0/1 for default BPSK)

    % default BPSK constellation and mapping
    constellation = [-1; 1];           % column vector (M x 1)
    bit_mapping  = int64([0; 1]);      % column vector (M x 1)

    if isempty(inbound)
        detected_bits = int64([]);
        return
    end

    % vectorized nearest-neighbor detection
    sz = size(inbound);
    x = inbound(:);                    % (N x 1)
    D = abs(x - constellation.');      % (N x M) distances
    [~, idx] = min(D, [], 2);          % nearest index per sample
    detected_bits = reshape(bit_mapping(idx), sz);  % restore original shape
end
