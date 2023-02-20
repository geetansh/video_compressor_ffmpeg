#!/bin/bash

# Things to keep in mind
# Video should be less than 30sec and should be a square video for best quality and compression

# check if video file was provided
if [ -z "$1" ]; then
  echo "Please provide a video file as the first argument."
  exit 1
fi

if [ -z "$2" ]; then
  echo "Please provide a Output video file as the second argument."
  exit 1
fi

# get video duration in seconds
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1")
echo "Video duration: $duration seconds"

# check if video is longer than 30 seconds
if (( $(echo "$duration > 30" | bc -l) )); then
  echo "Video is longer than 30 seconds, trimming to 30 seconds."
  ffmpeg -y -i "$1" -ss 00:00:00 -t 00:00:30 -c copy temp.mp4
  input="temp.mp4"
else
  input="$1"
fi

# compress the video with reduced resolution until output size is below 600KB
scale=480
while true; do
  ffmpeg -y -i "$input" -vf "scale=$scale:-2" -c:v libx264 -preset medium -crf 28 -c:a aac -b:a 128k $2
  size=$(wc -c < $2)
  if (( size < 600000 )); then
    break
  else
    scale=$((scale - 20))
    if (( scale < 160 )); then
      echo "Video cannot be compressed to less than 600KB."
      exit 1
    fi
  fi
done

# remove temporary file if it exists
if [ -f "temp.mp4" ]; then
  rm temp.mp4
fi


