function [A, B, error, memory_used] = learnSOCmodel_withControl(X, Y, U, options)

XU = [X; U];
n = size(X,1); 
% nA2 = norm(Y,'fro')^2; 

XYtr = X * Y';
XXt = X * X';
XUtr = X * U';
YUtr = Y * U';
UUtr = U * U';

% Options 
if nargin <= 1
    options = [];
end
if ~isfield(options,'maxiter')
    options.maxiter = Inf; 
end
if ~isfield(options,'timemax')
    options.timemax = 10; 
end
if ~isfield(options,'posdef') 
    options.posdef = 1e-12; 
end 
if ~isfield(options,'astab') 
    options.astab = 0;
else
    if options.astab < 0 || options.astab > 1
        error('options.astab must be between 0 and 1.');
    end
end 
if ~isfield(options,'display') 
    options.display = 1;  
end
if ~isfield(options,'graphic') 
    options.graphic = 0;  
end
if ~isfield(options,'init')
    options.init = 1;
end

% Initialization 
e100 = nan(100,1); % Preallocate for speed	

% Given initialization + projection
    % Standard initialization
    S = eye(n); 
    AB_ls = Y*pinv(XU);
    nA2 = norm(Y - AB_ls*XU,'fro')^2/2; 
    [O,C] = poldec(AB_ls(1:n, 1:n)); % Y = K*X, so K = Y * pinv(X);
    try
        % sometimes, due to numerics O*C can be stable, but S\O*C*S may not
        % -- theoretically, that is not possible. 
        eA = abs(eigs(S\O*C*S, 1, 'lm', 'MaxIterations', 1000, 'SubspaceDimension', n));
    catch
        % fprintf('Max eigenvalue not converged. Project C matrix \n');
        eA = 2; %anything larger than 1
    end
    B = AB_ls(1:n, n+1:end);
    if eA > 1 - options.astab
        C = projectPSD(C,0,1-options.astab);
        e_old = norm(Y - (S\ O * C* S) * X - B*U, 'fro')^2/2;
    else
        e_old = norm(Y - AB_ls*XU, 'fro')^2/2;
    end

    % LMI-based initialization
    maxeA = max(1,eA); 
    Astab = (AB_ls(1:n,1:n))/maxeA; 
    [~,Stemp,Otemp,Ctemp] = checkdstable(0.9999*Astab, options.astab); 
    etemp = norm(Y - (Stemp\ Otemp * Ctemp* Stemp) * X - B * U, 'fro')^2/2;
    if etemp < e_old
        S = Stemp; 
        O = Otemp;
        C = Ctemp;
        e_old = etemp;
    end
    



options.alpha0 = 0.5; % Parameter of FGM, can be tuned. 
options.lsparam = 1.5;
options.lsitermax = 60; 
options.gradient = 0; 

i = 1; 

alpha = options.alpha0;
Ys = S; 
Yo = O; 
Yc = C; 
Yb = B;
restarti = 1; 
begintime0 = clock; 


% Main loop 
while i < options.maxiter 
    if etime(clock,begintime0) > 1800		
        break;	
    end
    alpha_prev = alpha;
    
    % Compute gradient
    Atemp = S \ O * C * S;	
    Z = - (XYtr - XXt * Atemp' - XUtr*B') /S;	
    gS = (Z*O*C - Atemp * Z)';	
    gO = (C*S*Z)';	
    gC = (S*Z*O)';
    gB = (Atemp * XUtr + B *UUtr - YUtr); 
                
    inneriter = 1; 
    step = 1;
    
        % For i == 1, we always have a descent direction
        Sn = Ys - gS*step;
        On = Yo - gO*step; 
        Cn = Yc - gC*step; 
        Bn = Yb - gB * step;
        % Project onto feasible set
        Sn = projectInvertible(Sn,options.posdef);
        
        try
            maxE = abs(eigs(Sn\On*Cn*Sn, 1, 'lm', 'MaxIterations', 1000, 'SubspaceDimension', n));
        catch
            % fprintf('Max eigenvalue not converged. Project On and Cn matrices \n');
            maxE = 2; %anything larger than 1
        end
        if  maxE > 1 - options.astab
            On = poldec(On); 
            Cn = projectPSD(Cn,0,1-options.astab); 
        end
        e_new = norm(Y - (Sn\ On * Cn* Sn) * X - Bn * U, 'fro')^2/2;
    
