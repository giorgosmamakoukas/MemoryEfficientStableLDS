import typing
import time

import numpy
import scipy

import soc
import utilities


def initialize_soc(X,Y, **kwargs):
    """
    DEBUG
    """

    stability_relaxation = kwargs.get('stability_relaxation', 0)

    S = numpy.identity(len(X))
    S_inv = S
    A_ls = Y @ numpy.linalg.pinv(X) 

    O,C = scipy.linalg.polar(a=A_ls, side='right')
    eig_max = utilities.get_max_abs_eigval(O @ C, is_symmetric=False)
    
    if eig_max > 1 - stability_relaxation:
        C = utilities.project_psd(Q=C, eps=0, delta=1-stability_relaxation)
        e_old = utilities.adjusted_frobenius_norm(
            X=Y - (S_inv @ O @ C @ S) @ X)
    else:
        e_old = utilities.adjusted_frobenius_norm(X=Y - A_ls @ X) 
    
    eig_max = max(1, eig_max)
    A_stab = A_ls / eig_max
    _,S_,O_,C_ = soc.checkdstable(
        A=0.9999*A_stab, 
        stab_relax=stability_relaxation)
    S_inv_ = numpy.linalg.inv(a=S_)
    
    e_temp = utilities.adjusted_frobenius_norm(
        X=Y - (S_inv_ @ O_ @ C_ @ S_) @ X)
    if e_temp < e_old:
        S, O, C = S_, O_, C_
        e_old = e_temp
    
    return e_old, S, O, C

def refine_soc_solution(X, Y, S, O, C, **kwargs):
    """
    DEBUG
    - `e_0` and `delta` must become command-line arguments
    """
    
    e_0 = kwargs.get('e_0', 0.0001)
    delta = kwargs.get('delta', 0.00001)
    
    
    e_t = e_0
    S_inv = numpy.linalg.inv(a=S)
    A = S_inv @ O @ C @ S  
    A_ls = Y @ numpy.linalg.pinv(X)
    
    A_new = A + e_0 * A_ls
    grad = A_ls - A
    
    # get initial max abs eigenvalue
    eig_max = utilities.get_max_abs_eigval(A_new, is_symmetric=False)
    
    while eig_max <= 1 and utilities.adjusted_frobenius_norm(X=A_new - A_ls) > 0.01:
        e_t += delta
        A_new = A + e_t * grad
        eig_max = utilities.get_max_abs_eigval(A_new, is_symmetric=False)
    
    if e_t != e_0:
        A = A + (e_t - delta) * grad
    
    return A


def learn_stable_soc(X,Y, **kwargs):

    """
    NOTE: Error about termination conditions
    """
    
    time_limit = kwargs.get('time_limit', 1800)
    alpha = kwargs.get('alpha', 0.5)
    step_size_factor = kwargs.get('step_size_factor', 5)
    fgm_max_iter = kwargs.get('fgm_max_iter', 20)
    conjugate_gradient = kwargs.get('conjugate_gradient', False)
    log_memory = kwargs.get('log_memory', True)
    eps = kwargs.get('eps', 1e-12)


    e100 = [None] * 100
    
    A_ls = Y @ numpy.linalg.pinv(X) 
    nA2 = utilities.adjusted_frobenius_norm(X=Y - A_ls @ X)
    e_old, S, O, C = initialize_soc(X,Y, **kwargs)

    Ys, Yo, Yc = S, O, C
    
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
        On = Yo - O_grad * step
        Cn = Yc - C_grad * step
        
        Sn, On, Cn = soc.project_to_feasible(Sn, On, Cn, **kwargs)
        
        Sn_inv = numpy.linalg.inv(a=Sn)
        e_new = utilities.adjusted_frobenius_norm(
            X=Y - (Sn_inv @ On @ Cn @ Sn) @ X)

        while e_new > e_old and inneriter <= fgm_max_iter:
            
            Sn = Ys - S_grad * step
            On = Yo - O_grad * step
            Cn = Yc - C_grad * step
            
            Sn, On, Cn = soc.project_to_feasible(Sn, On, Cn, **kwargs)
        
            Sn_inv = numpy.linalg.inv(a=Sn)
            e_new = utilities.adjusted_frobenius_norm(
                X=Y - (Sn_inv @ On @ Cn @ Sn) @ X)

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
            step /= step_size_factor
            inneriter += 1
        
        
        alpha = (numpy.sqrt(alpha_prev**4 + 4*alpha_prev**2) - alpha_prev**2)/2
        beta = alpha_prev * (1 - alpha_prev) / (alpha_prev**2 + alpha)
        
        if e_new > e_old:
            if restart_i:
                restart_i = False
                alpha = kwargs.get('alpha', 0.5)
                Ys, Yo, Yc, e_new = S, O, C, e_old
            else:
                break
        else:
            restart_i = True
            if conjugate_gradient:
                beta = 0
            Ys = Sn + beta * (Sn - S)
            Yo = On + beta * (On - O)
            Yc = Cn + beta * (Cn - C)
            
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

    return A, mem







