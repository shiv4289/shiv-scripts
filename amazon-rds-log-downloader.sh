#!/bin/bash/

# This script does the following:
# 1. Set environment variables required to access AWS from cmd.
# 2. Download postgres RDS log for yesterday.
# 3. Run pgbadger on DB log downloaded in (2)
# 4. Archive the pgbadger report in S3.
# 5. Cleanup- Delte DB log downloaded in (2) and pgbadger report generated in (3)

############ 1. Set environment variables required to access AWS from cmd  #############

JAVA_HOME=/usr/lib/jvm/default-java
export JAVA_HOME

AWS_RDS_HOME=/home/ubuntu/RDSCli-1.19.004
export AWS_RDS_HOME

export PATH=$PATH:$AWS_RDS_HOME/bin

EC2_REGION=ap-southeast-1
export EC2_REGION

AWS_CREDENTIAL_FILE=/home/ubuntu/RDSCli-1.19.004/credential-file-path.template
export AWS_CREDENTIAL_FILE

echo "$0 - `date` - INFO - environment variables set"

############ 2. Download RDS log for yesterday  ############
# List all logs in this instance (for debugging)
# rds-describe-db-logs load-server-unencrypted

# Date in the format that matches RDS log convention.
_DATE=$(date -d "today 13:00 " '+%Y-%m-%d')
_CLIENT=preprod1
_LOGFILE=rds-$_CLIENT$_DATE.log

rds-download-db-logfile $_CLIENT --log-file-name error/postgresql.log.$_DATE-07 > $_LOGFILE

echo "$0 - `date` - INFO - DB log for yesterday downloaded"

############ 3. Run pgbadger on DB log downloaded in (2)  ############

_PGBADGER_RESULT_FILE="pgbadger-report-$_CLIENT-$_DATE.html"
_PGBADGER_OPTIONS=" -p '%t:%r:%u@%d:[%p]:' -s 10 -T PGBadger-`date --date='yesterday' +%Y%m%d` "

pgbadger $_PGBADGER_OPTIONS -o $_PGBADGER_RESULT_FILE $_LOGFILE

echo "$0 - `date` - INFO - pgbadger report is generated"

############ 4. Archive the pgbadger report in S3.  ############

# Change date format to suit archive
_DATE=$(date -d "yesterday 13:00 " '+%Y/%m/%d')
#
aws s3 cp $_PGBADGER_RESULT_FILE s3://pgbadger-report/$_DATE/load-server-unencrypted/
#
echo "$0 - `date` - INFO - Archived pgbadger report on S3"
#
############# 5. Cleanup ############
#
rm $_LOGFILE
rm $_PGBADGER_RESULT_FILE

echo "$0 - `date` - INFO - job complete!"
