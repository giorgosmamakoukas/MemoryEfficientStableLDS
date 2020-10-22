import typing

import numpy

def get_max_abs_eigval(
    X: numpy.ndarray, 
    is_symmetric: bool = False) -> float:
    """
    Get maximum value of the absolute eigenvalues of
    a matrix X. Returns `numpy.inf` if the eigenvalue
    computation does not converge. X does not have to 
    be symmetric.
    """
    eigval_operator = numpy.linalg.eigvalsh if is_symmetric else numpy.linalg.eigvals
    try: 
        eig_max = max(abs(eigval_operator(X)))
    except:
        eig_max = numpy.inf
        
    return eig_max

def adjusted_frobenius_norm(X: numpy.ndarray) -> float:
    """
    Compute the square of the Frobenius norm of a matrix
    and divide the result by 2.
    """
    return numpy.linalg.norm(X)**2/2

def get_numpy_memory_usage():
    """
    Computes memory used by NumPy arrays at call time. Fetches
    the size (in bytes) of all objects of type numpy.ndarray
    stored in `globals()`, sums their sizes and converts to MBs.
    """
    object_mems = [value.nbytes for _, value in globals().items() if isinstance(value, numpy.ndarray)]
    mbs_used = sum(object_mems)/1e6
    return round(mbs_used, 3)

def project_invertible(M, eps):
    """
    DEBUG
    """
    S,V,D = numpy.linalg.svd(M)
    if numpy.min(V) < eps:
        M = S @ numpy.diag(numpy.maximum(numpy.diag(V), eps)) @ D.T
    return M

def project_psd(
    Q: numpy.ndarray, 
    eps: float = 0, 
    delta: float = numpy.inf) -> numpy.ndarray:
    """
    DEBUG
    """
    Q = (Q + Q.T)/2
    E,V = numpy.linalg.eig(a=Q)
    E_diag = numpy.diag(v=numpy.minimum(delta, numpy.maximum(E, eps)))
    Q_psd = V @ E_diag @ V.T
    return Q_psd