def refine_soc_inputs_solution(X, Y, U, B, S, O, C, **kwargs):
    """
    DEBUG
    - `e_0` and `delta` must become command-line arguments
    """
    
    e_0 = kwargs.get('e_0', 0.00001)
    delta = kwargs.get('delta', 0.00001)
    
    
    e_t = e_0
    S_inv = numpy.linalg.inv(a=S)
    A = S_inv @ O @ C @ S  
    n = len(A)

    XU = numpy.concatenate((X, U), axis=0)
    AB_ls = Y @ numpy.linalg.pinv(XU)

    A_B = numpy.concatenate((A, B), axis=1)
    grad = AB_ls - A_B

    AB_new = A_B + e_t * grad
    A_new = AB_new[:n,:n]
    
    # get initial max abs eigenvalue
    eig_max = utilities.get_max_abs_eigval(A_new, is_symmetric=False)
    
    while eig_max < 1 and utilities.adjusted_frobenius_norm(X=AB_new - AB_ls) > 0.01:
        e_t += delta
        AB_new = A_B + e_t * grad
        A_new = AB_new[:n,:n]
        eig_max = utilities.get_max_abs_eigval(A_new, is_symmetric=False)
    
    if e_t != e_0:
        A_Btemp = A_B + (e_t - delta) * grad
        A = A_Btemp[:n,:n]
        B = A_Btemp[:n,n:]
    
    return A, B


def initialize_soc_with_inputs(X,Y, U,**kwargs):
    """
    DEBUG
    """

    stability_relaxation = kwargs.get('stability_relaxation', 0)

    n = len(X)
    S = numpy.identity(n)
    S_inv = S
    XU = numpy.concatenate((X, U), axis=0)
    AB_ls = Y @ numpy.linalg.pinv(XU)

    O,C = scipy.linalg.polar(a=AB_ls[:n,:n], side='right')
    eig_max = utilities.get_max_abs_eigval(S_inv @ O @ C @ S, is_symmetric=False)
    B = AB_ls[:n,n:]
    
    if eig_max > 1 - stability_relaxation:
        C = utilities.project_psd(Q=C, eps=0, delta=1-stability_relaxation)
        e_old = utilities.adjusted_frobenius_norm(
            X=Y - (S_inv @ O @ C @ S) @ X - B @ U)
    else:
        e_old = utilities.adjusted_frobenius_norm(X=Y - AB_ls @ XU) 
    
    eig_max = max(1, eig_max)
    A_stab = AB_ls[:n,:n] / eig_max
    _,S_,O_,C_ = soc.checkdstable(
        A=0.9999*A_stab, 
        stab_relax=stability_relaxation)
    S_inv_ = numpy.linalg.inv(a=S_)
    
    e_temp = utilities.adjusted_frobenius_norm(
        X=Y - (S_inv_ @ O_ @ C_ @ S_) @ X - B @ U)
    if e_temp < e_old:
        S, O, C = S_, O_, C_
        e_old = e_temp
    
    return e_old, S, O, C, B



