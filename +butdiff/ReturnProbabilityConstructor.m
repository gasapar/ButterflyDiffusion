function prob_ret = ReturnProbabilityConstructor(...
    mask, lin_scale, H, prob_jump, time_step, args)

arguments
    mask (1, :) {mustBeNonnegative}
    lin_scale (1, 1) {mustBePositive}
    H (:, :) {mustBeNonnegative, mustBeInteger} = []
    prob_jump (1, 1)...
        {mustBePositive, mustBeLessThanOrEqual(prob_jump, 0.5)}...
        = 1/6
    time_step (1, 1) {mustBePositive, mustBeInteger} = 1000
    args.StartPosition (:, :) double = []
    args.CacheFolder (1, 1) string...
        = butdiff.CacheSetting().ReturnProbabilityConstructorCacheFolder
    args.UseGPU (1, 1) logical = ~isempty(gpuDevice)
end

if isempty(H)
    H = ceil(6*log(10)/log(numel(mask)));
end


%%

persistent MEC
if isempty(MEC)
    MEC = memoize(@MainExecutor);
    MEC.CacheSize = 100000;
end

prob_ret = MEC(mask, lin_scale, H, prob_jump, time_step,...
    args.StartPosition, args.CacheFolder, args.UseGPU);
end

%%
function prob_ret = MainExecutor(...
    mask, lin_scale, H, prob_jump, time_step,...
    start_idx, cache_folder, use_gpu)

[prob_ret, prob_vec, last_time_step] = GetCachedValues(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder);

% number of new steps to make
needed_time_step = time_step - last_time_step;

if needed_time_step > 0
    % new steps must be done
    [prob_ret_new, prob_vec] = IncrementalExpander(...
        mask, lin_scale, H, prob_jump,...
        start_idx, needed_time_step, prob_vec, use_gpu);
    % expand array of return probs.
    prob_ret = [prob_ret; prob_ret_new];
    % save new expansion
    SaveValues(prob_ret, prob_vec,...
        mask, lin_scale, H, prob_jump, start_idx, cache_folder);
else
    % cache contained everything
    prob_ret = prob_ret(1:time_step);
end
end

%%
function cache_fullname = GetCacheFullName(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder)

if isempty(start_idx)
    start_idx = "";
end

cache_tag = join(string(mask), "_") +...
    "_" + lin_scale +...
    "_" + H +...
    "_inv" + 1/prob_jump +...
    "_" + start_idx;
cache_filename = "RPCC_" + cache_tag + ".mat";
cache_fullname = fullfile(cache_folder, cache_filename);

if ~isfolder(cache_folder)
    mkdir(cache_folder)
end
end

%%
function [prob_ret, prob_vec, last_time_step] =...
    GetCachedValues(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder)

cache_fullname = GetCacheFullName(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder);
if isfile(cache_fullname)
    % load saved file
    data = load(cache_fullname);
    prob_ret = data.prob_ret;
    prob_vec = data.prob_vec;
    last_time_step = numel(prob_ret);
else
    % create first step state
    [prob_ret, prob_vec] = StepOneState(...
        mask, lin_scale, H, prob_jump, start_idx);
    last_time_step = 1;
end
end

%%
function SaveValues(prob_ret, prob_vec,...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder)

cache_fullname = GetCacheFullName(...
    mask, lin_scale, H, prob_jump, start_idx, cache_folder);

% check folder existance
if ~isfolder(cache_folder)
    mkdir(cache_folder)
end

% save
save(cache_fullname, "prob_ret", "prob_vec", "-v7.3")
end

%%
function [prob_ret, prob_vec] = IncrementalExpander(...
    mask, lin_scale, H, prob_jump,...
    start_idx, time_step_count, prob_vec, use_gpu)

if isempty(start_idx)
    start_idx = floor(numel(prob_vec)/2);
end

% get probability matrix
P = butdiff.ProbabilityMatrixConstructor(...
    mask, lin_scale, H, prob_jump);

% create array for return probs. to be created
prob_ret = zeros(time_step_count, 1, "like", prob_jump);

% turn to GPU if requested
if use_gpu
    P = gpuArray(P);
    prob_ret = gpuArray(prob_ret);
    prob_vec = gpuArray(prob_vec);
end

% time evolutions
for idx = 1:time_step_count
    prob_vec = P * prob_vec;
    prob_ret(idx) = prob_vec(start_idx);
end

% gather data from GPU
if use_gpu
    prob_vec = gather(prob_vec);
    prob_ret = gather(prob_ret);
end
end

%%
function [prob_ret, prob_vec] = StepOneState(...
    mask, lin_scale, H, prob_jump, start_idx)

% get probability matrix
P = butdiff.ProbabilityMatrixConstructor(...
    mask, lin_scale, H, prob_jump);

if isempty(start_idx)
    start_idx = floor(size(P, 1)/2);
end

% initial distribution
prob_vec = zeros(size(P, 1), 1, "like", prob_jump);
prob_vec(start_idx) = 1;

% first step
prob_vec = P * prob_vec;
prob_ret = prob_vec(start_idx);
end