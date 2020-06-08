%% Add data
clear;
clc;

data = 'dyntex';

if strcmp(data, 'ucla')
    dataset = 'ucla/';
    Nvideos = 200;
    dims = 3:30;
elseif strcmp(data, 'ucsd') 
    dataset = 'ucsd/';
    Nvideos = 254;
    dims = 3:30;
elseif strcmp(data, 'dyntex')
    dataset = 'dyntex/';
    dims = 3:30;
    Nvideos = 99;
end

addpath(dataset);

N_dims = length(dims);

% Initialize variables to store metrics
num_BestScores_per_dim = struct('SUB', nan(N_dims,1), 'CG', nan(N_dims,1), 'WLS', nan(N_dims,1));
num_Failures_per_dim = struct('SUB', nan(N_dims,1), 'CG', nan(N_dims,1), 'WLS', nan(N_dims,1));
avg_PercentErrorIncrease_per_dim = struct('SUB', nan(N_dims,1), 'CG', nan(N_dims,1), 'WLS', nan(N_dims,1));
avg_Time_per_dim = struct('SUB', nan(N_dims,1), 'CG', nan(N_dims,1), 'WLS', nan(N_dims,1));

precision_decimal_digits = 10;
better_equal = 1;
for i = 1 : N_dims
    indx = dims(i);
    filename = [dataset, 'Errors_and_Times_dim_', num2str(indx), '.mat'];
    load(filename);
    
    SUB.error = round(SUB.error, precision_decimal_digits);
    WLS.error = round(WLS.error, precision_decimal_digits);
    CG.error = round(CG.error, precision_decimal_digits);

    % Replace NaN with Inf when comparing for better error
    nanIndeces_SUB = find(isnan(SUB.error));
    nanIndeces_CG = find(isnan(CG.error));
    nanIndeces_WLS = find(isnan(WLS.error));
    
    nanIndeces = union(union(nanIndeces_SUB, nanIndeces_CG), nanIndeces_WLS);
    SUB.error(nanIndeces) = [];
    CG.error(nanIndeces) = [];
    WLS.error(nanIndeces) = [];
    LS.error(nanIndeces) = [];
    
    % replace NaN with Inf and later remove
    if better_equal
            num_BestScores_per_dim.SUB(i) = sum((SUB.error <= WLS.error) .* (SUB.error <= CG.error));
            num_BestScores_per_dim.CG(i) = sum((CG.error <= WLS.error) .* (CG.error <= SUB.error));
            num_BestScores_per_dim.WLS(i) = sum((WLS.error <= SUB.error) .* (WLS.error <= CG.error));
    else  
            num_BestScores_per_dim.SUB(i) = sum((SUB.error < WLS.error) .* (SUB.error < CG.error));
            num_BestScores_per_dim.CG(i) = sum((CG.error < WLS.error) .* (CG.error < SUB.error));
            num_BestScores_per_dim.WLS(i) = sum((WLS.error < SUB.error) .* (WLS.error < CG.error));
    end

    num_Failures_per_dim.SUB(i) = sum(isinf(SUB.error));
    num_Failures_per_dim.CG(i) = sum(isinf(CG.error));
    num_Failures_per_dim.WLS(i) = sum(isinf(WLS.error));
             
    median_PercentErrorIncrease_per_dim.SUB(i) = 100*mean((SUB.error-LS.error) ./ LS.error);
    median_PercentErrorIncrease_per_dim.CG(i) = 100*mean((CG.error-LS.error) ./ LS.error);
    median_PercentErrorIncrease_per_dim.WLS(i) = 100*mean((WLS.error-LS.error) ./ LS.error);

    avg_Time_per_dim.SUB(i) = mean(SUB.time);
    avg_Time_per_dim.CG(i) = mean(CG.time);
    avg_Time_per_dim.WLS(i) = mean(WLS.time);
    
end

%% Normalize number of Best Scores
num_BestScores_per_dim.SUB = num_BestScores_per_dim.SUB / Nvideos * 100;
num_BestScores_per_dim.CG = num_BestScores_per_dim.CG / Nvideos *100;
num_BestScores_per_dim.WLS = num_BestScores_per_dim.WLS / Nvideos *100;

num_Failures_per_dim.SUB = num_Failures_per_dim.SUB / Nvideos * 100;
num_Failures_per_dim.CG = num_Failures_per_dim.CG / Nvideos *100;
num_Failures_per_dim.WLS = num_Failures_per_dim.WLS / Nvideos *100;
%% Plots
close all;

figure();
% subplot(1,4,1);
plot(dims, num_BestScores_per_dim.CG, ':o'); hold on;
plot(dims, num_BestScores_per_dim.WLS, '--*'); hold on;
plot(dims, num_BestScores_per_dim.SUB, '-s'); hold on;
legend('CG', 'WLS', 'SOC');
%  title('Success Rate'); 

% change linewidth
linewidth_d = 1.5;
lines = findobj(gcf,'Type','Line');
for i = 1:numel(lines)
  lines(i).LineWidth = linewidth_d;
end
set(gcf, 'color', 'w')
set(gca,'FontSize',14)
xlabel('dimension r', 'fontsize', 18);
 ylabel('best error frequency (%)', 'fontsize', 18);
grid on

figure();
semilogy(dims, median_PercentErrorIncrease_per_dim.CG, ':o'); hold on;
semilogy(dims, median_PercentErrorIncrease_per_dim.WLS, '--*'); hold on;
semilogy(dims, median_PercentErrorIncrease_per_dim.SUB, '-s'); hold on;

linewidth_d = 1.5;
lines = findobj(gcf,'Type','Line');
for i = 1:numel(lines)
  lines(i).LineWidth = linewidth_d;
end
set(gcf, 'color', 'w')
set(gca,'FontSize',14)
xlabel('dimension r', 'fontsize', 18);
ylabel('average error (%)', 'fontsize', 18);
grid on

%
figure();
semilogy(dims, avg_Time_per_dim.CG, ':o'); hold on;
semilogy(dims, avg_Time_per_dim.WLS, '--*'); hold on;
semilogy(dims, avg_Time_per_dim.SUB, '-s' ); hold on;

% 
linewidth_d = 1.5;
lines = findobj(gcf,'Type','Line');
for i = 1:numel(lines)
  lines(i).LineWidth = linewidth_d;
end
set(gcf, 'color', 'w')
set(gca,'FontSize',14)
f = gca; 
xlabel('dimension r', 'fontsize', 18);
ylabel('average time (s)', 'fontsize', 18);
grid on
