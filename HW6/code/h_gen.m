function h_gen(seed)

rng(seed);

rng(882502);

SNR_dB = 30; % dB = log10(ratio)
N0 = 1/10^(SNR_dB/10);

SC_IND_DATA = [2:7 9:21 23:27 39:43 45:57 59:64];

H = 1 + randn(1,64)*0.1;
H(SC_IND_DATA) = H(SC_IND_DATA);

l_rx_vec_air = 81445;
n_vec = sqrt(N0/2) .* complex(randn(1,l_rx_vec_air), randn(1,l_rx_vec_air));

save('input.mat', 'H', 'n_vec')