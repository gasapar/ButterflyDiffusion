close all
clear variables global
clc
% clearAllMemoizedCaches

mask = [0, 2, 5];
lin_scale = 5;
prob_jump = 1/6;
H = [];

result = StructureAnalysis(mask, lin_scale, H, prob_jump,...
    "MaxTime", 1e5);


%%

figure
hold on

plot(result.uni.x, result.uni.y2, ". black",...
    "DisplayName", "Residuas")

xline(result.threshold, "blue",...
    "DisplayName", result.threshold_method)


plot(result.max.x, result.max.y, "^ green",...
    "DisplayName", "Maxima")
plot(result.min.x, result.min.y, "v green",...
    "DisplayName", "Minima")

plot(result.infl.x, result.infl.y, "o magenta",...
    "DisplayName", "Inflection Points")


xlabel("$\log(t)$")

legend("Location", "best")



pkg.FigureSetup()