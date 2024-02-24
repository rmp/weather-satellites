#!/bin/bash

###############################################
source config.cfg
###############################################

# Create output directories
mkdir -p $output/noaa
mkdir -p $output/noaa/deleted
mkdir -p $output/meteor
mkdir -p $output/meteor/deleted

sat="$1$2"
start=$3
stop=$4
specie=$1
elevation=$5

filename=`date --date=@${start} +%Y%m%d-%H%M%S`_${sat}
rectime=$[$stop-$start]
at_start=`date --date=@${start} +%H:%M`

if [ "$sat" == "NOAA15" ]; then
    frequency=${NOAA15}
    sampling=${NOAA_sampling}
fi
if [ "$sat"  == "NOAA18" ]; then
    frequency=${NOAA18}
    sampling=${NOAA_sampling}
fi
if [ "$sat" == "NOAA19" ]; then
    frequency=${NOAA19}
    sampling=${NOAA_sampling}
fi
if [ "$sat" == "METEOR-M2" ]; then
    frequency=${METEORM2}
    sampling=${METEOR_sampling}
fi
if [ "$sat" == "METEOR-M22" ]; then
    frequency=${METEORM22}
    sampling=${METEOR_sampling}
fi
if [ "$sat" == "METEOR-M23" ]; then
    frequency=${METEORM23}
    sampling=${METEOR_sampling}
fi
if [ "$device" == "" ]; then
	device=0
fi
# Logging:
echo `date --date=@${start} +%Y%m%d-%H%M%S` $sat $elevation >> recordings.log

# Submit satellite:
if [ "$specie" == "NOAA" ]; then
    
    # Record: (-p 0.0, 55.0 ppm ????, added -E dc -A fast)       
    echo "timeout $rectime rtl_fm  -d ${device} -f ${frequency}M -s ${sampling}k -g ${NOAA_gain} -p 0.0 -E wav -E dc -E deemp -F 9 - | sox -t raw -e signed -c 1 -b 16 -r ${sampling}k - ${output}/noaa/${filename}.wav"  > job.txt 

    #echo "timeout $rectime rtl_fm  -d ${device} -f ${frequency}M -s 60k  -g 45 -E wav - | sox -t raw -e signed -c 1 -b 16 -r 60k - ${filename}.wav" # > job.txt
    #echo "timeout $rectime rtl_fm  -d ${device} -f ${frequency}M -s 60k  -g 45 -p 55 -E wav -E deemp -F 9 - | sox -t raw - ${filename}.wav rate 11025" # > job.txt

    # Resample and Decode:
    echo "/bin/bash apt.sh ${output}/noaa/${filename} &>> jobs.log" >> job.txt

    # Submission:
    at $at_start -f job.txt &> /dev/null
    rm job.txt

fi

if [ "$specie" == "METEOR-M" ] || [ "$specie" == "METEOR-M2" ]; then

    # Priority to Meteor's
    echo "pkill -9 rtl_fm" > job.txt

    # Record:
    # (from https://www.reddit.com/r/RTLSDR/comments/abn29d/automatic_meteor_m2_reception_on_linux_using_rtl)
    echo "timeout $rectime rtl_fm -d ${device} -M raw -f ${frequency}M -s ${sampling}k -g ${METEOR_gain} -p 0.0 | sox -t raw -r ${sampling}k -c 2 -b 16 -e s - -t wav ${output}/meteor/${filename}.wav rate 96k" >> job.txt
    
    # Resample and Decode:
    echo "/bin/bash lrpt.sh ${output}/meteor/${filename} &>> jobs.log" >> job.txt

    at $at_start -f job.txt &> /dev/null
    rm job.txt
    
fi
