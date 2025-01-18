folder=.
#filename="Персидские мотивы Персеполь.mp4"
filenameshape="*.mp4"
playlistname=playlist.txt

touch $playlistname
#ls $folder --format=single-column>playlist.txt

#ffmpeg -hide_banner -i "$folder/$filename" 2>&1 | grep Duration | cut -d ',' -f1

#ffprobe -i "$folder/$filename" -hide_banner -v error -show_format -show_entries format=duration -of flat

#ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$folder/$filename"

#eto
#mediainfo --Output="General;%Duration%" "$folder/$filename"

#eto
#find $folder -maxdepth 1 -type f -print0 | xargs -0 ls --format=single-column


for file in $filenameshape
do
#  ls "$file">>$playlistname
  shortenfilename=$( sed s/"mp4"/""/ <<< "$file") ; echo $shortenfilename>>$playlistname
  mediainfo --Output="General;%Duration%" "$file">>$playlistname

done
