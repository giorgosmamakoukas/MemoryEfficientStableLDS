function [M, scores, times, memory_used] = learnCGModel(S1,S2,bound, simulate_LB1)
% LEARNCGMODEL learns the dynamics matrix of a Linear Dynamical System 
% (LDS) from states using the constraint generation algorithm.
%
%  Syntax
%  
%    M = learnCGModel(S1,S2,simulate_LB1)
%
%  Description
%
%     Implements constraint generation algorithm described in
%     ' A Constraint Generation Approach for Learning Stable Linear
%     Dynamical Systems'
%     Sajid M. Siddiqi, Byron Boots, Geoffrey J.Gordon
%     NIPS 2007
%
%       
%   Given matrices of x_t states and x_{t+1} states, learns a *stable*
%   dynamics matrix that maps x_t to x_{t+1} by starting with the
%   least-squares solution as an unconstrained QP, then repeating:
%   check for stability, use the unstable solution to generate a constraint
%   and add it to the QP. When simulating LB-1 using constraint generation, 
%   constraints are added until the top singular value is 1.

%   Currently, Matlab's 'quadprog' function is used to solve the QP. 
%   CVX (with Sedumi), publicly available
%   optimization software, can also be used. 
%
%
%   M = learnCGModel(S1,S2,simulate_LB1) takes these inputs,
%      S1       - Matrix of state estimates at successive timesteps
%                 x_t,x_{t+1},x_{t+2},...
%      S2       - Matrix of next-state estimates at successive timesteps
%                 x_{t+1},x_{t+2},x_{t+3},...
%      simulate_LB1  - if 1, will use constraint generation to simulate LB-1,
%                 allowing us to run LB-1 on larger problems than the 
%                 actual LB-1 implementation in learnLB1model
%                
%     
%    and returns
%    M          - dynamics matrix estimate
%
% Authors: Sajid Siddiqi and Byron Boots

warning off optim:quadprog:SwitchToMedScale;

if simulate_LB1
    fprintf('**** SIMULATING LACY-BERNSTEIN 1**** \n');
end


display = 0;
eps = 0;
% sv_eps = 0.0004999999999;	
sv_eps = 0;
dotprint = 5;
maxIter = 4000;
svd_maxIter = 4000;

begintime = clock; 
begintime0 = clock; 

% we keep track of the following quantities over iterations,
% they can be plotted if desired ...
maxevals = [];
minevals = [];
scores = [];
svals = [];
times = [];

d = size(S1,1);

% calculating terms required for the quadratic objective function 
% P,q,r (eqn 4 in paper)

C = S1*S1';
C2 = S2*S1';
tmp = C2';
q = tmp(:);
P = zeros(d^2,d^2);

for i = 1:d
    P( (i-1)*d + 1 : (i-1)*d + d , (i-1)*d + 1 : (i-1)*d + d ) = C;
