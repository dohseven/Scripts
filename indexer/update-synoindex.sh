#!/bin/sh

# Synology synoindexd service only works with FTP, SMB, AFP
# this program index all files that synoindexd left
# you can select extensions, modified time, user and paths
# for the searching and treatment
#
# Usage: update-synoindex.sh  --> first for create config file
#        change values of config/update-synoindex-conf.txt
#        update-synoindex.sh
#
# ---------------------------------------------------------------------
# Copyright (C) 2015-01-16  CPVprogrammer
#                           https://github.com/CPVprogrammer
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#

#---------------------------------------------
#function to notify through pushbullet
#---------------------------------------------
notify_subtitles(){
    PUSHBULLET_DIR="/volume1/documents_jean/Synology/scripts/pushbullet"

    if [[ ! -d "$PUSHBULLET_DIR" ]]; then
        echo "Pushbullet script not found"
        exit
    fi

    TITLE="Nouveau fichier de sous-titres trouvé !"

    NOTIFY=`sh $PUSHBULLET_DIR/pushbullet.sh "$TITLE" "$BODY"`
}

#---------------------------------------------
#function to set the environment
#---------------------------------------------
set_environment(){
    ALL_EXT="ASF AVI DIVX FLV IMG ISO M1V M2P M2T M2TS M2V M4V MKV MOV MP4 MPEG4 MPE MPG MPG4 MTS QT RM TP TRP TS VOB WMV XVID"

    CONFIG_DIR=$(dirname $0)"/config"

    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir "$CONFIG_DIR"
    fi

    FICH_CONF="$CONFIG_DIR/update-synoindex-conf.txt"

    if [[ ! -f "$FICH_CONF" ]]; then
        #insert into file default values
        echo "#extensions
$ALL_EXT
#Modified time --> none or \"command find time\" --> 24 hours example = \"-mtime 0\" ----> 1 hour = \"-mmin -60\"
none
#user: none, root, transmission, ftp, etc.
none
#directories to treat --> 0 recursive, 1 no recursive
1 /volume1
1 /volume1
1 /volume1" > "$FICH_CONF"
        exit
    fi

    #flag for read extensions, time for find and user for find from file FICH_CONF
    READ_EXT=0
    READ_TIME=0
    READ_USER=0

    # Path to psql
    PSQL_PATH="/bin/psql"
}

