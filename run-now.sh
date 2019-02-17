#!/bin/bash

usage() {
	echo "Usage: $(basename $0) {-a|-d|-w|-y|-4}"
	exit 1
}

# abort on undefined variable
set -u

# abort on non-zero exit code
set -e

if [[ $# -ne 1 ]]; then
	usage
fi

if [[ "${1}" == "-a" ]]; then
    TIMERANGE=all
elif [[ "${1}" == "-d" ]]; then
    TIMERANGE=daylight
elif [[ "${1}" == "-w" ]]; then
    TIMERANGE=dawn
elif [[ "${1}" == "-y" ]]; then
    TIMERANGE=daily
elif [[ "${1}" == "-4" ]]; then
    TIMERANGE=4
else
    usage
fi

TSTAMP=$(date +%Y%m%d_%H%M%S)-${TIMERANGE}

[[ -d renamed ]] && rm -rf renamed
mkdir renamed

exclude() {
    # before this date, the images used the wrong aspect ratio
    if [[ "$1" > "2018-10-27_1245.jpg" ]]; then
       return 1
    else
       return 0
    fi
}

# Rename and hardlink each file to its chonological order, because that's what ffmpeg wants
# Hard link because it's less I/O and maybe easier on the SSD
if [[ ${TIMERANGE} == all ]]; then
    (cd now;
     N=1
     ls | sort | grep . | while read D; do 
         if $(exclude $D); then
             continue
         fi
         W=$(printf "%6.6d\n" $N)
         N=$((N+1))
         ln "${D}" ../renamed/"${W}.jpg"
     done)
elif [[ ${TIMERANGE} == daylight ]]; then
    (cd now;
     N=1
     ls | sort | grep . | while read D; do 
        if $(exclude $D); then
            continue
        fi
        T=$(echo $D | cut -d_ -f2 | cut -d. -f1 | sed "s/^[0]*//")
        if [[ ${T} -lt 630 || ${T} -gt 1900 ]]; then
            continue
        fi
        W=$(printf "%6.6d\n" $N)
        N=$((N+1))
        ln "${D}" ../renamed/"${W}.jpg"
     done)
elif [[ ${TIMERANGE} == dawn ]]; then
    (cd now;
     INDEX=1
     ls | sort | grep . | while read D; do 
        if $(exclude $D); then
            continue
        fi
        T=$(echo $D | cut -d_ -f2 | cut -d. -f1 | sed "s/^[0]*//")
        if [[ ${T} -lt 645 || ${T} -gt 715 ]]; then
            continue
        fi
        W=$(printf "%6.6d\n" $INDEX)
        ln "${D}" ../renamed/"${W}.jpg"
        INDEX=$((INDEX+1))
     done)
elif [[ ${TIMERANGE} == daily ]]; then
    (cd now;
     N=1
     ls | sort | grep . | while read D; do 
        if $(exclude $D); then
            continue
        fi
        T=$(echo $D | cut -d_ -f2 | cut -d. -f1 | sed "s/^[0]*//")
        if [[ ${T} != 1200 ]]; then
            continue
        fi
        W=$(printf "%6.6d\n" $N)
        N=$((N+1))
        ln "${D}" ../renamed/"${W}.jpg"
     done)
elif [[ ${TIMERANGE} == 4 ]]; then
    (cd now;
     N=1
     ls | sort | grep . | while read D; do
        if $(exclude $D); then
            continue
        fi
        T=$(echo $D | cut -d_ -f2 | cut -d. -f1 | sed "s/^[0]*//")
        if [[ $T -ne 800 && $T -ne 1100 && $T -ne 1400 && $T -ne 1700 ]]; then
            continue
        fi
        W=$(printf "%6.6d\n" $N)
        N=$((N+1))
        ln "${D}" ../renamed/"${W}.jpg"
     done)

else
    echo "You found a bug: TIMERANGE=${TIMERANGE}"
    exit 1
fi

# Generate the video.  Be patient.
# Setting thread_queue_size > 2048 tends to cause ffmpeg to crash on my 16GB laptop
(cd renamed; 
 ffmpeg -thread_queue_size 2048 -r 48 -pattern_type glob -i '*.jpg' -i "%06d.jpg" -aspect 3:4 -s 1280x1920 -vcodec libx264 "../${TSTAMP}.mp4")
