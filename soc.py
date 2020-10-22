import typing

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
    N_ = (X @ Y.T - X @ X.T @ M_.T) @ S_inv
    
    S_grad = (N_ @ O @ C - M_ @ N_).T
    O_grad = (C @ S @ N_).T
    C_grad = (S @ N_ @ O).T
    
    return S_grad, O_grad, C_grad

def checkdstable(A : numpy.ndarray) -> typing.Tuple[numpy.ndarray, ...]:
    P = scipy.linalg.solve_discrete_lyapunov(a=A.T, q=numpy.identity(len(A)))
    S = scipy.linalg.sqrtm(A=P)
    S_inv = numpy.linalg.inv(a=S)
    OC = S @ A @ S_inv
    O,C = scipy.linalg.polar(a=OC, side='right')
    C = project_psd(C, 0, 1)
    return P, S, O, C

def project_to_feasible(
	S: numpy.ndarray, 
	O: numpy.ndarray, 
	C: numpy.ndarray, 
	**kwargs) -> typing.Tuple[numpy.ndarray, ...]:
	"""
	Brief explanation
	"""

    eps = kwargs.get('eps', 0)
    
    S = utilities.project_invertible(M=S, eps=eps)
    eig_max = utilities.get_max_abs_eigval(O @ C)
    if eig_max > 1:
        O = scipy.linalg.polar(a=O, side='right')
        C = utilities.project_psd(C, 0, 1)
    return S, O, C