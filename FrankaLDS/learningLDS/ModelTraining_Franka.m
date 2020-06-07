addpath('Functions')
load('FrankaExperimentalData.mat')

Ps0_list = nan(length(nTrainingSamples),nStates + nControl);
Psi_list = nan(length(nTrainingSamples),nStates + nControl);
rng(2020);
 for k = 1: nTrainingSamples
    if randomShuffling
        i = randi(length(X));
    else
        i = k;
    end
    Ps0_list(k,:) = Psi_x(X(i,:), U(i,:))';
    Psi_list(k,:) = Psi_x(Y(i,:), U(i,:))';
       
 end

Y = Psi_list(:, 1:nStates)';
X = Ps0_list(:,1:nStates)';
U = Ps0_list(:, nStates+1:end)';
clear Ps0_list Psi_list k Samples i

% Solve unconstrained solution
AB_ls = Y * pinv([X;U]);
A_ls = AB_ls(1:nStates, 1:nStates); 
B_ls = AB_ls(1:nStates, nStates+1:end);



