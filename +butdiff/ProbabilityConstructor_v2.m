function prob_vec = ProbabilityConstructor_v2(...
    mask, lin_scale, H, prob_jump, time_step, args)

arguments
    mask (1, :) {mustBeNonnegative}
    lin_scale (1, 1) {mustBePositive}
    H (1, 1) {mustBeNonnegative, mustBeInteger}
    prob_jump (1, 1)...
        {mustBePositive, mustBeLessThan(prob_jump, 0.5)}...
        = 1/6
    time_step (1, 1) {mustBePositive, mustBeInteger} = 1000
    args.StartPosition (:, :) double = []
    args.CacheFolder (1, 1) string...
        = butdiff.CacheSetting().ProbabilityConstructorCacheFolder
    args.SaveCache (1, 1) logical = true
end

persistent GCF
if isempty(GCF)
    GCF = memoize(@GetCachedFun);
end


%%

MEMF = GCF(mask, lin_scale, H, prob_jump,...
    args.StartPosition, args.CacheFolder);

cache_size_before = numel(MEMF.stats.Cache.Inputs);
prob_vec = MEMF(time_step);

% check if cache expanded
if cache_size_before < numel(MEMF.stats.Cache.Inputs) && args.SaveCache
    % save cache after expansion
    cache_fullname = GetCacheFullName(...
        mask, lin_scale, H, prob_jump,...
        args.StartPosition, args.CacheFolder);
    save(cache_fullname, "MEMF", '-v7.3')
end
end

function prob_vec = BasicConstructor(...
    mask, lin_scale, H, prob_jump, start_idx, time_step, cache_folder)
%%

% get probability matrix
P = butdiff.ProbabilityMatrixConstructor(...
    mask, lin_scale, H, prob_jump);

persistent GCF
if isempty(GCF)
    GCF = memoize(@GetCachedFun);
end
MEF = GCF(mask, lin_scale, H, prob_jump, start_idx, cache_folder);

prob_vec = [];
if MEF.stats.CacheOccupancyPercent > 0
    % cache exists, start from the latest available value
    cached_time_steps_all = cell2mat([MEF.stats.Cache.Inputs{:}]);
    cached_time_steps_closest =...
        max(cached_time_steps_all(cached_time_steps_all < time_step));
    if ~isempty(cached_time_steps_closest)
        prob_vec = MEF(cached_time_steps_closest);
        time_step = time_step - cached_time_steps_closest;
    end
end

if isempty(prob_vec)
    % get initinal distribution
    prob_vec = zeros(size(P, 1), 1, "like", prob_jump);
    if isempty(start_idx)
        prob_vec(floor(end/2)) = 1;
    else
        prob_vec(start_idx) = 1;
    end
end

for t = 1:time_step
    prob_vec = P * prob_vec;
end
end

function cache_fullname = GetCacheFullName(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder)
%%

if isempty(start_idx)
    start_idx = "";
end

cache_tag = join(string(mask), "_") +...
    "_" + lin_scale +...
    "_" + H +...
    "_inv" + 1/prob_jump +...
    "_" + start_idx;
cache_filename = "PCC_" + cache_tag + ".mat";
cache_fullname = fullfile(cache_folder, cache_filename);

if ~isfolder(cache_folder)
    mkdir(cache_folder)
end
end

function MEMF = GetCachedFun(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder)
%%
cache_fullname = GetCacheFullName(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder);

if isfile(cache_fullname)
    % load cache
    data = load(cache_fullname, "MEMF");
    MEMF = data.MEMF;
else
    % create cache
    MEMF = memoize(@(ts) BasicConstructor(...
        mask, lin_scale, H, prob_jump, start_idx, ts, cache_folder));
    MEMF.CacheSize = 1e9;
end
end

