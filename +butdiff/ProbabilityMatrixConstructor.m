function P = ProbabilityMatrixConstructor(...
    mask, lin_scale, H, prob_jump)

arguments
    mask (1, :) {mustBeNonnegative}
    lin_scale (1, 1) {mustBePositive}
    H (1, 1) {mustBeNonnegative, mustBeInteger}
    prob_jump (1, 1)...
        {mustBePositive, mustBeLessThanOrEqual(prob_jump, 0.5)}...
        = 1/6
end

persistent MEMC
if isempty(MEMC)
    MEMC = memoize(@Constructor);
end
P = MEMC(mask, lin_scale, H, prob_jump);
end

function P = Constructor(mask, lin_scale, H, prob_jump)

prob_jump_dist =...
    prob_jump ./...
    diff(butdiff.VertexConstructor(mask, lin_scale, H));

vertex_num = numel(prob_jump_dist) + 1;

probab_stay_dist = [1, 1 - prob_jump_dist] - [prob_jump_dist, 0];

% sparse transition matrix
P = sparse(...
    [1:vertex_num, 2:vertex_num, 1:vertex_num-1],...
    [1:vertex_num, 1:vertex_num-1, 2:vertex_num],...
    [probab_stay_dist, prob_jump_dist, prob_jump_dist]);
end
