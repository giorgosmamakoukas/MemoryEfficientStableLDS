import typing
import time

import numpy
import scipy

import soc
import utilities


def initialize_soc(X,Y):
    """
    debug
    - project_psd has options.astab arg being used
    in MATLAB
    - do we need inverse of S in e_old?
    - check all pseudo-inverses for X, Y swapped
    """
    S = numpy.identity(len(X))
    S_inv = S
    A_ls = Y @ numpy.linalg.pinv(X) 

    O,C = scipy.linalg.polar(a=A_ls, side='right')
    eig_max = utilities.get_max_abs_eigval(O @ C)
    
    if eig_max > 1:
        C = utilities.project_psd(C, eps=0, delta=1)
        e_old = utilities.adjusted_frobenius_norm(Y - (S_inv @ O @ C @ S) @ X)
    else:
        e_old = utilities.adjusted_frobenius_norm(Y - A_ls @ X) 
    
    eig_max = max(1, eig_max)
    A_stab = A_ls / eig_max
    _,S_,O_,C_ = soc.checkdstable(0.9999*A_stab)
    S_inv_ = numpy.linalg.inv(a=S_)
    e_temp = utilities.adjusted_frobenius_norm(Y - (S_inv_ @ O_ @ C_ @ S_) @ X)
    if e_temp < e_old:
        S, O, C = S_, O_, C_
        e_old = e_temp
    
    return e_old, S, O, C

def refine_soc_solution(X, Y, S, O, C, **kwargs):
    """
    debug
    - eigenvalue computation in NumPy does not have
    SubspaceDimension specific like Matlab, or MaxIterations
    """
    
    e_0 = kwargs.get('e_0', 0.0001)
    delta = kwargs.get('delta', 0.00001)
    
    
    e_t = e_0
    S_inv = numpy.linalg.inv(a=S)
    A = S_inv @ O @ C @ S  
    A_ls = X @ numpy.linalg.pinv(Y)
    
    A_new = A + e_0 * A_ls
    grad = A_ls - A
    
    # get initial max abs eigenvalue
    eig_max = utilities.get_max_abs_eigval(A_new)
    
    while eig_max <= 1 and utilities.adjusted_frobenius_norm(A_new - A_ls) > 0.01:
        e_t += delta
        A_new = A + e_t * grad
        eig_max = utilities.get_max_abs_eigval(A_new)
    
    if e_t != e_0:
        A = A + (e_t - delta) * grad
    
    return A


def learn_stable_soc(X,Y, **kwargs):

    """
    NOTE: Change Yb, Ys, Yu to appropriate SOC names
    NOTE: Check that all kwargs of all functions are provided correctly
    NOTE: Error about termination conditions
    """
    
    time_limit = kwargs.get('time_limit', 1800)
    alpha = kwargs.get('alpha', 0.5)
    lsparam = kwargs.get('lsparam', 5)
    lsitermax = kwargs.get('lsitermax', 20)
    gradient = kwargs.get('gradient', False)
    log_memory = kwargs.get('log_memory', True)


    e100 = [None] * 100
    
    # add initialization method here
    A_ls = Y @ numpy.linalg.pinv(X) 
    nA2 = utilities.adjusted_frobenius_norm(Y - A_ls @ X)
    e_old, S, O, C = initialize_soc(X,Y)

    Ys, Yu, Yb = S, O, C
    
    i = 1
    restart_i = True
    t_0 = time.time()
    while i:
        t_n = time.time()
        if t_n - t_0 > 1800:
            break
        alpha_prev = alpha

        S_grad, O_grad, C_grad = soc.get_gradients(X, Y, S, O, C)
        
        step = kwargs.get('step', 100)
        inneriter = 1
        
        Sn = Ys - S_grad * step
        On = Yu - O_grad * step
        Cn = Yb - C_grad * step
        
        Sn, On, Cn = soc.project_to_feasible(Sn, On, Cn, **kwargs)
        
        Sn_inv = numpy.linalg.inv(a=Sn)
        e_new = utilities.adjusted_frobenius_norm(Y - (Sn_inv @ On @ Cn @ Sn) @ X)

        while e_new > e_old and inneriter <= lsitermax:
            
            Sn = Ys - S_grad * step
            On = Yu - O_grad * step
            Cn = Yb - C_grad * step
            
            Sn, On, Cn = soc.project_to_feasible(Sn, On, Cn, **kwargs)
        
            Sn_inv = numpy.linalg.inv(a=Sn)
            e_new = utilities.adjusted_frobenius_norm(Y - (Sn_inv @ On @ Cn @ Sn) @ X)

            try:
                assert (e_new < e_old) and (e_new > prev_error)
                break
            except (AssertionError, NameError):
                    pass

            if inneriter == 1:
                prev_error = e_new
            else:
                if e_new < e_old and e_new > prev_error:
                    break
                else:
                    prev_error = e_new
            step /= lsparam
            inneriter += 1
        
        
        alpha = (numpy.sqrt(alpha_prev**4 + 4*alpha_prev**2) - alpha_prev**2)/2
        beta = alpha_prev * (1 - alpha_prev) / (alpha_prev**2 + alpha)
        
        if e_new > e_old:
            if restart_i:
                restart_i = False
                alpha = kwargs.get('alpha', 0.5)
                Ys, Yu, Yb, e_new = S, O, C, e_old
            else:
                break
        else:
            restart_i = True
            if gradient:
                beta = 0
            Ys = Sn + beta * (Sn - S)
            Yu = On + beta * (On - O)
            Yb = Cn + beta * (Cn - C)
            
            S, O, C = Sn, On, Cn
        i+=1

        current_i = utilities.adjusted_modulo(i, 100)
        e100[current_i - 1] = e_old
        current_i_min_100 = utilities.adjusted_modulo(current_i + 1, 100)
        if (
            (e_old < 1e-6 * nA2) or 
            (
                (i > 100) and 
                (e100[current_i_min_100] - e100[current_i]) < 1e-8*e100[current_i_min_100]  
                )
            ):
            break
        e_old = e_new

    A = refine_soc_solution(X, Y, S, O, C, **kwargs)
    
    mem = None
    if log_memory:
        object_mems = [value.nbytes for _, value in locals().items() if isinstance(value, numpy.ndarray)]
        mbs_used = sum(object_mems)/1e6
        mem = round(mbs_used, 3)

    # just for debugging
    #A, mem = numpy.identity(X.shape[0]), numpy.nan

    return A, mem