#---------------------------------------------
#function to extract the extension of a path
#---------------------------------------------
extension(){
    FICH_EXT=${FICH_MEDIA##*.}

    #convert to uppercase the extension
    FICH_EXT=$(echo $FICH_EXT | tr 'a-z' 'A-Z')
}


#---------------------------------------------
#function to check it is a treatable extension
#---------------------------------------------
check_extension(){
    if echo "$ALL_EXT" | grep -q "$FICH_EXT"; then
        TREATABLE=1
    else
    echo "File not treated, unsupported extension ($FICH_EXT)"
        TREATABLE=0
    fi

    return "$TREATABLE"
}


#---------------------------------------------
#function to check if directory is in the DB
#---------------------------------------------
search_directory_DB(){
    PATH_MEDIA=${FICH_MEDIA%/*}
    PATH_MEDIA_1=$(echo $PATH_MEDIA | tr 'A-Z' 'a-z')

    #replace "'" with "\'"
    PATH_MEDIA_SQL=${PATH_MEDIA_1//"'"/"\'"}
    #replace " " with "\ "
    PATH_MEDIA_SQL=${PATH_MEDIA_SQL//" "/"\ "}
    TOTAL=0
    CREATE_DIR=0

    while : ; do
        TOTAL=`$PSQL_PATH mediaserver -U postgres -tA -c "select count(1) from directory where lower(path) like '%$PATH_MEDIA_SQL%'"`

        if [ "$TOTAL" = 0 ]; then
            PATH_MEDIA_1=${PATH_MEDIA_1%/*}
            CREATE_DIR=1
        fi

        PATH_MEDIA_SQL=${PATH_MEDIA_SQL%/*}
        if [ -z "$PATH_MEDIA_SQL" ]; then
            break
        fi
    done

    return "$CREATE_DIR"
}


#---------------------------------------------
#function to check if file is in the DB
#---------------------------------------------
search_file_DB(){
    FICH_MEDIA_1=$(echo $FICH_MEDIA | tr 'A-Z' 'a-z')

    #replace "'" with "\'"
    FICH_MEDIA_SQL=${FICH_MEDIA_1//"'"/"\'"}

    TOTAL=`$PSQL_PATH mediaserver -U postgres -tA -c "select count(1) from video where lower(path) like '%$FICH_MEDIA_SQL%'"`

    return "$TOTAL"
}


#---------------------------------------------
#function to add directory to DB
#---------------------------------------------
add_directory_DB(){
    echo "Adding directory $PATH_MEDIA to the database"
    synoindex -A "$PATH_MEDIA"
}


#---------------------------------------------
#function to add file to DB
#---------------------------------------------
add_file_DB(){
    echo "Adding file $FICH_MEDIA to the database"
    if [ "$FICH_EXT" = "SRT" ]; then
        REMOVE_BOM=`sed -i '1 s/^ďťż//' "$FICH_MEDIA"`
        BODY=$(basename "$FICH_MEDIA")
        notify_subtitles
    fi
    synoindex -a "$FICH_MEDIA"
}


#---------------------------------------------
#function to treat directories
#---------------------------------------------
treat_directories(){
    CREATE_FILE=1

    search_directory_DB
    SEARCH_RETVAL=$?

    if [ "$SEARCH_RETVAL" == 1 ]; then
        add_directory_DB
        CREATE_FILE=0
    fi

    return $CREATE_FILE
}


#---------------------------------------------
#function to treat files
#---------------------------------------------
treat_files(){
    echo "Analyzing $FICH_MEDIA"
    extension
    check_extension

    EXT_RETVAL=$?
    if [ "$EXT_RETVAL" == 1 ]; then
        search_file_DB
        SEARCH_RETVAL=$?
        echo "Status: $SEARCH_RETVAL"

        if [ "$SEARCH_RETVAL" == 0 ]; then
            treat_directories

            EXT_RETVAL=$?

            if [ "$EXT_RETVAL" == 1 ]; then
                add_file_DB
            fi
        fi
    fi
}


#---------------------------------------------
#function for the main program
#---------------------------------------------
treatment(){
    #read file FICH_CONF
    while read LINE || [ -n "$LINE" ]; do

        #skip comment and blank lines
        case "$LINE" in \#*) continue ;; esac
        [ -z "$LINE" ] && continue

        #read the extensions from file
        if [[ "$READ_EXT" -eq 0 ]]; then

            ALL_EXT=$LINE

            #convert to uppercase
            ALL_EXT=$(echo $ALL_EXT | tr 'a-z' 'A-Z')

            READ_EXT=1
            continue
        fi

        #read the update time from file
        if [[ "$READ_TIME" -eq 0 ]]; then
            LINE=$(echo $LINE | tr 'A-Z' 'a-z')

            if [ "$LINE" == "none" ]; then
                TIME_UPD=""
            else
                TIME_UPD="$LINE"
            fi

            READ_TIME=1
            continue
        fi

        #read the user from file
        if [[ "$READ_USER" -eq 0 ]]; then
            LINE=$(echo $LINE | tr 'A-Z' 'a-z')

            if [ "$LINE" == "none" ]; then
                USER_OWN=""
            else
                USER_OWN="-user $LINE"
            fi

            READ_USER=1
            continue
        fi

        #read the paths from file
        RECURSIVE=$(echo $LINE | awk -F" " '{print $1}')
        PATH_FILE=$(echo $LINE | awk -F" " '{print $2}')

        #delete last / if exists
        PATH_FILE="${PATH_FILE%/}"

        if [[ "$RECURSIVE" -eq 0 ]]; then
            #recursive find
            RECURSIVE=""
        else
            #no recursive find
            RECURSIVE="-maxdepth $RECURSIVE"
        fi

        PARAMETERS="$PATH_FILE $RECURSIVE $TIME_UPD -type f $USER_OWN"

        find $PARAMETERS |
        while read FICH_MEDIA
        do
            treat_files
        done

    done < $FICH_CONF
}


#---------------------------------------------
#main
#---------------------------------------------
set_environment
treatment
