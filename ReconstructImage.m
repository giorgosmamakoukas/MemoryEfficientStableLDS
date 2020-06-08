clear; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set configuration options %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numberSequences = 200; % number of frame sequences to be used
folder_name = 'results'; % directory to save results (will be created)
data_path = '/path/to/data'; % path to directory containing .mat frame sequences
path_to_algorithms = 'algorithms/'; % path to stable LDS algorithms

DIMS = 3:30; % subspace dimensions for which you want to run algorithms

% set standard config options
options.graphic = 0;
options.posdef = 10e-12;
options.init = 0;
options.maxiter = 500000;
options.display = 0;
    
machine_tolerance = 10e-11;

% add data_path to working directory
addpath(data_path);
addpath(path_to_algorithms);
mkdir(folder_name);

% loop over subspace dimensions
for dim_i = 1:length(DIMS) 
    n = DIMS(dim_i);

    % initialize error and time matrices to record scores
    CG.error = nan(numberSequences, 1);
    SUB.error = nan(numberSequences, 1);
    LS.error = nan(numberSequences, 1);
    WLS.error = nan(numberSequences, 1);
    
    LS.stability = nan(numberSequences, 1);
    
    CG.time = nan(numberSequences, 1);
    SUB.time = nan(numberSequences, 1);
    WLS.time = nan(numberSequences, 1);

    % loop over frame sequences
    for i = 0 : numberSequences-1
        name = ['seq_', num2str(i)];
        name

        % load frame sequence i
        load(name)
        P = im2double(data);

        Pnew = P';

        % run SVD on Hankel matrix
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

        % create algorithm input matrices
        Y = M(:,2:end);
        X = M(:,1:end-1);

        % run LS model
        fprintf('LS error: \n');
        LS.error(i+1) = norm(Y - Y*pinv(X) * X, 'fro')^2/2;
        if max(abs(eig(Y*pinv(X)))) <= 1
            LS.stability(i+1) = 1;
        else
            LS.stability(i+1) = 0;
        end

        % run SUB model 
        fprintf('Run SUB model \n');
        timeSUB = clock;
        A_SUB = learnSOCmodel(X, Y,options); 

        % record SUB time
        SUB.time(i+1) = etime(clock, timeSUB);

        % compute and record SUB error
        if max(abs(eig(A_SUB))) <= 1 + machine_tolerance
            SUB.error(i+1) = norm(Y - A_SUB * X, 'fro')^2/2;
        end
        
        % run WLS model
        fprintf('Run WLS model \n');
        timeWLS = clock;
        [A_WLS, ~, ~] = learnWLSmodel(V,S,1,0);

        % record WLS time
        WLS.time(i+1) = etime(clock, timeWLS);

        % compute and record WLS error
        if max(abs(eig(A_WLS))) <= 1 + machine_tolerance
            WLS.error(i+1) = norm(Y - A_WLS * X, 'fro')^2/2;
        end
        
        % run CG model 
        fprintf('Run CG model \n');
        timeCG = clock;
        [A_CG, scores, ~] = learnCGModel(X, Y,1, 0);

        % record CG time
        CG.time(i+1) = etime(clock, timeCG);
        
        % compute and record CG error
        if max(abs(eig(A_CG))) <= 1 + machine_tolerance
            CG.error(i+1) = norm(Y - A_CG * X, 'fro')^2/2;
        end
        
        % store results to dik
        save([folder_name, '/Errors_and_Times_dim_', num2str(n),'.mat'], 'CG', 'WLS', 'SUB', 'LS');
    end
end
