#!/bin/sh
#------------------------------------------
# Synology configuration backup
#
#------------------------------------------

BACKUP_TIME=$(date +%Y%m%d);
BACKUP_PATH="/volume1/backup/Synology/";
BACKUP_NAME="NAS_Jean";

BACKUP_FILE="${BACKUP_PATH}${BACKUP_NAME}_${BACKUP_TIME}.dss";

#echo $BACKUP_FILE;

synoconfbkp export --filepath=${BACKUP_FILE}
