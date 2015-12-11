#!/bin/bash

### Purpose of the script ###

# RUn through all the postgres logs, generate pgbadger report of yesterday's PostgreSQL logs
# and delete yesterday's postgres log. This script uses the other script "json-to-postgres-format-converter.py"
# as a utility.

sudo python /home/ubuntu/json-to-postgres-format-converter.py

############ SOME VARIABLES FOR READABILITY AND MAITENANCE #################

PGBADGER_SCRIPT='pgbadger'
PGBADGER_OPTIONS="-f stderr -s 10 -T PGBadger-`date --date='yesterday' +%Y%m%d` "

_now=$(date -d "yesterday 13:00 " '+%Y/%m/%d')

cd "/mnt/logs/archive/$_now/database"

for client in $(ls -d */);
  do
    PGLOG_PATH="/mnt/logs/archive/$_now/database/$client"
    PGLOG_FILE_NAME="postgres.log"

    PGBADGER_RESULT_PATH="/mnt/logs/archive/$_now/pgbadger/$client"
    PGBADGER_RESULT_FILE="pgbadger-report-`date --date='yesterday' +%Y%m%d`.html"

    sudo mkdir -p "$PGBADGER_RESULT_PATH"

    PGBADGER_FULL_COMMAND="sudo $PGBADGER_SCRIPT $PGBADGER_OPTIONS -o $PGBADGER_RESULT_PATH$PGBADGER_RESULT_FILE $PGLOG_PATH$PGLOG_FILE_NAME"

    ########### IMPLEMENTATION  #########################################

    echo "$0 - `date` - INFO - job starts"
    if [ -e "$PGLOG_PATH/$PGLOG_FILE_NAME" ]
    then
        echo "$0 - `date` - INFO - launching the creation of pgbadger report with $PGLOG_PATH$PGLOG_FILE_NAME"
        $PGBADGER_FULL_COMMAND
        if [ $? -eq 0 ]
        then
            echo "$0 - `date` - OK - success to create pgbadger report"
        else
            echo "$0 - `date` - ERROR - problem during the execution of: $PGBADGER_FULL_COMMAND"
            exit 1
        fi
    else
        echo "$0 - `date` - ERROR - log $PGLOG_PATH$PGLOG_FILE_NAME not found"
        exit 1
    fi
    echo "$0 - `date` - INFO - The pgbadger report is placed in $PGBADGER_RESULT_PATH$PGBADGER_RESULT_FILE" 

    if find /mnt/logs/archive/$_now/pgbadger/$client -type d -empty
    then
        echo pgbadger report is not created
    else
        echo "$0 - `date` - INFO - Cleanup: Deleting /mnt/logs/archive/$_now/database/$client"
        sudo rm -r "/mnt/logs/archive/$_now/database/$client"
    fi
  done

if find /mnt/logs/archive/$_now/database/ -type d -empty
then
        echo "$0 - `date` - INFO - Cleanup: Deleting /mnt/logs/archive/$_now/database"
        sudo rm -r "/mnt/logs/archive/$_now/database"
else
        echo "sorry not empty database folder found!!!"
fi
echo "$0 - `date` - INFO - job done"
