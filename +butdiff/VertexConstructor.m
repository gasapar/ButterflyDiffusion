function X = VertexConstructor(mask, lin_scale, H, args)

arguments
    mask (1, :) {mustBeNonnegative}
    lin_scale (1, 1) {mustBePositive}
    H (1, 1) {mustBeNonnegative, mustBeInteger}
    args.CacheFolder (1, 1) string...
        = butdiff.CacheSetting().VertexConstructorCacheFolder
end

if H == 1
    X = unique(mask);
    return
end

persistent GMF
if isempty(GMF)
    % access cache of cached functions
    GMF = memoize(@GetMemFun);
    GMF.CacheSize = 1000;
end

% get cached function
MEMC = GMF(mask, lin_scale, args.CacheFolder);

cache_size_before = numel(MEMC.stats.Cache.Inputs);
% call cached function
X = MEMC(H);

% check if cache expanded
if cache_size_before < numel(MEMC.stats.Cache.Inputs)
    % save cache after expansion
    cache_fullname = GetCacheFullName(mask, lin_scale, args.CacheFolder);
    save(cache_fullname, "MEMC", '-v7.3')
end
end

function MEMC = GetMemFun(mask, lin_scale, cache_folder)

cache_fullname = GetCacheFullName(mask, lin_scale, cache_folder);

if isfile(cache_fullname)
    data = load(cache_fullname);
    MEMC = data.MEMC;
else
    MEMC = memoize(@(h) Construct(mask, lin_scale, h, cache_folder));
    MEMC.CacheSize = 10000;
end
end

function cache_fullname = GetCacheFullName(mask, lin_scale, cache_folder)

cache_tag = join(string(mask), "_") + "_" + lin_scale;
cache_filename = "VCC_" + cache_tag + ".mat";
cache_fullname = fullfile(cache_folder, cache_filename);

if ~isfolder(cache_folder)
    mkdir(cache_folder)
end
end

function X = Construct(mask, lin_scale, H, cache_folder)

if H == 1 
    X = unique(mask);
    return
end

persistent GMF
if isempty(GMF)
    % access cache of cached functions
    GMF = memoize(@GetMemFun);
    GMF.CacheSize = 1000;
end

MEMC = GMF(mask, lin_scale, cache_folder);

X = MEMC(H - 1);

X =  mask.' + lin_scale * X(:).';
X = unique(X(:).');
end
