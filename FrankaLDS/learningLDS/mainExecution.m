%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Description
%
%       This file uses experimental data from the Franka manipulator to 
%       learn a LDS with inputs using different data-driven methods. In the 
%       end, it saves LQR gains for all data-driven models. 
%       The data-driven learning methods used are:
%           1. Least-squares (LS) unconstrained (possibly unstable) A and B 
%              matrix pair
%           2. A learned matrix pair [A, B] with SUB, that simultaneously 
%              learns a stable A, and a B matrix. 
%           3. A learned matirx pair [A, B] with WLS, that learns a stable 
%              A, without updating the least-squares B matrix solution. 
%           4. A learned matrix pair [A,B] with CG, that learns a stable A, 
%              without updating the least-squares B matrix solution.
%
%
%
%       Given experimental data from the Franka manipulator, the code:
%           1. Combines all data (discontinuous) runs into one file
%           2. Computes the least-squares solution
%           3. Computes the SUB, WLS, and CG stable solutions
%           4. Calculates LQR gains for each method
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all; clc; system = 'Franka';

path_to_training_data = '';
algorithms_path = '../../algorithms/'; % path for stable LDS algorithms
save_directory = 'results/';

addpath(algorithms_path);
options.graphic = 0;
options.posdef = 10e-12;
options.maxiter = 200000;

% settings;
nStates = 17; % Number of system states
nControl = 7; % Number of system inputs

AllSamples = [50:25:100, 150:50:200, 300, 400 500, 1000, 1500, 2000];

for randomShuffling = 0 : 1
    if randomShuffling == 1
        saveName = 'Randomized';
    else
        saveName = 'Serial';
    end

    numberSamples = length(AllSamples);
    SUB.error = nan(numberSamples, 2);
    CG.error = nan(numberSamples, 2);
    WLS.error = nan(numberSamples,2);
    LS.error = nan(numberSamples, 2);

    SUB.time = nan(numberSamples, 2);
    CG.time = nan(numberSamples, 2);
    WLS.time = nan(numberSamples, 2);

    SUB.maxeval = nan(numberSamples, 2);
    CG.maxeval = nan(numberSamples, 2);
    WLS.maxeval = nan(numberSamples, 2);
    LS.maxeval = nan(numberSamples, 2);

    LS.A = nan(numberSamples, nStates, nStates);
    LS.B = nan(numberSamples, nStates, nControl);
    SUB.A = nan(numberSamples, nStates, nStates);
    SUB.B = nan(numberSamples, nStates, nControl);
    CG.A = nan(numberSamples, nStates, nStates);
    WLS.A = nan(numberSamples, nStates, nStates);


    for nTraining = 1 : numberSamples

        %% Compute LS (unconstrained) [A, B] solution
        nTrainingSamples = AllSamples(nTraining);
        fprintf('\n\n %d \n \n', nTrainingSamples);

        fprintf('Computing LS unconstrained [A, B] solution ... \n');
        ModelTraining_Franka; 
        e_LS = norm(Y - A_ls * X - B_ls * U, 'fro')^2/2;
        maxeval_LS = max(abs(eig(A_ls)) );
        LS.error(nTraining, :) = [nTrainingSamples, e_LS];
        LS.maxeval(nTraining, :) = [nTrainingSamples, maxeval_LS];
        LS.A(nTraining, :,:) = A_ls;
        LS.B(nTraining, :,:) = B_ls;

        fprintf('    Max eigenvalue is : %.4f \n', maxeval_LS);
        fprintf('    Reconstruction error : %.5f \n', e_LS);
        save([save_directory, saveName, 'Data_LS_', system], 'LS');


        %% Compute SUB (stable) [A, B] solution
        fprintf('Computing stable [A, B] solution using SUB ... \n');

        timeSUB = clock;
        [A_SUB, B_SUB, ~, ~] = learnSOCmodel_withControl(X,Y, U, options);
        SUB.time(nTraining, :) = [nTrainingSamples, etime(clock, timeSUB)];
        SUB.A(nTraining, :,:) = A_SUB;
        SUB.B(nTraining, :,:) = B_SUB;

        e_SUB = norm(Y - A_SUB*X - B_SUB*U, 'fro')^2/2;
        maxeval_SUB = max(abs(eig(A_SUB)));
        if max(abs(eig(A_SUB))) <= 1 
            SUB.error(nTraining, :) = [nTrainingSamples, e_SUB];
        end
        SUB.maxeval(nTraining, :) = [nTrainingSamples, maxeval_SUB];

        fprintf('    Max eigenvalue is : %.4f \n', maxeval_SUB);
        fprintf('    Reconstruction error : %.5f \n', e_SUB);    
        save([save_directory, saveName,'Data_SUB_', system], 'SUB');

        %% Compute WLS (stable) [A, B] solution
        fprintf('Computing stable A solution using WLS ... \n');

        Pnew = [X(:,1), (Y-B_ls * U)];
        [U_wls,S_wls,V_wls] = svd(Pnew,0);

        n = nStates;
        V_wls = V_wls(:,1:n);
        S_wls = S_wls(1:n,1:n);
        U_wls = U_wls(:,1:n);

        timeWLS = clock;
        [A_WLS, ~, ~, ~] = learnWLSmodel(V_wls,S_wls,1,0);
        WLS.time(nTraining,:) = [nTrainingSamples, etime(clock,timeWLS)];
        WLS.A(nTraining, :,:) = A_WLS;

        e_WLS = norm(S_wls*V_wls(2:end,:)' - A_WLS * S_wls*V_wls(1:end-1,:)', 'fro')^2/2;
        maxeval_WLS = max(abs(eig(A_WLS)));
        if max(abs(eig(A_WLS))) <= 1 
            WLS.error(nTraining, :) = [nTrainingSamples, e_WLS];
        end
        WLS.maxeval(nTraining,:) = [nTrainingSamples, maxeval_WLS];
        fprintf('    Max eigenvalue is : %.4f \n', max(abs(eig(A_WLS)) ));
        fprintf('    Reconstruction error : %.5f \n', e_WLS);    
        save([save_directory, saveName,'Data_WLS_', system], 'WLS');    % clearvars -except system

        %% Compute CG (stable) [A, B] solution
        fprintf('Computing stable A using CG ... \n');

        timeCG = clock;
        [A_CG, ~, ~, ~] = learnCGModel(X, Y-B_ls*U, 1, 0);
        CG.time(nTraining, :) = [nTrainingSamples, etime(clock, timeCG)];
        CG.A(nTraining, :,:) = A_CG;

        e_CG = norm(Y - A_CG*X - B_ls*U, 'fro')^2/2;
        maxeval_CG = max(abs(eig(A_CG)));
        if max(abs(eig(A_CG))) <= 1 
            CG.error(nTraining, :) = [nTrainingSamples, e_CG];
        end
        CG.maxeval(nTraining, :) = [nTrainingSamples, maxeval_CG];

        fprintf('    Max eigenvalue is : %.4f \n', maxeval_CG)
        fprintf('    Reconstruction error : %.5f \n', e_CG);    
        save([save_directory, saveName,'Data_CG_', system], 'CG');  

    end
end

