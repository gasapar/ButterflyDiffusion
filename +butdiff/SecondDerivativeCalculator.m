function sec_der = SecondDerivativeCalculator(x, fx)

arguments
    x (1, :) {mustBeNumeric}
    fx (1, :) {mustBeNumeric}
end

sec_der = nan(size(x));


%{
Analytical solution to Ax=b:
syms a1 a2 b1 b2 real
A = [a1, a1^2; a2, a2^2];
b = [b1; b2];
x = simplify(A \ b)

(b2*a1^2 - b1*a2^2)/(a1*(- a2^2 + a1*a2))
   -(a1*b2 - a2*b1)/(a1*(- a2^2 + a1*a2))
%}

a1 = x(1:end - 2) - x(2:end - 1);
a2 = x(3:end) - x(2:end - 1);

b1 = fx(1:end - 2) - fx(2:end-1);
b2 = fx(3:end) - fx(2:end - 1);

sec_der(2:end-1) = 2 *...
    (a2 .* b1 - a1 .* b2)...
    ./...
    (a1 .* a2 .* (a1 - a2));
end