#!/bin/sh

# Directory where to store the log file
LOG_DIR="/volume1/documents/Tools/indexer/Logs";
if [ ! -d $LOG_DIR ]; then
    mkdir -p $LOG_DIR
fi

#LOG_TIME=$(date +%Y_%m_%d_%H_%M);
LOG_TIME=$(date +%Y_%m_%d);
LOG_FILE="${LOG_DIR}/indexer_${LOG_TIME}.log"

echo "----------------------------------------------------" >> $LOG_FILE
echo "Start time: $(date +%H:%M:%S)" >> $LOG_FILE
sh /volume1/documents/Tools/indexer/update-synoindex.sh >> $LOG_FILE 2>&1
echo "End time: $(date +%H:%M:%S)" >> $LOG_FILE
