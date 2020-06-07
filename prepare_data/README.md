# Data Preparation

In this page we show how to prepare the data in the format necessary for running our algorithms. The code has been tested in `Python 3.7.5`.


## Requirements
```
opencv-python==4.2.0
Pillow==7.1.1
scipy==1.4.1
numpy==1.18.0
```
You may need to install an `ffmpeg` [package](https://ffmpeg.org/) in order to be able to run `opencvpython`.

## Prepare data from `.mat` format

The UCLA and UCSD benchmark datasets that we use come in `.mat` format. To break-up the dataset into individual frame sequences, use the command:

```
python convert_mat_to_sequences.py
	--data /path/to/dataset.mat
	--save_dir /dir/to/save/results/
```

The `--data` command line argument expects the path to the `.mat` containing the raw UCLA or UCSD dataset, and `--save_dir` is the directory in which you want to save the results (it will be created if it does not exist).

## Prepare data from video files

The DynTex benchmark dataset that we used comes in `.avi` files, therefore we need to first convert them to sequences of frames (in `.jpg` format) and then convert the frames to `.mat` sequences as our algorithms necessitate.

### Convert video file to `.jpg` frames

To convert a video file to a sequence of frames, run the following command:

```
python convert_video_to_jpg.py 
	--video_dir /path/to/dir/containing/avi/files/
	--id_list /path/to/id_file
	--save_dir /dir/to/save/results/
```

The command line arguments are the following:
* `video_dir`: directory containing video files to be converted
* `id_list`: (optional) list of names of video files to be used, in case we don't need all videos in `video_dir`
* `save_dir`: directory in which to save directories containing image sequences

**NOTE**: This has been tested for `.avi` and `.mp4` video encodings only.

### Convert sequence of `.jpg` images to `.mat` sequences

To convert a directory containing frame sequences to a `.mat` sequence, we run:

```
python convert_img_to_sequences.py 
	--img_dir /path/to/dir/containing/dirs/containing/frame_sequences/
	--resize_dim 0
	--save_dir /dir/to/save/results/
```

The command line arguments are the following:
* `img_dir`: directory containing directories that contain image sequences
* `resize_dim`: (optional) if downsampling, size of maximum dimension
* `save_dir`: directory in which to save results

Note that this command will also save a `id_mapper.txt` file in `save_dir`, which maps the number of the `.mat` sequence to the ID of the original video file from which it was created.

**NOTE**: We assume that in each of the diretories of `img_dir`, the names of contained `.jpg` files are ordered in such a fashion that the alphabetically first filename corresponds to the first frame that we captured from the original video. If using the `convert_video_to_jpg.py` to convert the video to frames, this will be taken care for you.