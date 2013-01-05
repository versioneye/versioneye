#!/bin/bash

TITLE="VersionEye"

command -v gource >/dev/null 2>&1 || { echo >&2 "I require gource but it's not installed. Use: brew install gource . Aborting."; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { 
   echo >&2 "I require ffmpeg but it's not installed. Use: brew install ffmpeg  Aborting."; exit 1; }

gource --title $TITLE --auto-skip-seconds 5 --seconds-per-day 0.5 \
 --viewport 640x480 --hide filenames -o - | \
ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 \
    -preset ultrafast -crf 1 -threads 0 -bf 0 ~/Movies/versioneye.avi 

echo "Movie is now rendered, check your ~/Movies folder"
