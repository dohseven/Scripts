#!/bin/sh
#------------------------------------------
# findsubscript
#
# use this script to search for subtitles
#   subli_findTV2.sh <path> <age>
#       <path> - Directory or file to search
#       <age>  - additional age definition, e.g. 14 for files created 14 days ago
#
# Author: J. van Emden (Brickman)
# Latest version: http://synology.brickman.nl
#
# Location: /volume1/@appstore/scripts
#
# Version:
# 2012-09-16:
# - Updated the list of available services
#
# 2012-06-24:
# - Script can now be run from the sabtosickbeard Post Processing file
#
# 2012-06-20:
# - Subliminal version 0.6.0 is released
#
# 2012-05-28:
# - sabToSickbeard script sended old path as second parameter, now fixed.
#
# 2012-05-18:
# - Subliminal v0.6 age perimeter implemented
# - Age can be set through command line
#
# 2012-03-30:
# - Subliminal v0.5.1 changes applied
#
# 2012-03-07:
# - Also scanning for .mp4 files
#
# 2012-03-03:
# - Setting plugins fixed
#
# 2012-02-04:
# - Removed verbose output
#
# 2011-11-29:
# - Fixed the language, no it is possible to use one language
# - Example added for multiple plugins
#
# 2011-11-24:
# - Cache folder changed
# - Script is runned by a different user than root
#
# 2011-11-20:
# - Added plugin specifier
# - Added start and end date
#
# 2011-11-20:
# - Using find to reduce the load on the server
#
# 2011-10-22:
# - Initial release
#
#------------------------------------------
# Find subtitles using subliminal

SUBLI_EXE=/usr/local/subliminal/env/bin/subliminal   # Path to Subliminal (Syno Community package)
#SUBLI_EXE=/opt/local/bin/subliminal                 # Path to Subliminal (Runned the setup.py) otherwise
#SUBLI_EXE=/opt/bin/subliminal                       # Path to Subliminal (Runned the setup.py)

CDIR=/volume1/@appstore/subliminal/cache            # needs to be somewhere, doesn't really matter where, is used to store some things in (e.g. BierDopje.nl depends on it)
RUN_AS=subliminal                                   # User that runs the script

AGE=${2}                                            # set age in days of video files to look subs for
lang1=en                                            # set first language (ISO 639-1)
lang2=                                              # second language (leave blank if not needed) (ISO 639-1)

PATH_TO_TV=${1}                                     # Directory/file to process
#PLUGINS='-s addic7ed -s bierdopje'                  # Set your plugins or leave empty to use all
PLUGINS='-s opensubtitles -s subswiki -s subtitulos -s thesubdb -s addic7ed'
                                                    # Available, but may not work: PLUGINS = opensubtitles, bierdopje, subswiki, subtitulos, thesubdb, addic7ed, tvsubtitles
                                                    # example for several plugins: PLUGINS='-s bierdopje -s subtitulos'

#################################
## Do not edit below this line ##
#################################

# set lang 1 and/or lang 2
if [ -n "$lang1" ]; then
    LANGS="-l $lang1"
else
    echo "No language specified";
    exit 2
fi
[[ -n "$lang2" ]] && LANGS="-m $LANGS -l $lang2"

# Check if AGE is specified
if echo "$AGE" | egrep -q '^[0-9]+$'; then
    # $var is a number
    AGE=$AGE
else
    # $var is not a number
    AGE=""
fi
[[ -n "$AGE" ]] && AGE_cli="-a ${AGE}d" || AGE_cli=""

# Create cache folder, some plugins need 'm
[ -d $CDIR ] || { mkdir -p $CDIR; chmod 775 $CDIR; }

SUBLI_EXE2="$SUBLI_EXE $LANGS $PLUGINS $AGE_cli --cache-dir=$CDIR"

echo "============================================================="
echo -n `date +%Y-%m-%d\ %H:%M`;
[ -n "$AGE" ] && echo -e ": Find $LANGS subtitles for $PATH_TO_TV with age $AGE days\n" || echo -e ": Find $LANGS subtitles for $PATH_TO_TV\n"

# Check if program is installed
# [ test -x $SUBLI_EXE || {
    # echo "Subliminal is not installed!";
    # exit 1;}
[ -e $SUBLI_EXE ] || {
    echo "Subliminal is not installed, please install it using python-setuptools and pip install subliminal";
    exit 1;}

    
# Check if file/directory is specified
[ -n "$PATH_TO_TV" ] || {
    echo -e "No file or directory specified!\n\n=============================================================";
    exit 1;}

# Check if file/directory exists
[ -e "$PATH_TO_TV" ] || {
    echo -e "No file or directory specified!\n\n=============================================================";
    exit 1;}

# Check how the script is called
if [ "$#" -gt "2" ]; then
    # Run subliminal as script is called by SickBeard
    /bin/sh -c "$SUBLI_EXE2 \"$PATH_TO_TV\"";
else
    # Run subliminal as script is called as job and use RUN_AS user
    su $RUN_AS -s /bin/sh -c "$SUBLI_EXE2 \"$PATH_TO_TV\"";
fi

echo "";
echo -n `date +%Y-%m-%d\ %H:%M`;
echo ": Subtitle search ended";
echo "=============================================================";
