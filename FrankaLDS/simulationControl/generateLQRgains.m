clear; clc; close all;

path_to_data = 'results/'; % LDS models     
% Load all files
Sampling = 'random'; % 'random' or 'serial'

switch Sampling
    case 'random'
        filePrefix = 'Randomized';
    case 'serial'
        filePrefix = 'Serial';
    otherwise
        fprintf('Choose either /"random" or "serial" for Sampling \n');
end
algorithms = {'LS', 'CG', 'SUB', 'WLS'};
for i = 1 : length(algorithms)
    load([path_to_data, 'SerialData_', algorithms{i}, '_Franka']);
end
%% Develop LQR gains
nTraining = find(LS.error(:,1)== 100); % find index of results with 100 Training Data
nStates = length(LS.A);
nControl = size(LS.B, 3);

% Specify LQR weights
Q = zeros(nStates,nStates); 
Q(1:10, 1:10) = 1*eye(10);
R = 0.1*eye(nControl); 

A_LS = squeeze(LS.A(nTraining, :,:));
A_CG = squeeze(CG.A(nTraining, :,:));
A_SOC = squeeze(SUB.A(nTraining, :,:));
A_WLS = squeeze(WLS.A(nTraining, :,:));

B_LS = squeeze(LS.B(nTraining, :,:));
B_SOC = squeeze(SUB.B(nTraining, :,:));


try 
    LQR.LS = dlqr(A_LS,B_LS,Q,R);
catch
    fprintf('Failed LQR for LS\n');
end

try 
    LQR.SUB= dlqr(A_SOC,B_SOC,Q,R);
catch
    fprintf('Failed LQR for SUB\n');
end

try
    LQR.CG = dlqr(A_CG,B_LS,Q,R);
catch
    fprintf('Failed LQR for CG\n');
end


try
    LQR.WLS = dlqr(A_WLS,B_LS,Q,R);
catch
    fprintf('Failed LQR for CG\n');
end

save('LQR_gains', 'LQR')

