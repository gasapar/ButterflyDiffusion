function d2 = WAVE_ANALYZER_v2(pret, n)

x = log(n);
y = log(pret);
d2 = nan(size(x));


% Analytical solution to Ax=b, x =...
%{
-(A1_2*b2 - A2_2*b1)/(A1_1*A2_2 - A1_2*A2_1)
 (A1_1*b2 - A2_1*b1)/(A1_1*A2_2 - A1_2*A2_1)
%}

A1_1 = x(1:end - 2) - x(2:end - 1);
A2_1 = x(3:end) - x(2:end - 1);
A1_2 = A1_1 .^ 2;
A2_2 = A2_1 .^ 2;

b1 = y(1:end - 2) - y(2:end-1);
b2 = y(3:end) - y(2:end - 1);

d2(2:end-1) = 2 *...
    (A1_1 .* b2 - A2_1 .* b1) ./...
    (A1_1 .* A2_2 - A1_2 .* A2_1);
end