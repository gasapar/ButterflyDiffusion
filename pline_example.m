close all
clear variables
clc

N = 100;
x = linspace(0, 5*pi, N);
y = sin(x);

% cubic spline
F = spline(x, y);
% second derivative of spline
ddF = fnder(F, 2);
% roots of second derivative
ddF_root = fnzeros(ddF)';
% roots given as intevals
% use only point roots
ddF_root = ddF_root(ddF_root(:, 1) == ddF_root(:, 2), 1);

%% Plot
figure
hold on
box on
grid on

x_plot = linspace(min(x), max(x), numel(x) * 10);

plot(x, y, ". black",...
    "DisplayName", "Data")
plot(x_plot, ppval(F, x_plot), ": black",...
    "DisplayName", "Spline")

plot(x_plot, ppval(ddF, x_plot), "red",...
    "DisplayName", "Sec. der. spline (SDS)")
plot(ddF_root, zeros(size(ddF_root)), "o blue",...
    "DisplayName", "SDS roots")

xlabel("x")
ylabel("y")
legend("Location", "best")
