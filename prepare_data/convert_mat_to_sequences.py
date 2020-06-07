import os
import argparse

import numpy
import scipy.io

def parse_args():
    parser = argparse.ArgumentParser(
        description='Convert .mat datasets to individual frame sequences.')

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
        help='directory in which to save .mat frame sequences')

    args = parser.parse_args()
    return args

def main():
    args = parse_args()

    dataset = scipy.io.loadmat(args.data)['imgdb'][0]

    # make target directory if it does not exist
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
        scipy.io.savemat(
                file_name=f'{args.save_dir}seq_{i}.mat', 
                mdict={'data': img_sequence_feat})

if __name__ == '__main__':
    main()