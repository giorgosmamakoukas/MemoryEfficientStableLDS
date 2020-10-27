import argparse
import os

import numpy 
import PIL.Image


def parse_args():
    parser = argparse.ArgumentParser(
        description='Convert .jpg frames to .npy sequences.')

    # i/o arguments
    parser.add_argument(
        '--img_dir', 
        type=str, 
        required=True,
        help='directory containing frame sequence directories')
    parser.add_argument(
        '--resize_dim', 
        type=int, 
        default=48,
        help='if downsampling, size of maximum dimension')
    parser.add_argument(
        '--save_dir', 
        type=str, 
        required=True,
        help='directory in which to save output .jpg frames')

    args = parser.parse_args()
    return args

def main():

    # parse arguments
    args = parse_args()

    # add trailing / to input and output directories if necessary
    if not args.img_dir.endswith('/'):
        args.img_dir += '/'
    if not args.save_dir.endswith('/'):
        args.save_dir += '/'

    # make target directory if it does not exist
    os.makedirs(args.save_dir, exist_ok=True)

    # get frame sequence directories
    img_sequence_dirs = sorted([d for d in os.listdir(args.img_dir) if os.path.isdir(args.img_dir + d)])

    for i, d in enumerate(img_sequence_dirs):
        img_sequence = []

        # get frame sequence img files
        files = sorted(os.listdir(args.img_dir + d))

        for f in files:
            # read frame
            image = PIL.Image.open(args.img_dir + d + '/' + f).convert('L')
            
            # optionally resize frame
            if args.resize_dim:
                image.thumbnail((args.resize_dim, args.resize_dim))
            
            # convert PIL.Image to numpy.ndarray
            array = numpy.asarray(image)/255
            img_sequence.append(array)

        img_sequence = numpy.array(img_sequence)
        
        # reshape image sequences
        t, y, x = img_sequence.shape
        img_sequence_feat = numpy.reshape(
            a=img_sequence,
            newshape=(t, y * x), 
            order='C').T

        # save data to disk
        numpy.save(
            file=f'{args.save_dir}seq_{i}.npy',
            arr=img_sequence_feat)

        # save id mapper
        with open(args.save_dir + 'id_mapper.txt', 'a') as f:
            row = str(i) + '\t' + str(d) + '\n'
            f.write(row)

if __name__ == '__main__':
    main()