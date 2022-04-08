function probab_ret_vec = DistributionEvolver(...
    vertexes,...
    probab_jump,...
    t_max,...
    args)

arguments
    vertexes (1, :) {mustBeNumeric}
    probab_jump (1, 1) {mustBePositive} = 1/6
    t_max (1, 1) {mustBeInteger} = 1e3
    args.StepSize (1, 1) {mustBeInteger} = 1
end

vertex_num = numel(vertexes);

probab_jump_dist = probab_jump ./ diff(vertexes);


%% Contruct transition matrix

probab_stay_dist =...
    [1, 1 - probab_jump_dist] -...
    [probab_jump_dist, 0];

% sparse transition matrix
P = sparse(...
    [1:vertex_num, 2:vertex_num, 1:vertex_num-1],...
    [1:vertex_num, 1:vertex_num-1, 2:vertex_num],...
    [probab_stay_dist, probab_jump_dist, probab_jump_dist]);


%% Time evolution

% create step matrix based on stepsize
P_step = P;
for idx_step = 2:args.StepSize
    P_step = P * P_step;
end
% number of steps
t_max_steps = floor(t_max / args.StepSize);


% vector of probabilities
probab_vec = zeros(vertex_num, 1, 'like', probab_jump);
% initial position in the middle
idx_init = floor(vertex_num/2);
probab_vec(idx_init) = 1;

% vector of return probabilities evolution
probab_ret_vec = zeros(1, t_max_steps, 'like', probab_jump);


for idx_step = 1:t_max_steps
    probab_vec = P_step * probab_vec;
    probab_ret_vec(idx_step) = probab_vec(idx_init);
end
end
