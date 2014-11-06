Title: So You Want Another PostgreSQL Database? (Part 2)
Date: 2014-10-18
Category: DevOps
Tags: postgres, double-database, how-to
Slug: so-you-want-another-postgresql-database-part-2
Author: John Young
Avatar: john-young

__Read [Part 1](http://engineroom.trackmaven.com/blog/so-you-want-another-postgresql-database-part-1/)__

## Automatic nightly base backups to Amazon S3 using WAL-E

In the first part of this series of posts, we set up streaming replication between a primary database and a replica database by shipping WAL files between them. While functional, it lacks the robustness and safety that a production database requires. To add an additional layer of protection to our process, we ship our WAL files to S3 so that our replica can ALWAYS bring itself up to date regardless of an enormous write load on the primary or a temporary network disruption preventing the primary and replica from communicating with each other. 

We also create a base backup of our database nightly and send that to S3 so that we can restore our database to any point in time we need in case of catastrophe. With a base backup and the WAL files written since that backup was taken, your database can very easily be recovered to any point in time you specify.

### S3

* First things first, create a bucket on S3 to store our backups
  * Turn on versioning as a safeguard against file manipulation
* Create a user in AWS IAM to have Put access to the S3 bucket
  * Give the user read/put access, but NOT delete access. If, for some reason, our database server is compromised and an attacker gets our AWS credentials for this user, they will be able to overwrite our files but not delete them. Thanks to versioning, overwriting of our files is a non-issue. If the name of our bucket is db-backup, a policy like this will do:

```
{
  "Version": "2014-05-14",
  "Statement": [
    {
      "Sid": "Stmt1399394132000",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::db-backup",
        "arn:aws:s3:::db-backup/*"
      ]
    }
  ]
}
```

* Create a new user, making sure to save their AWS credentials (access key AND secret key), and add them to the newly created group

### Master and Slave Database Servers

Install WAL-E and its dependencies, then set it up by saving your bucket name, AWS user's access key, and AWS user's secret key.

* `sudo apt-get install daemontools python-dev lzop pv python-pip`
* I ran into problems with my older version of six, so just to be safe... `sudo pip install -U six`
* `sudo pip install wal-e`
* Set up WAL-E:

```
umask u=rwx,g=rx,o=
sudo mkdir -p /etc/wal-e.d/env
echo "<AWS SECRET KEY>" | sudo tee /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
echo "<AWS ACCESS KEY>" | sudo tee /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
echo 's3://db-backup/' | sudo tee /etc/wal-e.d/env/WALE_S3_PREFIX
sudo chown -R root:postgres /etc/wal-e.d
```

* That's all there is to it when it comes to setting up WAL-E. Ensure that the following options are set correctly in /etc/postgresql/9.3/main/postgresql.conf:

```
wal_level = 'hot_standby'
archive_mode = on
archive_command = 'envdir /etc/wal-e.d/env /usr/local/bin/wal-e wal-push %p'
archive_timeout = 60
```

* Become the postgres user: `su - postgres`
* Set up a cron job: 
  * `crontab -e`
  * `0 2 * * * /usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-push /data/trackmaven` will push a base backup of the master database to S3 at 2am nightly

We will also need to clean up our S3 bucket by deleting old base backups. This can be done manually, but can also be done with WAL-E. You will need to add Delete permissions to the bucket before WAL-E can do it, so understand the risks that are associated with that. The following command will keep the 5 most recent base backups and delete all others at 2:30am nightly. We could schedule it to run after the nightly backup like this:

  * `crontab -e`
  * `30 2 * * * /usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e delete --confirm retain 5`
