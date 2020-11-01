import argparse
import random
import time
import json
import os

import numpy

import utilities

import engine

def parse_args():
    parser = argparse.ArgumentParser(
        description='Learn state-transition matrix using SOC method.')

    # i/o arguments
    parser.add_argument(
        '--data', 
        type=str, 
        required=True,
        help='path to file containing training data')
    parser.add_argument(
        '--save_dir', 
        type=str, 
        required=True,
        help='directory in which to store results')

    # training arguments
    parser.add_argument(
        '--subspace_dim', 
        type=int, 
        required=True,
        help='embedding dimension for state-transition matrix')
    parser.add_argument(
        '--eps', 
        type=float, 
        default=10e-11,
        help='epsilon threshold for deciding stability')
    parser.add_argument(
        '--time_limit', 
        type=int, 
        default=1800,
        help='time duration (in sec) after which to terminate program')

    # logging arguments
    parser.add_argument(
        '--log_memory', 
        action='store_true',
        help='whether to record memory required by objects')
    parser.add_argument(
        '--store_matrices', 
        action='store_true',
        help='whether to record memory required by objects')

    # reproducibility arguments
    parser.add_argument(
        '--seed', 
        type=int, 
        required=True,
        help='seed for random number generator; for reproducibility')

    args = parser.parse_args()
    return args


def main():
    # parse command line arguments
    args = parse_args()

    # add trailing / to input and output directories if necessary
    if not args.save_dir.endswith('/'):
        args.save_dir += '/'
    args.save_dir += str(args.subspace_dim) + '/'

    # make target directory if it does not exist
    os.makedirs(args.save_dir, exist_ok=True)

    # get sequence name
    seq_name = args.data.split('/')[-1].split('.')[0]

    # set random seeds
    random.seed(args.seed)
    numpy.random.seed(args.seed)

    # read data
    data = numpy.load(args.data)

    # get algorithm parameters
    params = {
        'log_memory' : args.log_memory,
        'time_limit' : args.time_limit,
        'subspace_dim' : args.subspace_dim,
        'eps' : args.eps
    }

    # prepare relevant matrices
    if data.T.shape[1] < data.T.shape[0]:
        V,S,UH  = numpy.linalg.svd(data.T)
        U = UH.T.conj() 
    else:
        U,S,VH = numpy.linalg.svd(data)
        V = VH.T.conj() 
    S = numpy.diag(S)

    V = V[:,:args.subspace_dim]
    S = S[:args.subspace_dim,:args.subspace_dim]
    U = U[:,:args.subspace_dim]
    M = S @ V.T
    
    X, Y = M[:,:-1], M[:,1:]

    # learn SOC model
    t_0 = time.time()
    A, mem = engine.learn_stable_soc(X=X, Y=Y, **params)
    t_1 = time.time()
    
    # compute least-squares error
    A_ls = Y @ numpy.linalg.pinv(X)
    ls_error = utilities.adjusted_frobenius_norm(
        X=Y - A_ls @ X)

    # check if LS solution is stable
    ls_max_eig = utilities.get_max_abs_eigval(X=A_ls)

    # compute frobenius norm reconstruction error
    soc_error = numpy.nan
    if utilities.get_max_abs_eigval(A) <= 1 + args.eps:
        soc_error = utilities.adjusted_frobenius_norm(X=Y - A @ X)

    # compute percentage error
    perc_error = 100*(soc_error - ls_error)/ls_error

    # store results
    results = {
        'time' : t_1 - t_0,
        'err' : perc_error,
        'mem' : mem,
        'ls_max_eig' : ls_max_eig
    }
    with open(f'{args.save_dir}{seq_name}_results.json', 'w') as f:
        json.dump(results, f)

    # optionally store matrices for study/reconstruction
    if args.store_matrices:
        matrices = {
            'A' : A,
            'U' : U,
            'X_0' : X[:,0]
        }

        numpy.savez(
            file=f'{args.save_dir}{seq_name}_matrices.npz',
            **matrices)

if __name__ == '__main__':
	main()