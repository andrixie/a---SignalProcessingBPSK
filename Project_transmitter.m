%% === Data & System Parameters ===
fs = 48000;
T = 1e-2;
eta = fs * T;
ts = T / eta;

%% === Modulation Specification ===
fc = 1200;

%% === RRC Filter ===
beta = 0.5;
L = 128;
hT = root_raised_cosine(beta, L, T, eta);

%% === Miscellaneous Setup ===
k_max = 5 * eta;
Nf = 1;
matrix = [];
snr_dB = 0:1:1;
error_across_db = [];
error = [];
SNR_linear = 10.^(snr_dB / 10);

%% === Training Sequence & Symbol Map ===
Nt = 200;
SM = [ +1+j +1-j -1+j -1-j ];  % 4-QAM symbol map
M = length(SM);
bitsPerSymbol = log2(M);
Es = sum(SM * SM') / M;
Eb = Es / bitsPerSymbol;

%% === Message Bitstream Preparation ===
msg = 'iloveian';
msg8 = uint8(msg);
msgbit = int2bit(msg8, 8);
msgbitarr = reshape(msgbit, 1, []);
Na = length(msg);
Nabit = int2bit(Na, 8);
Nabitarr = reshape(Nabit, 1, []);

%% === Transmission Loop ===
for i = 1:Nf
    rng(292);
    
    train_Seq = randi([0, 1], 1, Nt);
    train_Seq = [1, train_Seq];
    Nt = Nt + 1;

    head = [train_Seq, Nabitarr];
    asend = msgbitarr;
    a = [head, asend];
    a = int64(a);

    fprintf('Transmitted Training: %s\n', sprintf('%d ', train_Seq));
    fprintf('Transmitted len in bit: %s\n', sprintf('%d ', Nabit));
    fprintf('Transmitted Message: %s\n', sprintf('%d ', asend));
    fprintf('expected uint8: %s\n', sprintf('%d ', msg8));

    %% === Modulation ===
    ah = Sym_map(a);
    vt = conv(upsample(ah, eta), hT);
    vt = vt(1:end - eta + 1);
    tvt = (0:length(vt)-1) * ts;
    x = real(vt .* sqrt(2) .* exp(1j * 2 * pi * fc * tvt));
    x = x / max(abs(x));

    %% === Acoustic Playback (TX End) ===
    player = audioplayer(x, fs);
    play(player);
    return  % comment this out to test full channel + receiver

    %% === Channel with Random Delay (RX Test Only) ===
    delay = randi([0, k_max], 1, 1);
    rct = [zeros(1, delay), x, zeros(1, k_max - delay)];

    %% === Demodulation ===
    t = (0:length(rct)-1) * ts;
    y = rct .* sqrt(2) .* exp(-1j * 2 * pi * fc * t);
    hR = fliplr(hT); 
    rt = conv(y, hR) * ts;

    %% === Delay Estimation via Correlation ===
    mu = zeros(1, k_max + 1);
    for k = 0:k_max
        mu(k + 1) = abs(sum(rt((eta + k + (0:Nt - 1) * eta)) .* conj(Sym_map(train_Seq))) / Nt);
    end
    [~, idx] = max(mu);
    k_hat = idx - 1;
    rt = rt((k_hat + 1):end);

    %% === Symbol Detection ===
    r0 = rt(eta:eta:end);
    tr0 = (0:length(rt)-1) * ts;

    %% === Phase/Channel Compensation ===
    q = (1 / Nt) * sum(r0(1:Nt) ./ Sym_map(train_Seq));
    zn = r0 / q;

    %% === Header Decoding ===
    train_removed = zn(Nt + 1:end);
    templen = train_removed(1:8);
    templendet = Dec_dev(templen);
    msglen = bit2int(uint8(templendet'), 8);

    %% === Message Recovery ===
    z = train_removed(8 + 1 : msglen * 8 + 8);
    ann = Dec_dev(z);

    %% === Results ===
    fprintf('k value = %d\n', k_hat);
    fprintf('k value expected = %d\n', delay);
    fprintf('Received Message: %s\n', sprintf('%d ', ann));

    nErrs = sum(xor(asend, ann));
    fprintf('Number of Errors: %d\n', nErrs);
end
