function [Ahat,scores, times, memory_used] = learnWLSmodel(V,S,bound,svd_check)
% LearnWLSModel leans the transition matrix of a Linear Dynamical System using
% the weighted-least-square method
%
% INPUTS
% V         - [tau, n] the right orthogonal matrix of the SVD for observation vectors
% S         - [n n] the scale matrix of the SVD for observation vectors
% bound     - [1] the upper bound of the spectral radius of the transition
%             matrix
% svd_check - [boolen] Setting 0 means checking the bounds of eigent values, while 1 means checking the bounds of singular values 
%
% OUTPUTS
% Ahat      - [n n] the learned transition matrix
% scores    - records the objective values along the optimization track
%
% implemented by Wenbing Huanng, 2016-4-04

% specify the experimental settings
% MIN_THRESH = 0.0004999999999;	
MIN_THRESH = 0;
SCORE_THRESH = 0.0001;

display = 0;
eps = 0;
dotprint = 1;
maxIter = 4000;	
NumQP = 2000;

% we keep track of the following quantities over iterations,
% they can be plotted if desired ...
maxevals = [];
minevals = [];
svals = [];
scores = [];
times = [];

begintime = clock;
begintime0 = clock; 

% first Ahat is learned unconstrained
% fprintf('calculating initial A...\n');
[P,lambda,~] = svd(V(1:end-1,:)'*V(1:end-1,:));
Abar = P'*(V(2:end,:)'*V(1:end-1,:))*P*diag(1./diag(lambda));
A_zp = P'*V(2:end,:)'*V(1:end-1,:)*P;
Ahat = S*P*Abar*P'*diag(1./diag(S));
lsscore = norm(S*V(2:end,:)'- Ahat*S*V(1:end-1,:)','fro')^2;
scores(end+1) = lsscore;
% fprintf('frob score = %.4f\n',lsscore);

% compute the eigenvalues of Abar instead of Ahat
[~,max_e,min_e] = get_eigenthings(Abar);
maxevals(end+1) = max_e;
minevals(end+1) = min_e;


% do the initial check
if svd_check
    [~,s,~] = svds(Abar,1, 'largest', 'MaxIterations', maxIter);
    svals(end+1) = s;
    if s <= bound + MIN_THRESH
        stored_var = whos();	
        memory_used = 0;	
        for i = 1 : length(stored_var)	
            memory_used = memory_used + stored_var(i).bytes;	
        end
        return;
    else
%         fprintf('initial smallest eigenval = %.4f\n',min_e);
    end
    
else
    if max_e < bound & min_e > -bound
        stored_var = whos();	
        memory_used = 0;	
        for i = 1 : length(stored_var)	
            memory_used = memory_used + stored_var(i).bytes;	
        end
        return;
    else
%         fprintf('initial smallest eigenval = %.4f\n',min_e);
    end
end


