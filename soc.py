import typing

import numpy
import scipy.linalg

import utilities

def get_gradients(
    X: numpy.ndarray, 
    Y: numpy.ndarray, 
    S: numpy.ndarray, 
    O: numpy.ndarray, 
    C: numpy.ndarray) -> typing.Tuple[numpy.ndarray, ...]:
    """
    Perform one gradient update step
    """

    S_inv = numpy.linalg.inv(a=S)
    M_ = S_inv @ O @ C @ S  
    N_ = - (X @ Y.T - X @ X.T @ M_.T) @ S_inv
    
    S_grad = (N_ @ O @ C - M_ @ N_).T
    O_grad = (C @ S @ N_).T
    C_grad = (S @ N_ @ O).T
    
    return S_grad, O_grad, C_grad

def get_gradients_with_inputs(
    X: numpy.ndarray, 
    Y: numpy.ndarray, 
    U: numpy.ndarray,
    B: numpy.ndarray,
    S: numpy.ndarray, 
    O: numpy.ndarray, 
    C: numpy.ndarray) -> typing.Tuple[numpy.ndarray, ...]:
    """
    Perform one gradient update step
    """

    S_inv = numpy.linalg.inv(a=S)
    M_ = S_inv @ O @ C @ S 
    N_ = - (X @ Y.T - X @ X.T @ M_.T - X @ U.T @ B.T) @ S_inv
    
    S_grad = (N_ @ O @ C - M_ @ N_).T 
    O_grad = (C @ S @ N_).T 
    C_grad = (S @ N_ @ O).T 

    B_grad = M_ @ X @ U.T + B @ U @ U.T - Y @ U.T
    
    return S_grad, O_grad, C_grad, B_grad

def checkdstable(
    A : numpy.ndarray,
    stab_relax: bool) -> typing.Tuple[numpy.ndarray, ...]:
    
    P = scipy.linalg.solve_discrete_lyapunov(a=A.T, q=numpy.identity(len(A)))
    S = scipy.linalg.sqrtm(A=P)
    S_inv = numpy.linalg.inv(a=S)
    OC = S @ A @ S_inv
    O,C = scipy.linalg.polar(a=OC, side='right')
    C = utilities.project_psd(Q=C, eps=0, delta=1-stab_relax)
    return P, S, O, C

def project_to_feasible(
    S: numpy.ndarray, 
    O: numpy.ndarray, 
    C: numpy.ndarray, 
    avoid_unstable: bool = False,
    **kwargs) -> typing.Tuple[numpy.ndarray, ...]:
    """
    Brief explanation
    """

    eps = kwargs.get('eps', 1e-12)
    stability_relaxation = kwargs.get('stability_relaxation', 0)
    
    S = utilities.project_invertible(M=S, eps=eps)

    matrix = O @ C
    if avoid_unstable:
        S_inv = numpy.linalg.inv(a=S)
        matrix = S_inv @ matrix @ S

    eig_max = utilities.get_max_abs_eigval(matrix, is_symmetric=False)
    if eig_max > 1 - stability_relaxation:
        O, _ = scipy.linalg.polar(a=O, side='right')
        C = utilities.project_psd(Q=C, eps=0, delta=1-stability_relaxation)
    return S, O, C