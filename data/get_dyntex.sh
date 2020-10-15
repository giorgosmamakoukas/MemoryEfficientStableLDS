#!/bin/bash

# positional arguments for download directory and path to .txt file containing 
# names of files to be downloaded from FTP server 
OUT_DIR=$1
ID_FILE=$2

# request username and password for FTP server access
echo "Provide your DynTex FTP server username:"
read -s USER
echo "Provide your DynTex FTP server password:"
read -s PASS

# create download directory if it does not already exist
mkdir -p $OUT_DIR

# loop over file names and download
cat $ID_FILE | while read f;
do 
	wget ftp://$USER:$PASS@trust.univ-lr.fr/DynTex/Videos/pr1/$f.avi -P $OUT_DIR
done