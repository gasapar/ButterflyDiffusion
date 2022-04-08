function pret = CONTINUUM1DEXACT_v2(pjump, nmax)

if isempty(pjump)
    pjump = 1/6;
end

n = 1:nmax;
pret = zeros(size(n));
A = log(pjump);
B = log(1 - 2 * pjump);


for N = n   
    
    K = 0:N/2;
    
    G1 = gammaln(N+1) -...
        2*gammaln(K + 1) -...
        gammaln(N - 2*K + 1) +...
        2 * K * A + (N-2*K) * B;
     pret(N) = sum(exp(G1));

end

% semilogx(n, pret .* n .^ (1/2), 'k.')
% axis([1 nmax -inf inf])
% grid on
% xlabel('n')
% ylabel('p_{ret}(n) n^{1/2}')
end

