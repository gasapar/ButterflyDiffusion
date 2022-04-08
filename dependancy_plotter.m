close all
clear variables
clc


mask = [0, 2, 6];
lin_scale = 5;

prob_jump_all = unique([...
    0.01, 0.5, 1/6, 0.25, 1/4, 1/3,...
    0.05:0.05:0.5,...
    ]);


[f_all, P_all, N_all, T_all] =...
    GetFourStats(mask, lin_scale, prob_jump_all);



%% Figure


structure_label = "mask_" + join(string(mask), "-") + "_" + lin_scale;

figure("Name", "Dependancy_plot_" + structure_label)
tiledlayout("flow", "Padding", "tight")
nexttile

plot(prob_jump_all, 2*pi./f_all, "x: red")
xlabel("Jump Probability")
ylabel("Period")

title("mask: $[" + join(string(mask), ", ") + "]$, $N = " + lin_scale + "$",...
    "FontWeight", "normal")
nexttile

plot(prob_jump_all, P_all, "x: red")
xlabel("Jump Probability")
ylabel("Aplitude")


nexttile

plot(prob_jump_all, T_all, "x: red")
xlabel("Jump Probability")
ylabel("Threshold")


nexttile

plot(prob_jump_all, N_all, "x: red")
xlabel("Jump Probability")
ylabel("Regresion Poins Number")






pkg.FigureSetup("Size", [14, 24])
pkg.Fig2Pdf()

%% Functions


function [f_all, P_all, N_all, T_all] = GetFourStats(...
    mask, lin_scale, prob_jump_all)


f_all = nan(size(prob_jump_all));
P_all = f_all;
N_all = f_all;
T_all = f_all;

for idx = 1:numel(prob_jump_all)
    result = StructureAnalysis(mask, lin_scale, [],...
        prob_jump_all(idx), "MaxTime", 1e5,...
        "ThresholdMethod", "FirstMinimum");
    
    f_all(idx) = result.four.f_max;
    P_all(idx) = result.four.P_max;
    N_all(idx) = result.reg_sample_size;
    T_all(idx) = result.threshold;
end
end