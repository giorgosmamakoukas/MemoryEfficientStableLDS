import os
import argparse

import numpy
import scipy.io

def parse_args():
    parser = argparse.ArgumentParser(
        description='Convert .mat datasets to individual frame sequences stored as .npy files.')

    # i/o arguments
    parser.add_argument(
        '--data', 
        type=str, 
        required=True,
        help='path to .mat dataset')
    parser.add_argument(
        '--save_dir', 
        type=str, 
        required=True,
        help='directory in which to save .npy frame sequences')

    args = parser.parse_args()
    return args

def main():

    # parse command-line arguments
    args = parse_args()

    # load .mat data
    dataset = scipy.io.loadmat(args.data)['imgdb'][0]

    # make target directory if it does not exist
    if not args.save_dir.endswith('/'):
        args.save_dir += '/'
    os.makedirs(args.save_dir, exist_ok=True)

    for i in range(dataset.shape[0]):
        img_sequence = numpy.asarray(dataset[i])/255
        
        # reshape image sequences 
        x, y, t = dataset[i].shape
        img_sequence_feat = numpy.reshape(
                a=img_sequence,
                newshape=(t, y * x), 
                order='C').T

        # save data to disk
        numpy.save(
            file=f'{args.save_dir}seq_{i}.npy',
            arr=img_sequence_feat)

if __name__ == '__main__':
    main()