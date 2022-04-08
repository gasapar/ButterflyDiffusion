close all
clear variables global
clc
%clearAllMemoizedCaches


%% Parameters

pars.UseGPU = false;
pars.Verbosity = true;


%% Structure parameters

all_mask = {[0, 1], [0, 2]};

lin_scale = 3;


H = [];
start_idx = 1;


%% Execution parameters

all_prob_jump = unique([...
    0.5, 1/6, 0.01, 1/4, 1/3,...
    0.05:0.05:0.5,...
    ]);
all_time_step = 1e3:1e3:3e4;


%%

for mask_idx = 1:numel(all_mask)
    mask = all_mask{mask_idx};
    
    MassiveGenerator(mask, lin_scale,...
        H, all_prob_jump, all_time_step,...
        "StartPosition", start_idx,...
        "UseGPU", pars.UseGPU,...
        "Verbosity", pars.Verbosity);
end
