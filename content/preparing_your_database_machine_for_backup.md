Backup Postgres on AWS to offsite server
======================

> 3 copies, 2 different media types, 1 offsite, boom, good to go.
> 
> --<cite> Abraham Lincoln</cite>


Backups should be straightforward, automatic, have few moving parts, adhere to the [3-2-1 rule](http://www.dpbestflow.org/backup/backup-overview#321), and, most importantly, facilitate easy recovery.

TrackMaven's applications run on AWS and we've previously just stored our backups on S3. However, you may want to keep an offsite backup, as we did. 

This post details one way to mirror multiple backup copies of your database both in S3 and on an offsite server.

#### Preparing your database machine for backup

###### Create an additional mountpoint for your backup data

Unless you have a significant amount of extra space on your DB machines, we suggest creating and mounting an additional EBS volume to handle your backup date. 

The instructions to [create](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-creating-volume.html), [attaching](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-creating-volume.html), and [mounting](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-attaching-volume.html) another EBS volume (hereafter referrered to as `/YOUR_BACKUP_POINT`) are best covered by Amazon. 

###### Setting permissions on new volume

Because you created the mountpoint with `sudo` it will be owned by `root`. We need it to be readable/writeable by other users.

`pg_dump` is the process we will use to write the backup, and it should be run by the `postgres` user so it does not have to authenticate (annoying and difficult to do securely within `crontab`). 

We created a new group `BACKUPUSERS` and added our `ssh_user` and `postgres` to it with these commands:


```
sudo groupadd BACKUPUSERS
sudo usermod -a -G BACKUPUSERS YOUR_SSH_USER
sudo usermod -a -G BACKUPUSERS postgres
sudo chgrp -R BACKUPUSERS /YOUR_BACKUP_POINT
sudo chmod -R 770 /YOUR_BACKUP_POINT
```

H/T to [this superuser answer](http://superuser.com/questions/280994/give-write-permissions-to-multiple-users-on-a-folder-in-ubuntu).

#### Initial backup

If you haven't created an IAMS user with only S3 permissions, we suggest that you do that now, because you'll need the keys for the next step.

Install and configure the S3 command line client on the DB machine:

```
sudo apt-get install s3cmd
s3cmd --configure
```

Put this script somewhere on your DB machine - the logging lines are meant to uncomemnt if you are running manually and want to debug.

The script will remove yesterday's backups, dump a current copy of the database, 

######DB backup cron script
```
#!/bin/bash

# Backup script to pg_dump
# 'YOUR_DATABASE' db. Assumes that
# this is on the crontab of the
# postgres user so no authentication
# is necessary.


PGDUMP=/usr/bin/pg_dump
DATABASE=YOUR_DATABASE
BACKUP_FOLDER=/YOUR_BACKUP_FOLDER
EXPORTFILE=$BACKUP_FOLDER/pg_dump_`date +%F`.sql
COMPRESSEDFILE=$EXPORTFILE.tgz
BUCKET=s3://YOUR_S3_BUCKET/OPTIONAL_FOLDER/
S3CMD=/usr/bin/s3cmd
LOG_FILE=$BACKUP_FOLDER/backup_log_file.txt
DATE=`date +%F`

REMOVE_TIME=`date +%T`
echo Time: $REMOVE_TIME
echo Removing yesterdays...
echo $DATE,RemovingOld,$REMOVE_TIME >> $LOG_FILE
rm $BACKUP_FOLDER/*.sql*

DUMP_TIME=`date +%T`
echo Time: $DUMP_TIME
echo Dumping...
echo $DATE,DumpBegan,$DUMP_TIME >> $LOG_FILE
$PGDUMP -c -f $EXPORTFILE $DATABASE

TAR_TIME=`date +%T`
echo Time: $TAR_TIME
echo Taring...
$DATE,TarBegan,$TAR_TIME >> $LOG_FILE
tar -czf $COMPRESSEDFILE $EXPORTFILE

S3_TIME=`date +%T`
echo Time: $S3_TIME
echo s3cmd PUTTING...
echo $DATE,S3Began,$S3_TIME >> $LOG_FILE
$S3CMD put $COMPRESSEDFILE $BUCKET
$S3CMD put -f $LOG_FILE $BUCKET

DONE_TIME=`date +%T`
echo $DATE,Done,$DONE_TIME >> $LOG_FILE
```
######Set up the crontab

Become the `postgres` user so you don't have to authenticate in your crontab to access the database:

`su - postgres`

Access your crontab to edit:

`crontab -e`

Then add this line to your crontab, which will run your script at the path you specify at 1AM every night:

``0 1 * * * /YOUR_BACKUP_POINT/YOUR_BACKUP_SCRIPT.sh`


#### Pull the backup to remote server

Install `s3cmd` on your local/offsite box and configure it as well - create whatever directory structure you want.

######Get/ifnot/wait/tryagain

```
#!/bin/bash

# Script to test if today's backup HAS
# occured, and has been pushed to the
# specified S3 bucket - if it has, gets
# the file. If not present, wait 30 min
# and try again.
# Assumptions/Notes:
#  * Only checks 10 times after
#    initial run
#  * Assumes that s3cmd has been
#    configured prior to cron init


BUCKET=s3://YOUR_BUCKET
DATE=`date +%F`
FILE=pg_dump_$DATE"".sql.tgz""
FULLPATH=$BUCKET$FILE
EXISTS=false
WAIT_TIME_IN_SECONDS=1800
RETRYS=0

echo Checking for $FULLPATH

get_file_from_s3 ()
{
  #echo getting $FULLPATH
  s3cmd get $FULLPATH
}

check_if_backup_complete ()
{
  s3cmd info $FULLPATH >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    EXISTS=true
    get_file_from_s3
  fi
}

while [ $RETRYS -lt 10 ]; do
  check_if_backup_complete
  if ! $EXISTS; then
    sleep $WAIT_TIME_IN_SECONDS
    (( RETRYS++ ))
    echo $RETRYS
  else
    break
  fi
done
```

You can run this script as any user.



#### Keep only n backups on S3



```
#!/bin/bash

FILES=()
FILES+=`s3cmd ls s3://trackmaven-prod-db/pg_dump/ | grep tgz | awk '{print $4}'`

#echo $FILES

SORTEDFILES=( $(
    for el in "${FILES[@]}"
    do
        echo "$el"
    done | sort -Vr ) )

for (( i = 0 ; i < ${#SORTEDFILES[@]} ; i++ )) do
  if [ $i -gt 2 ]; then
    #echo Removing ${SORTEDFILES[$i]}
    s3cmd del ${SORTEDFILES[$i]}
  fi
done
```

#### Keep only n backups on the remote machine

Then you need to delete the files on the local machine that you don't need anymore:










