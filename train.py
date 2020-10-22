import argparse
import random

import numpy

# import soc


"""
NOTES:
1. To make the algorithm maximally parallelizable, we will make it so that the training file accepts one dimension and one data matrix at a time and stores the results in a directory corresponding to the particular dimension
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
        type=int, 
        required=True,
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

    # set random seeds
    random.seed(args.seed)
    numpy.random.seed(args.seed)

    # read data
    data = numpy.load(args.data)

    # get algorithm parameters
    params = {}

    # prepare relevant matrices
    X = data[:,:-1]
    Y = data[:,1:]

    # learn SOC model
    # A, mem = soc.learn_stable_soc(X=X, Y=Y, **params)


    # compute frobenius norm reconstruction error
    # NOTE: make sure we are computing same quantity
    # as in the paper, with ^2/2

    # store results

    # optionally store matrices for study/reconstruction

if __name__ == '__main__':
	main()