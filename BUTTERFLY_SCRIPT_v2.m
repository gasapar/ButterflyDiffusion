%BUTTERFLY_SCRIPT

close all
clear variables
clc


%% Parameters

spline_method = @spline;
resampled_size_limit = 1e4;

N = 3;
mask = [0, 2];

H = 20;

pjump = 1/6;
nmax = 1e5;

start_idx = 1;

% approx. of limit distribution of defined finite structure
lim_pret = numel(mask)^-H;

% dimension of defined set
DH = log(numel(mask)) / log(N);


%% Run code

t_small = tic;
p_ret = butdiff.ReturnProbabilityConstructor(...
    mask, N, H, pjump, nmax, "StartPosition", start_idx);
disp("Computation time: " + toc(t_small) + " s")


%% Set Data and Interpolants

data.raw.t = 1:nmax;
data.raw.p_ret = p_ret(:).';

data = DataSetFullCalculations(data,...
    "SplineMethod", spline_method,...
    "SubSampleLimit", resampled_size_limit);


%% Plot Probabilities

figure
hold on

plot(data.raw.t, data.raw.p_ret, '. black',...
    "DisplayName", "$\Pr(X_t=x_0| X_0=x_0)$")

yline(lim_pret, 'red',...
    "DisplayName", "$\lim_{t\to\infty}\Pr(X_t=x_0| X_0=x_0)$")

xline(1/lim_pret, "blue",...
    "DisplayName", "Border Interference Limit")

xlabel("$t$")
ylabel("Return Probability")
legend("Location", "best")

ylim([lim_pret/5, +inf])
xlim([0, max(data.raw.t)])

set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')


pkg.FigureSetup()
snapnow


%% Plot Resample Illustration

figure
hold on

plot(data.uni.raw.t, data.uni.raw.p_ret, "o green",...
    "DisplayName", "LogU Data")
plot(data.raw.t, data.raw.p_ret, ". black",...
    "DisplayName", "Raw Data")

title("Logarithmicaly Uniform Resampling")
xlabel("$t$")
ylabel("Probability")

legend("Location", "best")

set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')

pkg.FigureSetup()
snapnow


%% Plot Inflection Points

figure
hold on

plot(data.uni.log.t, data.uni.log.d2.p_ret, '. black',...
    "DisplayName", "Second Derivative")

plot(data.uni.log.t_plot, data.uni.log.d2.p_ret_plot, "yellow",...
    "DisplayName", "Second Derivative Spline")

plot(data.uni.log.d2.root, zeros(size(data.uni.log.d2.root)), "o magenta",...
    "DisplayName", "Spline Root")

xline(1/lim_pret, "blue",...
    "DisplayName", "Border Interference Limit")

xlim([0, max(data.uni.log.t)])
xlabel('$\log(t)$')

legend("Location", "best")

pkg.FigureSetup()
snapnow


%% Dimension estimation

% main spline to use for log data interpolation
used_spline = data.uni.log.d0.spline;

% inflection points as roots of second derivative
x_vals = data.uni.log.d2.root(1:end);

% return log probability in root points
y_vals = ppval(used_spline, x_vals);

% linear regresion
mdl = fitlm(x_vals, y_vals);

% second parameter is: -df/(df+1)
par2 = mdl.Coefficients.Estimate(2);
std_par2 = mdl.Coefficients.SE(2);
var_par2 = std_par2 ^ 2;

df_est = - par2 / (par2 + 1);

var_df_est = (1 ./ (par2 + 1)^4)  * var_par2;
std_df_est = sqrt(var_df_est);


%% Plot Regression Result 

figure
hold on

plot(data.uni.log.d2.root, ppval(used_spline, data.uni.log.d2.root),...
    "o magenta",...
    "DisplayName", "Inflection Points")


plot(x_vals, y_vals, "p magenta",...
    "DisplayName", "Regresion Points")

plot(xlim, mdl.feval(xlim), "green",...
    "DisplayName", "Linear Model: $R^2 = " + mdl.Rsquared.Ordinary +"$")

% plot(nan, nan, "white",...
%     "DisplayName",...
%     "$\widehat{\beta} = " + par2 +...
%     ",\quad\mathrm{std}\,\widehat{\beta} = " + std_par2 + " $")

plot(nan, nan, "white",...
    "DisplayName",...
    "$\widehat{d_{\mathrm{f}}} = " + df_est +...
    ",\,\,\mathrm{std}\,\widehat{d_{\mathrm{f}}} = " + std_df_est + " $")

plot(nan, nan, "white",...
    "DisplayName",...
    "$d_{\mathrm{f}} = "+ DH +" $")

xlabel("$\log(t)$")
ylabel("Log Return Probability")

legend("Location", "northeast")

pkg.FigureSetup()
snapnow


%% Linearize Data

ldata.raw.t = data.raw.t;
ldata.raw.p_ret = exp(data.log.p_ret - mdl.feval(data.log.t));


ldata = DataSetFullCalculations(ldata,...
    "SplineMethod", spline_method,...
    "SubSampleLimit", resampled_size_limit);


