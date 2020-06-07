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
        required=True,
        help='extension of video files')
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
    args = parse_args()

    # get list of videos to process
    dataset_id = []
    if args.id_list:
        with open(args.id_list, 'r') as f:
            for line in f:
                line=line.strip()
                dataset_id.append(line)

    for vid in os.listdir(args.video_dir):
        if vid.endswith(args.video_ext) and vid.split('.')[0] in dataset_id:

            # capture video
            cap = cv2.VideoCapture(f'{args.video_dir}{vid}')
            cap.set(cv2.CAP_PROP_FPS, 60)
            
            # get video name without extension
            vid = vid.split('.')[0]
            
            try:
                if not os.path.exists(f'{args.save_dir}{vid}'):
                    os.makedirs(f'{args.save_dir}{vid}')
            except OSError:
                print ('Error: Creating directory of data')

            # main routine: capture frames
            currentFrame = 0
            while(True):
                _, frame = cap.read()

                if frame is None:
                    break

                # save current frame as .jpg
                name = f'{args.save_dir}{vid}/frame_' + str(currentFrame).zfill(5) + '.jpg'
                cv2.imwrite(name, frame)

                # move to next frame
                currentFrame += 1

            # release video
            cap.release()
            cv2.destroyAllWindows()

if __name__ == '__main__':
    main()