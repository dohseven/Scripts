#!/bin/sh
# Cronjob script for finding subtitles with Subliminal
#
# Author: J. van Emden (Brickman)
# Latest version: http://synology.brickman.nl
#
# Location: /volume1/@appstore/scripts
#
# Version:
# 2012-05-18:
# - Age can be set through command line
#
# 2012-03-30:
# - Initial release
#

AGE=$2                                      # Age to search for
PATH_TO_TV=$1                               # Path or file to search

# Directory where to store the log file
LOG_DIR="/volume1/documents/logs/subliminal";

##########################################
##########################################
## Do not edit after this line!         ##
##########################################
##########################################

# Subliminal only folder
SUBLI_LOG_DIR="${LOG_DIR}";
#LOG_TIME=$(date +%Y_%m_%d_%H_%M);
LOG_TIME=$(date +%Y_%m_%d);
[ -n "$2" ] && SUBLI_LOG_FILE="${SUBLI_LOG_DIR}/findTV_${AGE}_${LOG_TIME}.log" || SUBLI_LOG_FILE="${SUBLI_LOG_DIR}/findTV_old_${LOG_TIME}.log"

if [ ! -d $SUBLI_LOG_DIR ]; then
    mkdir -p $SUBLI_LOG_DIR
fi

sh $(dirname $0)/subli_findTV.sh "$PATH_TO_TV" $AGE >> $SUBLI_LOG_FILE 2>&1