% calculate the required terms for QP:
% W_H, W_f, W_A, W_b, W_c
constraints = 0;
n = size(V,2);
M = S*(V(2:end,:)'*V(1:end-1,:))*P*diag(1./diag(lambda));

tmp_H = M'*M;
W_H = kron(lambda, tmp_H);
tmp_f = (lambda*tmp_H)';
W_f = -tmp_f(:);
W_c = trace(S*(V(2:end,:)'*V(2:end,:))*S);
W_A = [];
W_b = [];
W = ones(n,1);
Abbar = Abar * diag(W);


% specify the QP optimization method with the interior-point-convex method
options = optimoptions('quadprog','Algorithm','interior-point-convex', 'Display','off','MaxIter',maxIter);
for i=1:NumQP
     if etime(clock,begintime0) > 1800		
        break;	
    end
    Abbarprev = Abbar;
    
%     numCont = min(i,n);
    numCont = 1;
    [W_u,W_s,W_v] = svds(Abbar,numCont, 'largest','MaxIterations', maxIter);
    for j=1:numCont
        tmp = (W_v(:,j)*W_u(:,j)'*Abar)';
        tmp = tmp(:)';
        W_A = [W_A; tmp];
        W_b = [W_b; bound];
    end
  

    [W,FVAL,EXITFLAG] = quadprog(W_H, W_f, W_A, W_b, [], [], [], [], [], options);
    W = reshape(W, [n,n]);
    Abbar = Abar * W;
    
    % switch the QP optimization method to the active-set method if the
    % interior-point-convex method fail to converge
    if EXITFLAG == -2
        instead_options = optimoptions('quadprog','Algorithm','interior-point-convex', 'Display','off','MaxIter',maxIter);
        [W,FVAL,EXITFLAG] = quadprog(W_H, W_f, W_A, W_b, [], [], [], [], [], instead_options);
        %         Abbar = Abar * diag(W);
        W = reshape(W, [n,n]);
        Abbar = Abar * W;
    end
    
    score = (2*FVAL+W_c);
    scores(end+1) = score;
    times(end+1) = etime(clock,begintime);
    begintime = clock;
    diffscore = (score - lsscore)/lsscore;
    
    [tmp_evals,max_e,min_e] = get_eigenthings(Abbar);
    
    maxevals = [maxevals max_e];
    minevals = [minevals min_e];
    
    if svd_check
        [~,s,~] = svds(Abbar,1,  'largest','MaxIterations', maxIter);
        svals(end+1) = s;
        if  s <= bound + MIN_THRESH      % then we're done
            break;
        else
%             fprintf('.');
            if mod(i,dotprint) == 0 & display
%                 fprintf('eps: %.3f, diffscore: %.4f, top eval: %.7f, small eval: %.7f\n',eps,diffscore,max_e,min_e);
            end
        end
    else
        if( max_e < bound & min_e > -bound )    % then we're done
            break;
        else
            if mod(i,dotprint) == 0 & display
%                 fprintf('eps: %.3f, diffscore: %.4f, top eval: %.7f, small eval: %.7f\n',eps,diffscore,max_e,min_e);
            end
        end
    end
    
    if (scores(i+1) - scores(i))/score(1) < SCORE_THRESH
         Abbar = binary_interpolation(A_zp,Abbar,bound);
         break;
    end
    
    constraints = i;
end

maxeig= max(abs(eig(Abbar)));
maxsval = svds(Abbar,1, 'largest', 'MaxIterations', maxIter);

% refining the solution: binary search to find boundary of stability region
if ~svd_check
    
%     Aborig = Abbarprev;
    Aborig = Abar;
    Abbest = binary_interpolation(Aborig,Abbar,bound);
    maxeig= max(abs(eig(Abbest)));
    maxsval = svds(Abbest,1,  'largest','MaxIterations', maxIter);
    
    Abbar = Abbest;
    
end

Ahat = S*P*Abbar*P'*diag(1./diag(S));
score = norm(S*V(2:end,:)'- Ahat*S*V(1:end-1,:)','fro')^2;
scores(end+1) = score;
diffscore = (score - lsscore)/lsscore;
time = etime(clock,begintime);

stored_var = whos();	
memory_used = 0;	
for i = 1 : length(stored_var)	
    memory_used = memory_used + stored_var(i).bytes;	
end

end

function Abbest = binary_interpolation(Aborig,Abbar,bound)
tol = 0.00001;
lo = 0;
hi = 1;
while hi-lo > tol
%     fprintf(',');
    alpha = lo + (hi-lo)/2;
    Abbest = (1-alpha)*Abbar + alpha*Aborig;
    maxeig = max(abs(eig(Abbest)));
    if (maxeig) > bound
        hi = alpha;
    elseif maxeig < bound
        lo = alpha;
    else    % done!
        break
    end
end
Abbest = (1-alpha + tol)*Abbar + (alpha-tol)*Aborig;
end


function [actual_evals,max_e,min_e] = get_eigenthings(A)
% maximum and minimum magnitudes of eigenvalues and corresponding
% eigenvectors, and the actual eigenvalues
[tmp_evecs,tmp_evals] = eig(A);
actual_evals = diag(tmp_evals);
evals = abs(actual_evals);
max_e = max(evals);
min_e = min(evals);

end
