function [A, memory_used] = learnSOCmodel(X, Y ,options) 
n = size(X,1); 
% nA2 = norm(Y,'fro')^2; 

XYtr = X * Y';
XXt = X * X';

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
    options.posdef = 1e-9; 
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
    A_ls = Y*pinv(X); 
    nA2 = norm(Y - A_ls*X,'fro')^2/2; 
    [O,C] = poldec(A_ls); % Y = K*X, so K = Y * pinv(X);
    try
        eA = abs(eigs(O*C, 1, 'lm', 'MaxIterations', 3000, 'SubspaceDimension', n));
    catch
        fprintf('Max eigenvalue not converged. Project C matrix \n');
        eA = 2; %anything larger than 1
    end
    if eA > 1
        C = projectPSD(C,0,1-options.astab);
        e_old = norm(Y - (S\ O * C* S) * X, 'fro')^2/2;
    else
        e_old = norm(Y - A_ls*X, 'fro')^2/2;
    end

    % LMI-based initialization
    maxeA = max(1,eA); 
    Astab = (A_ls)/maxeA; 
    [~,Stemp,Otemp,Ctemp] = checkdstable(0.9999*Astab); 
    etemp = norm(Y - (Stemp\ Otemp * Ctemp* Stemp) * X, 'fro')^2/2;
    if etemp < e_old
        S = Stemp; 
        O = Otemp;
        C = Ctemp;
        e_old = etemp;
    end
    



options.alpha0 = 0.5; % Parameter of FGM, can be tuned. 
options.lsparam = 5;
options.lsitermax = 20; 
options.gradient = 0; 

i = 1; 

alpha = options.alpha0;
Ys = S; 
Yo = O; 
Yc = C; 
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
    Z = - (XYtr - XXt * Atemp' ) /S;	
    gS = (Z*O*C - Atemp * Z)';	
    gO = (C*S*Z)';	
    gC = (S*Z*O)';

    inneriter = 1; 
    step = 100;
    
        % For i == 1, we always have a descent direction
        Sn = Ys - gS*step;
        On = Yo - gO*step; 
        Cn = Yc - gC*step; 
        % Project onto feasible set
        Sn = projectInvertible(Sn,options.posdef);
        
        try
            maxE = abs(eigs(On*Cn, 1, 'lm', 'MaxIterations', 3000, 'SubspaceDimension', n));
        catch
            maxE = 2; %anything larger than 1
        end
        if  maxE > 1
            On = poldec(On); 
            Cn = projectPSD(Cn,0,1-options.astab); 
        end
        e_new = norm(Y - (Sn\ On * Cn* Sn) * X, 'fro')^2/2;
    
% Barzilai and Borwein
    while (e_new > e_old) && (inneriter <= options.lsitermax) 
        % For i == 1, we always have a descent direction
        Sn = Ys - gS*step;
        On = Yo - gO*step; 
        Cn = Yc - gC*step; 
        % Project onto feasible set
        Sn = projectInvertible(Sn,options.posdef);
        
        try 
            maxE = abs(eigs(On*Cn, 1, 'lm', 'MaxIterations', 3000, 'SubspaceDimension', n));
        catch
            maxE = 2; %anything larger than 1
        end
            
        if  maxE > 1
            On = poldec(On); 
            Cn = projectPSD(Cn,0,1-options.astab); 
        end
        e_new = norm(Y - (Sn\ On * Cn* Sn) * X, 'fro')^2/2;
        
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
            e_new = e_old;          
        elseif restarti == 0 % no previous restart and no descent direction => converged 
%             e_new = e_old; 
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
        % Keep new iterates in memory 
        S = Sn;
        O = On;
        C = Cn;
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
e0 = 0.0001;
e_step = 0.00001;
e = e0;
Anew = A + e * A_ls; 
grad = A_ls - A;

try
    maxE = abs(eigs(Anew, 1, 'lm', 'MaxIterations', 3000, 'SubspaceDimension', n));
catch
    % fprintf('Max eigenvalue not converged. Consider Anew unstable \n');
    maxE = 2; %anything larger than 1
end

while (maxE <= 1) && norm(Anew - A_ls, 'fro')>0.01 % unstable operator
    e = e+e_step;
    Anew = A + e * grad;
    try
        maxE = abs(eigs(Anew, 1, 'lm', 'MaxIterations', 3000, 'SubspaceDimension', n));
    catch
        maxE = 2; %anything larger than 1
    end
end
if e ~= e0
    A = A + (e-e_step) * grad;
end


stored_var = whos();
memory_used = 0;
for i = 1 : length(stored_var)
    memory_used = memory_used + stored_var(i).bytes;
end

end

function Sp = projectInvertible(S, epsilon)

    [s,v,d] = svd(S);

    if min(v) < epsilon
        Sp = s*diag(max(diag(v), epsilon))*d';
    else
        Sp = S;
    end

end

function Qp = projectPSD(Q,epsilon,delta) 

if nargin <= 1
    epsilon = 0;
end

if nargin <= 2
    delta = +Inf;
end

Q = (Q+Q')/2;

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

function [P,S,O,C] = checkdstable(A) 

n = length(A); 
P = dlyap(A',eye(n)); 
if nargout >= 3
    S = sqrtm(P); 
    OC = S*A/S; 
    [O,C] = poldec(OC); 
    C = projectPSD(C,0,1); 
end
end