% Barzilai and Borwein
    while (e_new > e_old) && (inneriter <= options.lsitermax) 
        % For i == 1, we always have a descent direction
        Sn = Ys - gS*step;
        On = Yo - gO*step; 
        Cn = Yc - gC*step;
        Bn = Yb - gB * step;
        % Project onto feasible set
        Sn = projectInvertible(Sn,options.posdef);
        
        try 
            maxE = abs(eigs(Sn\On*Cn*Sn, 1, 'lm', 'MaxIterations', 1000, 'SubspaceDimension', n));
        catch
            % fprintf('Max eigenvalue not converged. Project On and Cn matrices \n');
            maxE = 2; %anything larger than 1
        end
            
        if  maxE > 1 - options.astab
            On = poldec(On); 
            Cn = projectPSD(Cn,0,1-options.astab); 
        end
        e_new = norm(Y - (Sn\ On * Cn* Sn) * X - Bn * U, 'fro')^2/2;
        
        if e_new < e_old && e_new > prev_error
            break;
        end
        if inneriter == 1
            prev_error = e_new;
        else
            if e_new < e_old && e_new > prev_error
                break;
            else
                prev_error = e_new;
            end
        end
        step = step/options.lsparam; 
        inneriter = inneriter+1;
    end
   
    % Conjugate with FGM weights, if decrease was achieved 
    % otherwise restart FGM 
    alpha = ( sqrt(alpha_prev^4 + 4*alpha_prev^2 ) - alpha_prev^2) / (2);
    beta = alpha_prev*(1-alpha_prev)/(alpha_prev^2+alpha);
    if (e_new > e_old) % line search failed 
%     if (inneriter > options.lsitermax) % line search failed 
        if restarti == 1
            % Restart FGM if not a descent direction
            restarti = 0;
            alpha = options.alpha0; 
            Ys = S;
            Yo = O;
            Yc = C;
            Yb = B;
            e_new = e_old;
%             % Reinitialize step length
        elseif restarti == 0 % no previous restart and no descent direction => converged 
            e_new = e_old; 
%             i
            break; 
        end
    else
        restarti = 1;
        % Conjugate
        if options.gradient == 1
            beta = 0; 
        end
        Ys = Sn + beta*(Sn-S); 
        Yo = On + beta*(On-O);
        Yc = Cn + beta*(Cn-C);
        Yb = Bn + beta*(Bn - B);
        % Keep new iterates in memory 
        S = Sn;
        O = On;
        C = Cn;
        B = Bn;
    end
    i = i+1;
        
    current_i = mod(i, 100) + ~mod(i, 100)*100; % i falls in [1, 100]	
    e100(current_i) = e_old; 	
    current_i_min_100 = mod(current_i+1, 100) + ~mod(current_i+1, 100)*100;
    % Check if error is small (1e-6 relative error)
    if (e_old < 1e-6*nA2 || (i > 100 && e100(current_i_min_100)-e100(current_i) < 1e-8*e100(current_i_min_100))) 	
        break; 	
    end	
    e_old = e_new; 
    
end


% Refine solution

    A = S\O*C*S;

    % Move in direction of unstable A until you meet the stability boundary (to
    % decrease error)
    e0 = 0.00001;
    e_step = 0.00001;
    e = e0;
    n = length(A);
%     AB_ls = Y*pinv([X; U]);
    grad = AB_ls - [A, B];

