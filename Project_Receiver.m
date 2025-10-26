%% === Data & System Parameters ===
fs = 48000;
T = 1e-2;
eta = fs*T;
ts = T/eta;
fc = 1200;

%% === RRC Filter Design ===
beta = 0.5;
L = 128;
hT = root_raised_cosine(beta, L, T, eta);
%hT = sqrt(1/T) * ones(1, eta);  % Pulse shape (rectangular)

k_max = 300*eta;

%% === Initialization ===
Nf = 1;
matrix = [];

snr_dB = 0:1:1;
error_across_db = [];
error = [];
SNR_linear = 10.^(snr_dB / 10);

%% === Training Sequence & Symbol Map ===
Nt = 50;
SM = [ +1+j +1-j -1+j -1-j];    % 4-QAM symbol map
M = length(SM);                 % Constellation size
bitsPerSymbol = log2(M);        % Number of message bits per symbol
Es = sum(SM*SM') / M;           % Energy per symbol
Eb = Es / bitsPerSymbol;        % Energy per bit

%% === Message Bitstream Preparation === (dont really need this)
msg = 'iloveian';
msg8 = uint8(msg);
msgbit = int2bit(msg8,8);
msgbitarr = reshape(msgbit,1,[]);
Na = length(msgbitarr);

%% === Receiver Loop ===
for i = 1:Nf

    % === Training Sequence Generation ===
    rng(292);
    train_Seq = randi([0,1], 1, Nt);
    train_Seq = [1, train_Seq];
    Nt = Nt+1;
    asend = randi([0,1], 1, Na);
    asend = msgbitarr;
    a = [train_Seq, asend];

    %% === Record Incoming Audio ===
    duration = 7;
    recObj = audiorecorder(fs, 16, 1);
    disp('Listening...');
    recordblocking(recObj, duration);
    disp('Done.');
    file = getaudiodata(recObj)';
    file = file(:).';

    %check if there signal
    plot(file);
    title('Recorded waveform');


    %% === Demodulation ===
    t = (0:length(file)-1)*ts;
    y = file .* sqrt(2) .* exp(-j*2*pi*fc*t);
    hR = fliplr(hT); 
    rt = conv(y, hR) * ts; 

    %% === Delay Compensation ===
    mu = zeros(1,k_max+1);
    for k=0:k_max
        mu(k+1) = abs(sum(rt((eta+k + (0:Nt-1)*eta)) .* conj(Sym_map(train_Seq))) / Nt);
    end
    [mx,idx] = max(mu);
    k_hat = idx - 1;
    rt = rt((k_hat+1):end);

    %% === Symbol Detection ===
    r0 = rt(eta:eta:end);  %for std pulse
    %r0 = rt(L*eta+1:eta:end-L*eta);  %For Root raised cosine
    tr0 = (0:length(rt)-1) * ts; 

    %% === Channel Compensation ===
    q = (1/Nt)* sum(r0(1:Nt)./Sym_map(train_Seq));
    zn = r0/q;

    %% === Header Decoding ===
    train_removed = zn(Nt+1:end);
    templen = train_removed(1:8);
    %templen(int64(real(templen)) == -1) = 0;
    templendet = Dec_dev(templen);
    msglen = bit2int(uint8(templendet'), 8);

    %% === Message Extraction ===
    z = train_removed(8+1:msglen*8+8);
    ann = Dec_dev(z);

    %% === Output Display ===
    %decryptmsg = bit2int(ann', 8);
    fprintf('k value = %d\n', k_hat);
    %fprintf('k value expected = %d\n', delay);
    fprintf('Received length: %s\n', sprintf('%d ', msglen));
    fprintf('Received length in bit: %s\n', sprintf('%d ', templendet'));
    fprintf('Received Message: %s\n', sprintf('%d ', ann));
    %decryptmsg = bit2int(ann',8)
    %fprintf('Received Message in 8bit: %s\n', sprintf('%d ', decryptmsg));
    %fprintf('Received Message in str: %s\n', char(decryptmsg));

    %length(ann)
    %ann2 = ann(1:Na+Nt);
    %nErrs = sum(xor(asend, ann));
    %fprintf('Number of Errors: %d\n', nErrs);

end
