function F = DETERMINISTIC1DGENERATOR_v2(N, mask, h)

F = 0;

mask = mask(:);
for k = 1:h
    F = mask + N * F(:).';
end
F = F(:).';
end
