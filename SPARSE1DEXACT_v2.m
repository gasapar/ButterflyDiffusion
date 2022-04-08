function pret = SPARSE1DEXACT_v2(F, pjump, nmax, range)

pret = zeros(1, nmax);
N = numel(F);
pjump_all = pjump ./ diff(unique(floor(F)));

L = [0, pjump_all];
R = [pjump_all, 0];
S = 1 - L - R;

P = sparse(...
    [1:N, 2:N, 1:N-1],...
    [1:N, 1:N-1, 2:N],...
    [S, pjump_all, pjump_all]);




for i = floor(N/2)-range:floor(N/2)+range
    p = zeros(N, 1);
    p(i) = 1;
    for j = 1:nmax      
        p = P * p;        
        pret(j) = p(i);
    end
end
pret = pret / (2 * range + 1);

end
