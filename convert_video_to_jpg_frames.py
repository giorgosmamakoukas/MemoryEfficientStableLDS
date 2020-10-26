import argparse
import os

import cv2

def parse_args():
    parser = argparse.ArgumentParser(
        description='Extract .jpg frames from video files.')

    # i/o arguments
    parser.add_argument(
        '--video_dir', 
        type=str, 
        required=True,
        help='directory containing video files')
    parser.add_argument(
        '--video_ext', 
        type=str, 
        default='avi',
        help='extension of video files')
    parser.add_argument(
        '--fps', 
        type=int, 
        default=60,
        help='frame rate to use for capturing jpg from video')
    parser.add_argument(
        '--zero_pad', 
        type=int, 
        default=10,
        help='number of zeros for padding jpg sequence number with')
    parser.add_argument(
        '--id_list', 
        type=str, 
        default='',
        help='file containing filenames (without extension) of video files to process')
    parser.add_argument(
        '--save_dir', 
        type=str, 
        required=True,
        help='directory in which to save output .jpg frames')

    args = parser.parse_args()
    return args

def main():

    # parse commang line arguments
    args = parse_args()

    # get list of video IDs to process
    dataset_id = []
    if args.id_list:
        with open(args.id_list, 'r') as f:
            for line in f:
                line=line.strip()
                dataset_id.append(line)
    else:
        for vid in os.listdir(args.video_dir):
            dataset_id.append(vid.split('.')[0])

    # add trailing / to output directory if necessary
    if not args.save_dir.endswith('/'):
        args.save_dir += '/'

    # main routine: 
    for vid in os.listdir(args.video_dir):
        
        # get video name without extension
        vid_id = vid.split('.')[0]
        
        if vid.endswith(args.video_ext) and vid_id in dataset_id:

            # capture video and set camera frame rate
            cap = cv2.VideoCapture(f'{args.video_dir}{vid}')
            cap.set(cv2.CAP_PROP_FPS, args.fps)

            # create output directory if it does not exist
            os.makedirs(f'{args.save_dir}{vid_id}', exist_ok=True)

            # capture frames
            currentFrame = 0
            while(True):
                _, frame = cap.read()

                if frame is None:
                    break

                # save current frame as .jpg
                padded_idx = str(currentFrame).zfill(args.zero_pad)
                name = f'{args.save_dir}{vid_id}/frame_{padded_idx}.jpg'
                cv2.imwrite(name, frame)

                # move to next frame
                currentFrame += 1

            # release video
            cap.release()
            cv2.destroyAllWindows()

if __name__ == '__main__':
    main()