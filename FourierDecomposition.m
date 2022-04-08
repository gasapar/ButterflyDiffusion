function [f, P] = FourierDecomposition(x, y)

arguments
    x (1, :) {mustBeReal}
    y (1, :) {mustBeReal}
end

T = (max(x) - min(x)) / numel(x);
Fs = 1/T;       
L = numel(y);

Y = fft(y);

P2 = abs(Y / L);
P = P2(1:(floor(L/2)+1));
P(2:end-1) = 2*P(2:end-1);
f = Fs * (0:floor(L/2)) / L * 2*pi;
end