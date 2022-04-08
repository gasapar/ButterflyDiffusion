function prob_vec = ProbabilityConstructor(...
    mask, lin_scale, H, prob_jump, time_step, args)

arguments
    mask (1, :) {mustBeNonnegative}
    lin_scale (1, 1) {mustBePositive}
    H (1, 1) {mustBeNonnegative, mustBeInteger}
    prob_jump (1, 1)...
        {mustBePositive, mustBeLessThan(prob_jump, 0.5)}...
        = 1/6
    time_step (1, 1) {mustBePositive, mustBeInteger} = 1000
    args.StartPosition (:, :) = []
    args.CacheFolder (1, 1) string...
        = butdiff.CacheSetting().ProbabilityConstructorCacheFolder
end

global ProbabilityConstructor_P
global ProbabilityConstructor_MEMC


MEM_HSI = memoize(@HandleStartIdx);
start_idx = MEM_HSI(mask, lin_scale, H, prob_jump, args.StartPosition);


ProbabilityConstructor_P = butdiff.ProbabilityMatrixConstructor(...
    mask, lin_scale, H, prob_jump);
vec_len = size(ProbabilityConstructor_P, 1);


persistent GMF
if isempty(GMF)
    % access cache of cached functions
    GMF = memoize(@GetMemFun);
    GMF.CacheSize = 1000;
end

ProbabilityConstructor_MEMC = GMF(mask, lin_scale, H, start_idx, vec_len, args.CacheFolder);


cache_size_before = numel(ProbabilityConstructor_MEMC.stats.Cache.Inputs);
prob_vec = ProbabilityConstructor_MEMC(H, prob_jump, time_step);

% check if cache expanded
if cache_size_before < numel(ProbabilityConstructor_MEMC.stats.Cache.Inputs)
    % save cache after expansion
    cache_fullname = GetCacheFullName(...
        mask, lin_scale, H, start_idx, vec_len, args.CacheFolder);
    MEMC = ProbabilityConstructor_MEMC;
    save(cache_fullname, "MEMC", '-v7.3')
end
end

function cache_fullname = GetCacheFullName(...
    mask, lin_scale, H, start_idx, vec_len, cache_folder)

cache_tag = join(string(mask), "_") +...
    "_" + lin_scale + "_" + H + "_" + start_idx + "_" + vec_len;
cache_filename = "PCC_" + cache_tag + ".mat";
cache_fullname = fullfile(cache_folder, cache_filename);

if ~isfolder(cache_folder)
    mkdir(cache_folder)
end
end

function MEMC = GetMemFun(...
    mask, lin_scale, H, start_idx, vec_len, cache_folder)

cache_fullname = GetCacheFullName(...
    mask, lin_scale, H, start_idx, vec_len, cache_folder);

if isfile(cache_fullname)
    data = load(cache_fullname);
    MEMC = data.MEMC;
else
    MEMC = memoize(@(h, prb, ts)...
        Construct(mask, lin_scale, h, prb, ts, start_idx, vec_len, cache_folder));
    MEMC.CacheSize = 100000000;
end
end

function prob_vec = Construct(...
    mask, lin_scale, H, prob_jump, time_step, start_idx, vec_len, cache_folder)


if time_step == 0
    prob_vec = zeros(vec_len, 1, "like", prob_jump);
    prob_vec(start_idx) = 1;
    return
end

% persistent GMF
% if isempty(GMF)
%     % access cache of cached functions
%     GMF = memoize(@GetMemFun);
%     GMF.CacheSize = 1000;
% end
% 
% MEMC = GMF(mask, lin_scale, H, start_idx, vec_len, cache_folder);
global ProbabilityConstructor_MEMC
prob_vec = ProbabilityConstructor_MEMC(H, prob_jump, time_step - 1);

% P = butdiff.ProbabilityMatrixConstructor(mask, lin_scale, H, prob_jump);
global ProbabilityConstructor_P
prob_vec = ProbabilityConstructor_P * prob_vec;
end


function start_idx = HandleStartIdx(mask, lin_scale, H, prob_jump, start_idx)

P = butdiff.ProbabilityMatrixConstructor(mask, lin_scale, H, prob_jump);

N = size(P, 1);
default_start_idx = floor(N / 2);
if isempty(start_idx)
    start_idx = default_start_idx;
else
    start_idx = start_idx(1);
    if isnan(start_idx)
        start_idx = default_start_idx;
    end
end
end
