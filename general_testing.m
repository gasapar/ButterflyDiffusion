close all
clear variables global
clc
clearAllMemoizedCaches

mask = [0, 2];
lin_scale = 3;
prob_jump = 1/6;
H = 6;


digs = 10;

%%

P = butdiff.ProbabilityMatrixConstructor(...
    mask, lin_scale, H, prob_jump);
P = vpa(P, digs);

max_time = size(P, 1)-1;

prob_ret = butdiff.ReturnProbabilityConstructor(...
    mask, lin_scale, H, prob_jump, max_time);

prob_ret = vpa([1; prob_ret], digs);

%%

lambda_all = eig(P);

%%

figure
hold on

for idx = 1:10
    plot(lambda_all .^ idx, ".", ...
        "DisplayName", string(idx))
end

legend("Location", "best")

xlabel("$\lambda$  index")
ylabel("Powers of $\lambda$")

set(gca, 'YScale', 'log')

pkg.FigureSetup()


figure
plot(diff(lambda_all), ". blue")

xlabel("$\lambda$  index")
ylabel("$\Delta\lambda$")


set(gca, 'YScale', 'log')

pkg.FigureSetup()


%%
t = 0:max_time;

L = (lambda_all(:).') .^ t(:);

c_all = L \ prob_ret;


disp(c_all)
close all
sum(c_all)
%% Functions


function P = SymMatrix(F, p_jump)

p_jump = sym(p_jump);
F = sym(diff(F));

prob_jump_dist = p_jump ./ F;

vertex_num = numel(prob_jump_dist) + 1;

probab_stay_dist = [1, 1 - prob_jump_dist] - [prob_jump_dist, 0];


P = sym(zeros(vertex_num));

idx = full(gallery("tridiag", vertex_num, 1, 2, 3));
P(idx == 2) = probab_stay_dist;
P(idx == 1) = prob_jump_dist;
P(idx == 3) = prob_jump_dist;
end



