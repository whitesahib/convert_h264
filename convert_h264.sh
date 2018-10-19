#!/bin/bash

# Convert video to h264 v 4.0.5a
# Created by White Sahib, 2018

# with auto-detecting bitrate / +N/A bit_rate / + multiple extenstions
# good parsing of '.' in filenames
# 3.8 bugfix for 'N/A N/A'
# 3.9 init rate depends on video height 
# 3.9.1 height and +width
# 3.9.2 fix ffmpeg issue -max_muxing_queue_size
# 3.9.3 +preset from command line (slow - default)
# 3.9.4 change init rate (-rate <value>)
# 3.9.5a use format:bit_rate
# 3.9.6a au_bitrate=0
# 3.9.7 +full_hd_rate
# 3.9.8 +overwrite option (-y) 
# 3.9.9 bugfix (double height/width in .ts files)
# 4.0 -copy (copy video, aac audio)
# 4.0.1 autodeterminate codec_name
# 4.0.2 -force_recode
# 4.0.3 bugfix (if statement for copy or recoding)
# 4.0.4 bugfix (if file exists statement)
# 4.0.5 update (if h264 and low rate then dont recode)

echo "Convert video v 4.0.5a 18-10-2018";

just_copy=0;
copy=0
force_recode=0;
default=1500;
ex_map="";
preset="slow"
audio_codec="aac";
audio_bitrate="128k";

au_bitrate=0;

declare -i original_bitrate=0;
declare original_bitrate_k=0;
declare -i init_rate=$default;
declare -i hd_rate=2500;
declare -i full_hd_rate=4000;
declare -i low_rate=700;
declare -i buf=0;
declare name;
buf=$((init_rate*2));

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

if [[ "$1" == "-preset" ]]; then
  preset="$2";
#  if [[ "$3" == '-exclude' ]]; then
#    ex_map="-map -$4";
#  else
#    ex_map="";
#  fi

  if [[ "$3" == "-rate" ]]; then
   default=$4;
  fi
fi

for j in $@;
  do
#       echo $j;
       if [[ "$j" == "-recode" ]]; then
            force_recode=1;
       elif [[ "$j" == "-copy" ]]; then
            copy=1;
       fi
  done


for i in $(cat list.txt);
  do 
  init_rate=$default;
  fullpathname=$i;
  echo $fullpathname;

  name="${fullpathname##*/}";
  name="${name%.*}";
  echo $name;

  if [ -f "$fullpathname" ]; then

  test=`ffprobe -show_entries format=bit_rate -of default=noprint_wrappers=1 -hide_banner -i "$i" 2> /dev/null | sed 's/bit_rate=*//g'| sed 'q'`;
  height=`ffprobe "$i"  -select_streams v:0 -show_entries stream=,height -of default=noprint_wrappers=1 -hide_banner 2> /dev/null | sed 's/height=*//g'| sed 'q'`;
  width=`ffprobe "$i"  -select_streams v:0 -show_entries stream=,width -of default=noprint_wrappers=1 -hide_banner 2> /dev/null | sed 's/width=*//g'| sed 'q'`;
  echo "$width"x"$height";

  codec=`ffprobe -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1 -hide_banner -i "$i" 2> /dev/null | sed 's/codec_name=*//g'| sed 'q'`;
  echo $codec;

  if [ "$height" -gt 719 ]; then
      init_rate=$hd_rate;
  fi

  if [ "$height" -gt 1079 ]; then
      init_rate=$full_hd_rate;
  fi

  if [ "$width" -gt 1200 ]; then
      init_rate=$hd_rate;
  elif [ "$width" -lt 321 ]; then
      init_rate=$low_rate;
  fi

  if [ "$width" -gt 1917 ]; then
      init_rate=$full_hd_rate;
  fi

  if [[ "$test" == *"N/A"* ]]; then
     echo "Can't find bit_rate, falling to default init";
     original_bitrate_k=$init_rate;
  else
     original_bitrate=`ffprobe -show_entries format=bit_rate -of default=noprint_wrappers=1 -hide_banner -i "$i" 2> /dev/null | sed 's/.*bit_rate=\([0-9]\+\).*/\1/g'`;
     original_bitrate_k=$(bc <<< "scale=0;$original_bitrate/1024+$au_bitrate")
  fi
     echo 'Original bitrate:'$original_bitrate_k;

  if (($original_bitrate_k < ${init_rate} )); then
     rate=$original_bitrate_k;
    else
     rate=$init_rate;
  fi

  echo 'Encoding rate:'$rate;

  if [ "$copy" -eq 1 ] || [ $codec == "h264" ] && [ "$force_recode" -eq 0 ]; then
    just_copy=1;
  elif [ $codec == "h264" ] && [ $rate == $original_bitrate_k ]; then
    just_copy=1;
  else
    just_copy=0;
  fi

  if [ $just_copy -eq 1 ]; then
    echo "Copying video stream..";
    ffmpeg -loglevel quiet -hide_banner -y -i "$i" -map 0 -map_metadata 0 -metadata title="$name" -c:v copy -c:a $audio_codec -c:s mov_text -threads 4 -movflags +faststart -max_muxing_queue_size 1024 "${fullpathname%.*}.mp4";
  else
    ffmpeg -loglevel quiet -hide_banner -y -i "$i" -map 0 -map_metadata 0 -metadata title="$name" -c:v libx264 -profile:v high -preset $preset -tune fastdecode -qmin 16 -crf 19 -maxrate ${rate}k -bufsize ${buf}k -c:a $audio_codec -c:s mov_text -threads 4 -movflags +faststart  -async 1 -vsync 1 -max_muxing_queue_size 1024 "${fullpathname%.*}.mp4";
  fi

  fi  # -- if file exists
done

IFS=$SAVEIFS
