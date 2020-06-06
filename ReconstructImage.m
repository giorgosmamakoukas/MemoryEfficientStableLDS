%% This is image reconstruction for UCSD dataset
clear; 

numberSequences = 254; % Specify your own
folder_name = 'results'; % where to save files
data_path = '/path/to/data';

% Specify number of Video Sequences --- (count seq0)!!!
options.graphic = 0;
options.posdef = 10e-12;
options.init = 0;
options.maxiter = 500000;
options.display = 0;

machine_tolerance = 10e-11;

% Add path to dataset!
addpath(data_path);
DIMS = 3:30;

for dim_i = 1:length(DIMS) % Run optimization for different levels of subspace dimension
    n = DIMS(dim_i);

    % Initialize errors and time 
    CG.error = nan(numberSequences, 1);
    SUB.error = nan(numberSequences, 1);
    LS.error = nan(numberSequences, 1);
    WLS.error = nan(numberSequences, 1);
    
    LS.stability = nan(numberSequences, 1);
    
    CG.time = nan(numberSequences, 1);
    SUB.time = nan(numberSequences, 1);
    WLS.time = nan(numberSequences, 1);

    for i = 0 : numberSequences-1
        name = ['seq_', num2str(i)];
        name
        load(name)
        P = im2double(data);

        Pnew = P';
        % Perform SVD on Hankel Matrix
        if size(Pnew,2) < size(Pnew,1)
            [V,S,U] = svd(Pnew,0);
        else
            [U,S,V] = svd(Pnew',0);
        end
        % Subspace 
        V = V(:,1:n);
        S = S(1:n,1:n);
        U = U(:,1:n);

        M = S*V';

        Y = M(:,2:end);
        X = M(:,1:end-1);

        fprintf('LS error: \n');
        LS.error(i+1) = norm(Y - Y*pinv(X) * X, 'fro')^2/2;
        if max(abs(eig(Y*pinv(X)))) <= 1
            LS.stability(i+1) = 1;
        else
            LS.stability(i+1) = 0;
        end

        % learn SUB model
        fprintf('Run SUB model \n');
        timeSUB = clock;
        A_SUB = learnSOCmodel(X, Y,options); 
        SUB.time(i+1) = etime(clock, timeSUB);
        
        % learn WLS model
        fprintf('Run WLS model \n');
        timeWLS = clock;
        [A_WLS, ~, ~] = learnWLSmodel(V,S,1,0);
        WLS.time(i+1) = etime(clock, timeWLS);
        
         % learn CG model 
        fprintf('Run CG model \n');
        timeCG = clock;
        [A_CG, scores, ~] = learnCGModel(X, Y,1, 0);
        CG.time(i+1) = etime(clock, timeCG);
        
        if max(abs(eig(A_CG))) <= 1 + machine_tolerance
            CG.error(i+1) = norm(Y - A_CG * X, 'fro')^2/2;
        end
        
        if max(abs(eig(A_SUB))) <= 1 + machine_tolerance
            SUB.error(i+1) = norm(Y - A_SUB * X, 'fro')^2/2;
        end

        if max(abs(eig(A_WLS))) <= 1 + machine_tolerance
            WLS.error(i+1) = norm(Y - A_WLS * X, 'fro')^2/2;
        end
        
        mkdir(folder_name);
        save([folder_name, '/Errors_and_Times_dim_', num2str(n),'.mat'], 'CG', 'WLS', 'SUB', 'LS');
    end
end
