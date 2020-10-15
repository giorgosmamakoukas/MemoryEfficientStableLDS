# Obtaining datasets

# UCLA dataset
The UCLA dataset can be obtained from this [link](https://drive.google.com/file/d/0BxMIVlhgRmcbN3pRa0dyaHpHV1E/view?usp=sharing). We use the file `ucla_patches.mat` to extract the frame sequences.

# UCSD dataset
To obtain the UCSD dataset that was used in the paper, you can visit the relevant [page](http://www.svcl.ucsd.edu/projects/traffic/) of the Statistical Visual Computing Lab at UCSD or download it directly from [here](http://www.svcl.ucsd.edu/projects/traffic/db/trafficdb.tgz). We use the file named `traffic_patches_reg.mat` to extract the frame sequences.

# DynTex dataset
To obtain the subset of the DynTex dataset that was used in our experiments, visit the Download section of the main DynTex project [page](http://dyntex.univ-lr.fr/index.html). You will need to register to in order to obtain credentials that will allow you to access the FTP server that hosts the dataset. In our case, it took less than 10 minutes for the maintainers to send us access credentials from the moment we completed our registration. 

If you have `wget` already installed in your machine, you can use the `get_dyntex.sh` script to download the DynTex subset that we used. In particular, running

```
bash get_dyntex.sh /path/to/store/downloaded/videos/ DynTex_IDs.txt
```
`DynTex_IDs.txt` contains the names of the video files that we used in our experiments (without the `.avi` extension). `/path/to/store/downloaded/videos/` will be the local directory in which you wish to store the downloaded `.avi` videos, which will be created in case it does not already exist. Once you run the above command, you will be prompted to provide the username and password that you obtained with the registration process and the downloading process will begin.


If you are using a MacOS, you will most likely need to install `wget` prior to executing the above commands. If you are using `Homebrew` as your package manager, you can easily install `wget` with

```
brew install wget
```