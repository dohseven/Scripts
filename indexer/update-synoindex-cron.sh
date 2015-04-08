#!/bin/sh

# Directory where to store the log file
LOG_DIR=$(dirname $0)"/Logs";
if [ ! -d $LOG_DIR ]; then
    mkdir -p $LOG_DIR
fi

#LOG_TIME=$(date +%Y_%m_%d_%H_%M);
LOG_TIME=$(date +%Y_%m_%d);
LOG_FILE="${LOG_DIR}/indexer_${LOG_TIME}.log"

echo "----------------------------------------------------" >> $LOG_FILE
echo "Start time: $(date +%H:%M:%S)" >> $LOG_FILE
sh $(dirname $0)/update-synoindex.sh >> $LOG_FILE 2>&1
echo "End time: $(date +%H:%M:%S)" >> $LOG_FILE
