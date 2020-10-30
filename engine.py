import typing

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


def learn_stable_soc(X,Y, **kwargs):
    
    time_limit = kwargs.get('time_limit', 1800)
    alpha = kwargs.get('alpha', 0.5)
    lsitermax = kwargs.get('lsitermax', 20)
    gradient = kwargs.get('gradient', False)
    log_memory = kwargs.get('log_memory', False)
    
    # add initialization method here
    e_old, S, O, C = initialize_soc(X,Y)

    print(e_old)

    A, mem = numpy.identity(X.shape[0]), numpy.nan
    return A, mem