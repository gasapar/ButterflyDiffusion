close all
clear variables global
clc
%clearAllMemoizedCaches


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
all_time_step = 1e4:1e4:1e6;


%%

for mask_idx = 1:numel(all_mask)
    mask = all_mask{mask_idx};
    
    MassiveGenerator(mask, lin_scale,...
        H, all_prob_jump, all_time_step)
end
