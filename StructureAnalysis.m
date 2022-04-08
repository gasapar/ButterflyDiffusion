function result = StructureAnalysis(mask, lin_scale, H, prob_jump, args)

arguments
    mask (1, :)
    lin_scale (1, 1)
    H = ceil(6*log(10)/log(numel(mask)))
    prob_jump (1, 1) = 1/6
    args.MaxTime = 1e6
    args.SplineMethod = @spline
    args.SubSampleLimit = 1e4
    args.ThresholdMethod = "SecondMinimum"
end

if isempty(H)
    H = ceil(6*log(10)/log(numel(mask)));
end

%% Log Transform

p_ret = butdiff.ReturnProbabilityConstructor(...
    mask, lin_scale, H, prob_jump, args.MaxTime);

t = 1:numel(p_ret);

x = log(t);
y = log(p_ret);


%% Resample

ux = linspace(min(x), max(x), min(numel(x), args.SubSampleLimit));

F = args.SplineMethod(x, y);
uy = ppval(F, ux);


%% Inflection Points

uF = args.SplineMethod(ux, uy);

dduF = fnder(uF, 2);

inflection_points = mean(fnzeros(dduF));
f_inflection_points = ppval(F, inflection_points);


%% Calculate Reziduals

% linear regresion
mdl = fitlm(inflection_points, f_inflection_points);
y2 = y - reshape(mdl.feval(x), size(y));


%% Get descriptive points

F2 = args.SplineMethod(x, y2);
uy2 = ppval(F2, ux);

uF2 = args.SplineMethod(ux, uy2);

duF2 = fnder(uF2);
dduF2 = fnder(uF2, 2);

potentional_extremes = mean(fnzeros(duF2));
dduF2_potentional_extremes = ppval(dduF2, potentional_extremes);

is_local_max = dduF2_potentional_extremes < 0;
is_local_min = dduF2_potentional_extremes > 0;

max_x = sort(potentional_extremes(is_local_max));
min_x = sort(potentional_extremes(is_local_min));


%% Get Threshold

switch args.ThresholdMethod
    case "FirstMinimum"
        threshold = min_x(1);
    case "SecondMinimum"
        threshold = min_x(2);
    case "FirstMaximum"
        threshold = max_x(1);
    case "SecondMaximum"
        threshold = max_x(2);
    otherwise
        error("Unknown threshold method.")
end


%% New Linear Model

is_thesholded = inflection_points > threshold;

inflection_points = inflection_points(is_thesholded);
f_inflection_points = f_inflection_points(is_thesholded);

reg_sample_size = numel(inflection_points);
mdl = fitlm(inflection_points, f_inflection_points);
y2 = y - reshape(mdl.feval(x), size(y));


%% Get Descriptive Points

F2 = args.SplineMethod(x, y2);
uy2 = ppval(F2, ux);

uF2 = args.SplineMethod(ux, uy2);

duF2 = fnder(uF2);
dduF2 = fnder(uF2, 2);

potentional_extremes = mean(fnzeros(duF2));
dduF2_potentional_extremes = ppval(dduF2, potentional_extremes);

is_local_max = dduF2_potentional_extremes < 0;
is_local_min = dduF2_potentional_extremes > 0;

result.max.x = sort(potentional_extremes(is_local_max));
result.min.x = sort(potentional_extremes(is_local_min));

result.max.y = ppval(F2, result.max.x);
result.min.y = ppval(F2, result.min.x);

result.infl.x = mean(fnzeros(dduF2));
result.infl.y = ppval(F2, result.infl.x);


%% Get New Threshold

switch args.ThresholdMethod
    case "FirstMinimum"
        threshold = result.min.x(1);
    case "SecondMinimum"
        threshold = result.min.x(2);
    case "FirstMaximum"
        threshold = result.max.x(1);
    case "SecondMaximum"
        threshold = result.max.x(2);
    otherwise
        error("Unknown threshold method.")
end


%% Fourier Analysis

is_thesholded = ux > threshold;
[f, P] = FourierDecomposition(...
    ux(is_thesholded), uy2(is_thesholded));
[result.four.P_max, max_idx] = max(P);
result.four.f_max = f(max_idx);


%% Set Data to Return


result.threshold = threshold;
result.threshold_method = args.ThresholdMethod;

result.mask = mask;
result.lin_scale = lin_scale;
result.prob_jump = prob_jump;
result.H = H;
result.t_max = args.MaxTime;

result.raw.x = x;
result.raw.y = y;
result.raw.y2 = y2;

result.uni.x = ux;
result.uni.y = uy;
result.uni.y2 = uy2;

result.reg_sample_size = reg_sample_size;

result.df = log(numel(mask))/log(lin_scale);

par2 = mdl.Coefficients.Estimate(2);
std_par2 = mdl.Coefficients.SE(2);
var_par2 = std_par2 ^ 2;

result.df_est = - par2 / (par2 + 1);

var_df_est = (1 ./ (par2 + 1)^4)  * var_par2;
result.df_est_std = sqrt(var_df_est);


end