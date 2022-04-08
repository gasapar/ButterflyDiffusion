function data = DataSetFullCalculations(data, args)

arguments
    data (1, 1) struct
    args.SplineMethod (1, 1) function_handle = @spline
    args.SubSampleLimit (1, 1) {mustBePositive, mustBeInteger} = 1e4
end


%% Set Data and Interpolants

data.log.t = log(data.raw.t);
data.log.p_ret = log(data.raw.p_ret);

data.xlog.t = data.log.t;
data.xlog.p_ret = data.raw.p_ret;

data.raw = AddAllSplines(data.raw, args);
data.log =  AddAllSplines(data.log, args);
data.xlog = AddAllSplines(data.xlog, args);


%% Resample data
% Resample data to be unifort in log scale and recreate splines based on the
% resampled data.

data.uni.log.t = linspace(...
    min(data.log.t), max(data.log.t),...
    min(numel(data.log.t), args.SubSampleLimit));

data.uni.raw.t = exp(data.uni.log.t);
data.uni.xlog.t = data.uni.log.t;

data.uni.log.p_ret = ppval(data.log.d0.spline, data.uni.log.t);
data.uni.raw.p_ret = ppval(data.raw.d0.spline, data.uni.raw.t);
data.uni.xlog.p_ret = ppval(data.xlog.d0.spline, data.uni.xlog.t);

data.uni.raw = AddAllSplines(data.uni.raw, args);
data.uni.log = AddAllSplines(data.uni.log, args);
data.uni.xlog = AddAllSplines(data.uni.xlog, args);

data.uni.raw = EvalAllSplines(data.uni.raw);
data.uni.log = EvalAllSplines(data.uni.log);
data.uni.raw = EvalAllSplines(data.uni.raw);


%% Roots

data.uni.log = CalculateRoots(data.uni.log);
data.uni.raw = CalculateRoots(data.uni.raw);
data.uni.xlog = CalculateRoots(data.uni.xlog);


%% Ploting data

data.uni.log = EvalAllSplinesPlot(data.uni.log);
data.uni.raw = EvalAllSplinesPlot(data.uni.raw);
data.uni.xlog = EvalAllSplinesPlot(data.uni.xlog);
end

function dat = AddAllSplines(dat, args)

dat.d0.spline = args.SplineMethod(dat.t, dat.p_ret);
dat.d1.spline = fnder(dat.d0.spline, 1);
dat.d2.spline = fnder(dat.d0.spline, 2);
end

function dat = EvalAllSplines(dat)

dat.d0.p_ret = ppval(dat.d0.spline, dat.t);
dat.d1.p_ret = ppval(dat.d1.spline, dat.t);
dat.d2.p_ret = ppval(dat.d2.spline, dat.t);
end

function dat = EvalAllSplinesPlot(dat)

dat.t_plot = linspace(...
    min(dat.t), max(dat.t), numel(dat.t) * 10);

dat.d0.p_ret_plot = ppval(dat.d0.spline, dat.t_plot);
dat.d1.p_ret_plot = ppval(dat.d1.spline, dat.t_plot);
dat.d2.p_ret_plot = ppval(dat.d2.spline, dat.t_plot);
end


function dat = CalculateRoots(dat)

dat.d0.root = mean(fnzeros(dat.d0.spline));
dat.d1.root = mean(fnzeros(dat.d1.spline));
dat.d2.root = mean(fnzeros(dat.d2.spline));
end