def learn_stable_soc_with_inputs(X,Y, U, **kwargs):
    """
    DEBUG:
    - Make sure we test this for different dimensions of X and U
    """

    time_limit = kwargs.get('time_limit', 1800)
    alpha = kwargs.get('alpha', 0.5)
    step_size_factor = kwargs.get('step_size_factor', 5)
    fgm_max_iter = kwargs.get('fgm_max_iter', 20)
    conjugate_gradient = kwargs.get('conjugate_gradient', False)
    log_memory = kwargs.get('log_memory', True)
    eps = kwargs.get('eps', 1e-12)


    e100 = [None] * 100
    
    XU = numpy.concatenate((X, U), axis=0)
    AB_ls = Y @ numpy.linalg.pinv(XU)
    nA2 = utilities.adjusted_frobenius_norm(X=Y - AB_ls @ XU)
    e_old, S, O, C, B = initialize_soc_with_inputs(X,Y, U,**kwargs)


    Ys, Yo, Yc, Yb = S, O, C, B
    
    i = 1
    restart_i = True
    t_0 = time.time()
    while i:
        t_n = time.time()
        if t_n - t_0 > 1800:
            break
        alpha_prev = alpha

        S_grad, O_grad, C_grad, B_grad = soc.get_gradients_with_inputs(X, Y, B, S, O, C)
        
        step = kwargs.get('step', 100)
        inneriter = 1
        
        Sn = Ys - S_grad * step
        On = Yo - O_grad * step
        Cn = Yc - C_grad * step
        Bn = Yb - B_grad * step
        
        Sn, On, Cn = soc.project_to_feasible(Sn, On, Cn, avoid_unstable=True, **kwargs)
        
        Sn_inv = numpy.linalg.inv(a=Sn)
        e_new = utilities.adjusted_frobenius_norm(
            X=Y - (Sn_inv @ On @ Cn @ Sn) @ X - Bn @ U)


        while e_new > e_old and inneriter <= fgm_max_iter:
            
            Sn = Ys - S_grad * step
            On = Yo - O_grad * step
            Cn = Yc - C_grad * step
            Bn = Yb - B_grad * step
            
            Sn, On, Cn = soc.project_to_feasible(Sn, On, Cn, avoid_unstable=True, **kwargs)
        
            Sn_inv = numpy.linalg.inv(a=Sn)
            e_new = utilities.adjusted_frobenius_norm(
                X=Y - (Sn_inv @ On @ Cn @ Sn) @ X - Bn @ U)

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
            step /= step_size_factor
            inneriter += 1

        alpha = (numpy.sqrt(alpha_prev**4 + 4*alpha_prev**2) - alpha_prev**2)/2
        beta = alpha_prev * (1 - alpha_prev) / (alpha_prev**2 + alpha)
        
        if e_new > e_old:
            if restart_i:
                restart_i = False
                alpha = kwargs.get('alpha', 0.5)
                Ys, Yo, Yc, Yb, e_new = S, O, C, B, e_old
            else:
                e_new = e_old
                break
        else:
            restart_i = True
            if conjugate_gradient:
                beta = 0
            Ys = Sn + beta * (Sn - S)
            Yo = On + beta * (On - O)
            Yc = Cn + beta * (Cn - C)
            Yb = Bn + beta * (Bn - B)
            
            S, O, C, B = Sn, On, Cn, Bn
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


    # refine solutions
    A, B= refine_soc_inputs_solution(X, Y, U, B, S, O, C, **kwargs)
    
    # record memory usage
    mem = None
    if log_memory:
        object_mems = [value.nbytes for _, value in locals().items() if isinstance(value, numpy.ndarray)]
        mbs_used = sum(object_mems)/1e6
        mem = round(mbs_used, 3)

    return A, B, mem