%     A_ls = AB_ls(1:n, 1:n);
%     B_ls = AB_ls(1:n, n+1:end);

    AB_new = [A, B] + e * grad; 
    Anew = AB_new(1:n,1:n);



    try
        maxE = abs(eigs(Anew, 1, 'lm', 'MaxIterations', 1000, 'SubspaceDimension', n));
    catch
        % fprintf('Max eigenvalue not converged. Consider Anew unstable \n');
        maxE = 2; %anything larger than 1
    end

    % while (maxE <= 1) && norm(Anew - A_ls, 'fro')>0.00001 % unstable operator
    while (maxE < 1) && norm(AB_ls - AB_new,'fro')^2/2 > 0.01 % unstable operator
        e = e+e_step;

        AB_new = [A, B] + e*grad;
        Anew = AB_new(1:n, 1:n); 
        try
            maxE = abs(eigs(Anew, 1, 'lm', 'MaxIterations', 1000, 'SubspaceDimension', n));
        catch
            % fprintf('Max eigenvalue not converged. Consider Anew unstable \n');
            maxE = 2; %anything larger than 1
        end
    end
    if e ~= e0
        ABtemp = [A, B] + (e-e_step) * grad;
        A = ABtemp(1:n, 1:n);
        B = ABtemp(1:n, n+1:end);
    end
    
    stored_var = whos();
    memory_used = 0;	
    for i = 1 : length(stored_var)	
        memory_used = memory_used + stored_var(i).bytes;	
    end

    error = norm(Y - A * X - B * U, 'fro')^2/2;
end

% Project the matrix Q onto the PSD cone 
% 
% This requires an eigendecomposition and then setting the negative
% eigenvalues to zero, 
% or all eigenvalues in the interval [epsilon,delta] if specified. 
function Sp = projectInvertible(S, epsilon)

    [s,v,d] = svd(S);

    if min(v) < epsilon
        Sp = s*diag(max(diag(v), epsilon))*d';
    else
        Sp = S;
    end

end

function Qp = projectPSD(Q,epsilon,delta) 

% if isempty(Q)
%     Qp = Q;
%     return;
% end

if nargin <= 1
    epsilon = 0;
end

if nargin <= 2
    delta = +Inf;
end

Q = (Q+Q')/2;

% if max(max(isnan(Q))) == 1 || max(max(isinf(Q))) == 1
%     error('Input matrix has infinite or NaN entries');
% end
[V,e] = eig(Q);

Qp = V * diag( min( delta, max(diag(e),epsilon) ) ) * V'; 
end

function [U, H] = poldec(A)
%POLDEC   Polar decomposition.
%         [U, H] = POLDEC(A) computes a matrix U of the same dimension
%         (m-by-n) as A, and a Hermitian positive semi-definite matrix H,
%         such that A = U*H.
%         U has orthonormal columns if m >= n, and orthonormal rows if m <= n.
%         U and H are computed via an SVD of A.
%         U is a nearest unitary matrix to A in both the 2-norm and the
%         Frobenius norm.

%         Reference:
%         N. J. Higham, Computing the polar decomposition---with applications,
%         SIAM J. Sci. Stat. Comput., 7(4):1160--1174, 1986.
%
%         (The name `polar' is reserved for a graphics routine.)

% [m, n] = size(A);

[P, S, Q] = svd(A, 0);  % Economy size.
% if m < n                % Ditto for the m<n case.
%    S = S(:, 1:m);
%    Q = Q(:, 1:m);
% end
U = P*Q';
if nargout == 2
   H = Q*S*Q'; % provably from svd decomposition
%    H = (H + H')/2;      % Force Hermitian by taking nearest Hermitian matrix.
end

end

function [P,S,O,C] = checkdstable(A, epsilon) 

n = length(A); 
P = dlyap(A',eye(n)); 
if nargout >= 3
    S = sqrtm(P); 
    OC = S*A/S; 
    [O,C] = poldec(OC); 
    C = projectPSD(C,0,1 - epsilon); 
end
end