%% Minima, Maxima and Inflection Points of Linearized Data

figure
hold on

plot(ldata.xlog.t, ldata.xlog.p_ret, ". black",...
    "DisplayName", "Lin. Model Residuals")

plot(...
    ldata.uni.xlog.d2.root,...
    ppval(ldata.xlog.d0.spline, ldata.uni.xlog.d2.root), "o magenta",...
    "DisplayName", "Inflection Points")

extremes_x = ldata.uni.xlog.d1.root;
extremes_d0 = ppval(ldata.xlog.d0.spline, extremes_x);
extremes_d2 = ppval(ldata.xlog.d2.spline, extremes_x);

is_min = extremes_d2 > 0;
is_max = extremes_d2 < 0;

% use second minimum
model_threshold = sort(extremes_x(is_min));
model_threshold = model_threshold(2);

plot(extremes_x(is_max), extremes_d0(is_max), "^ green",...
    "DisplayName", "Local Maxima")
plot(extremes_x(is_min), extremes_d0(is_min), "v green",...
    "DisplayName", "Local Minima")

xlabel("$\log(t)$")
legend("Location", "best")

pkg.FigureSetup()
snapnow


%% Use Threshold

use_in_model = data.uni.log.d2.root > model_threshold;

% inflection points as roots of second derivative
x_vals = data.uni.log.d2.root(use_in_model);

% return probability in root points
y_vals = ppval(used_spline, x_vals);

% linear regresion
mdl = fitlm(x_vals, y_vals);

% second parameter is: -df/(df+1)
par2 = mdl.Coefficients.Estimate(2);
std_par2 = mdl.Coefficients.SE(2);
var_par2 = std_par2 ^ 2;

df_est = - par2 / (par2 + 1);

var_df_est = (1 ./ (par2 + 1)^4)  * var_par2;
std_df_est = sqrt(var_df_est);


%% Plot Regression Result With Threshold

figure
hold on

plot(data.uni.log.d2.root, ppval(used_spline, data.uni.log.d2.root),...
    "o magenta",...
    "DisplayName", "Inflection Points")

plot(x_vals, y_vals, "p magenta",...
    "DisplayName", "Regresion Points")

plot(xlim, mdl.feval(xlim), "green",...
    "DisplayName", "Linear Model: $R^2 = " + mdl.Rsquared.Ordinary +"$")

xline(model_threshold, "blue",...
    "DisplayName", "Threshold Location")

plot(nan, nan, "white",...
    "DisplayName",...
    "$\widehat{d_{\mathrm{f}}} = " + df_est +...
    ",\,\,\mathrm{std}\,\widehat{d_{\mathrm{f}}} = " + std_df_est + " $")

plot(nan, nan, "white",...
    "DisplayName",...
    "$d_{\mathrm{f}} = " + DH + " $")

xlabel("$\log(t)$")
ylabel("Log Return Probability")

legend("Location", "northeast")

pkg.FigureSetup()
snapnow


%% Redo Linearization

clear ldata

ldata.raw.t = data.raw.t;
ldata.raw.p_ret = exp(data.log.p_ret - mdl.feval(data.log.t));

ldata = DataSetFullCalculations(ldata,...
    "SplineMethod", spline_method,...
    "SubSampleLimit", resampled_size_limit);


%% Minima, Maxima and Inflection Points of Linearized Data with Threshold

figure
hold on

plot(ldata.xlog.t, ldata.xlog.p_ret, ". black",...
    "DisplayName", "Lin. Model Residuals")

plot(...
    ldata.uni.xlog.d2.root,...
    ppval(ldata.xlog.d0.spline, ldata.uni.xlog.d2.root), "o magenta",...
    "DisplayName", "Inflection Points")

extremes_x = ldata.uni.xlog.d1.root;
extremes_d0 = ppval(ldata.xlog.d0.spline, extremes_x);
extremes_d2 = ppval(ldata.xlog.d2.spline, extremes_x);

is_min = extremes_d2 > 0;
is_max = extremes_d2 < 0;

model_threshold = sort(extremes_x(is_min));
model_threshold = model_threshold(2);

plot(extremes_x(is_max), extremes_d0(is_max), "^ green",...
    "DisplayName", "Local Maxima")
plot(extremes_x(is_min), extremes_d0(is_min), "v green",...
    "DisplayName", "Local Minima")

xlabel("$\log(t)$")
legend("Location", "best")

pkg.FigureSetup()
snapnow


%% Wave fitting


sin_data_idx = model_threshold < ldata.uni.xlog.t;

x_data = ldata.uni.xlog.t(sin_data_idx);
y_data = ldata.uni.xlog.p_ret(sin_data_idx);

[f, P] = FourierDecomposition(x_data, y_data);


%%

figure
plot(x_data, y_data, ". black")


xlabel("$\log(t)$")
pkg.FigureSetup()


%%

figure
plot(f, P, ":. red",...
    "DisplayName", "Residuals")

xlabel("$f$")



set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')
pkg.FigureSetup()




%%

[max_val, max_idx] = max(P);



%%


cftool(x_data, y_data)
