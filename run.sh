#!/bin/bash
#
# Convert a zip archive of time-lapse photos from Imgur into a video
#

# abort on undefined variable
set -u

# abort on non-zero exit code
set -e

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename $0) archive.zip"
    exit 1
fi

ARCHIVE="${1}"

TSTAMP=$(date +%Y%m%d_%H%M%S)
IMGDIR=images-${TSTAMP}
unzip -d "${IMGDIR}" "${ARCHIVE}"

cd $IMGDIR

# Remove filenames that aren't in the expected format
find . -type f ! -name '*.jpg.jpg' -delete

# Remove the extra cruft from the filenames
for x in *.jpg; do echo $x|(read N dash hash dash2 fname; mv "$x" $fname); done

# Remove extra .jpg suffix that Imgur adds when it adds a file to a zip archive
for x in *; do fname=$(echo $x|sed "s/.jpg.jpg/.jpg/"); mv "${x}" "${fname}"; done

# Rename each file to its chonological order, because that's what ffmpeg wants
ls | sort | grep -n . | while IFS=: read N D; do W=$(printf "%6.6d\n" $N); mv "${D}" "${W}.jpg"; done

# Generate the video.  Be patient.
ffmpeg -thread_queue_size 512 -r 24 -pattern_type glob -i '*.jpg' -i "%06d.jpg" -s hd1080 -vcodec libx264 -thread_queue_size 512 "../${TSTAMP}.mp4"