end
r = trace(S2*S2');

% constraints for QP (initially empty)
G = [];
h = [];

% first M is learned unconstrained
% fprintf('calculating initial M...\n');
M = pinv(S1')*S2';
lsscore = norm(S1'*M - S2','fro')^2;
scores(end+1) = lsscore;
% fprintf('frob score = %.4f\n',lsscore);

[tmp_evals,max_e,min_e] = get_eigenthings(M);
maxevals(end+1) = max_e;
minevals(end+1) = min_e;

[u,s,v] = svds(M,1, 'largest','MaxIterations', svd_maxIter);  
Morig = M;

% if we're simulating LB-1, watch for top singular value to
% dip below 1
if simulate_LB1       
    if s  <= bound + sv_eps
        M= M';
        
        stored_var = whos();	
        memory_used = 0;	
        for i = 1 : length(stored_var)	
            memory_used = memory_used + stored_var(i).bytes;	
        end
        
        return;
    else
%         fprintf('initial smallest eigenval = %.4f\n',min_e);
    end    
else     % watch for stability 
    if max_e < bound & min_e > -bound
        M = M';
        
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

% calculate constraint based on unstable solution
tmp = u*v';
ebar = tmp(:);
G = [G ; ebar'];
h = [h ; bound];

svals(end+1) = s;

constraints = 0;

% iteratively add constraints, recalculate QP solution

for i = 1:2000
    
     if etime(clock,begintime0) > 1800		
        break;	
    end
    % We want to minimize m'*P*m - 2*q'*m + r, whereas    
    % for quadprog, the objective is to minimize x'*H*x/2  + f'*x
    % with constraints Gx - h <= 0, so have to flip some signs ..
    options = optimoptions('quadprog','Algorithm','interior-point-convex', 'Display','off','MaxIter',maxIter);
    [m,val] = quadprog(2*P,2*(-q),G,h,[],[],[],[],[], options);

%    CAN ALSO USE CVX INSTEAD OF QUADPROG:
%    val = 0;
%     cvx_begin
%         variable m(d*d)
%         minimize(norm(S1'*reshape(m,d,d)-S2', 'fro'))
%         subject to
%             -G*m + h >= 0;
%     cvx_end
%     

    % adding back the constant term in the objective irrelevant to iqph
    
    score = val+r;
    scores(end+1) = score;
    times(end+1) = etime(clock,begintime);
    begintime = clock;
    svals(end+1) = s;
    % reshaping M into the matrix we need
    
    Mprev = M;
    M = reshape(m,d,d);  
    
    conscore = norm(S1'*M - S2','fro')^2;
    
    diffscore = (conscore - lsscore)/lsscore;

    [tmp_evals,max_e,min_e] = get_eigenthings(M);

    maxevals = [maxevals max_e];
    minevals = [minevals min_e];

    [u,s,v] = svds(M,1, 'largest','MaxIterations', svd_maxIter);

    % if we're simulating LB-1, watch for top singular value to
    % dip below 1, or number of iterations to exceed allowed maximum
    if simulate_LB1
        if s <= bound + sv_eps 
            break;
        else
            if mod(i,dotprint) == 0 & display
            end
        end
    else      % watch for stability 
        
        if( max_e < bound & min_e > -bound )    % then we're done
            break;
        else
%             fprintf('.');
            if mod(i,dotprint) == 0 & display
            end
        end
    end

    % don't need to check largest singular value, because it 
    % must be greater than 1 since the eigenvalue was.
    
    % Add a constraint based on largest singular value
    if mod(i,dotprint) == 0 & display

    end
    tmp = u*v';
    ebar = tmp(:);
    G = [G ; ebar'];
    h = [h ; bound];
    constraints = i;
    end

maxeig= max(abs(eig(M)));
maxsval = svds(M,1, 'largest','MaxIterations', svd_maxIter);

% refining the solution: binary search to find boundary of stability region

if ~simulate_LB1
    
    Mbest = [];
    tol = 0.00001;
    lo = 0;
    hi = 1;

    % interpolating from previous best solution
    Morig = Mprev;
    if  simulate_LB1 == 0
        while hi-lo > tol
%             fprintf(',');
            alpha = lo + (hi-lo)/2;
            Mbest = (1-alpha)*M + alpha*Morig;
            maxeig = max(abs(eig(Mbest)));
            if (maxeig) > bound
                hi = alpha;
            elseif maxeig < bound
                lo = alpha;
            else    % done!
                break
            end
        end
        Mbest = (1-alpha + tol)*M + (alpha-tol)*Morig;
        M = Mbest;
        maxeig= max(abs(eig(M)));
        maxsval = svds(M,1, 'largest','MaxIterations', svd_maxIter); 	
        
%         fprintf('top eigval after binary search: %.7f\n',maxeig);
%         fprintf('top sval after binary search: %.7f\n',maxsval);
    end

end

M = M';  % returning dynamics matrix in proper orientation
score = norm(S2- M*S1,'fro')^2;
scores(end+1) = score;
diffscore = (score - lsscore)/lsscore;
stored_var = whos();	
memory_used = 0;	
for i = 1 : length(stored_var)	
    memory_used = memory_used + stored_var(i).bytes;	
end

end

function [actual_evals,max_e,min_e] = get_eigenthings(M)
% maximum and minimum magnitudes of eigenvalues and corresponding
% eigenvectors, and the actual eigenvalues
[tmp_evecs,tmp_evals] = eig(M);
actual_evals = diag(tmp_evals);
evals = abs(actual_evals);
max_e = max(evals);
min_e = min(evals);

end
