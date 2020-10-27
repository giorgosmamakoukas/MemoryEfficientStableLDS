import argparse
import random
import time
import json
import os

import numpy

import utilities

# import soc


"""
NOTES:
1. To make the algorithm maximally parallelizable, we will make it so that the training file accepts one dimension and one data matrix at a time and stores the results in a directory corresponding to the particular dimension
2. fix params dict
3. ensure that matrices and transposes are correctly provided as per MATLAB
4. double check command line arguments
"""

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
    params = {}

    # prepare relevant matrices
    U = numpy.identity(10) #### PLACEHOLDERS
    X_0 = numpy.identity(100) #### PLACEHOLDERS

    X = data[:,:-1]
    Y = data[:,1:]

    # learn SOC model
    t_0 = time.time()
    # A, mem = soc.learn_stable_soc(X=X, Y=Y, **params)
    A, mem = numpy.identity(X.shape[0]), numpy.nan
    t_1 = time.time()
    
    # compute least-squares error
    ls_error = utilities.adjusted_frobenius_norm(
        X=Y - Y @ numpy.linalg.pinv(X) @ X)

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
        'mem' : mem
    }
    with open(f'{args.save_dir}{seq_name}_results.json', 'w') as f:
        json.dump(results, f)


    # optionally store matrices for study/reconstruction
    if args.store_matrices:
        matrices = {
            'A' : A,
            'U' : U,
            'X_0' : X_0
        }

        numpy.savez(
            file=f'{args.save_dir}{seq_name}_matrices.npz',
            **matrices)

if __name__ == '__main__':
	main()