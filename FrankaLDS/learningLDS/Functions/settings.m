
% function [] = settings()% Parameters 
% Number_of_Samples = 50; % Number of random initial conditions for both training and testing data
ts = 1; % time spacing between state measurements
tFinal = 1; % time horizon --- used in measuring error

nKoopman = 18; % Number of basis functions, including control terms
nStates = 18; % Number of system states
nControl = 7; % Number of system inputs

m = tFinal/ts; % Number of prediction steps
n = 4; % Number of derivatives used in basis functions
% end
