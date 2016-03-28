Title: So you want another PostgreSQL database? (part 3)
Date: 2014-12-29
Category: DevOps
Tags: postgres, how-to
Slug: so-you-want-another-postgresql-database-part-3
Author: John Young
Avatar: john-young
Summary: Tuning your PostgreSQL cluster for performance

__Read [Part 1](/blog/so-you-want-another-postgresql-database-part-1/) or [Part 2](/blog/so-you-want-another-postgresql-database-part-2/)__

## Tuning your PostgreSQL servers on Amazon EC2
It will probably come as no surprise that the settings that are best for your PostgreSQL cluster are heavily dependent on your data and how you're using it. No one can say what will work best for you in every single use case, and it's up to you to profile your database to determine what does and does not work for you. With that being said, a great starting point for general use cases can be found in Christophe Pettus' talk [PostgreSQL when it's not your job](http://thebuild.com/presentations/not-your-job.pdf). If you're completely new to tuning your Postgres instances, I highly recommend using these settings as an initial profile point.

Here's a quick summary of his suggestions:
```
Memory settings
* shared_buffers: Set to 25% of total system RAM (or 8GB if RAM > 32GB)
* work_mem: Start at 32-64MB.
  * Look for `temporary file` lines in logs then set it to 2-3x the size of the largest temp file you see
* maintenance_work_mem: 10% of RAM, up to 1GB
* effective_cache_size: 50-75% of total RAM

Checkpoint settings
* wal_buffers: 16MB
* checkpoint_completion_target: 0.9
* checkpoint_timeout: 10min
* checkpoint_segments: 32
  * Check logs for checkpoint entries. Adjust checkpoint_segments so that checkpoints happen due to timeouts rather than filling segments

Planner settings
* random_page_cost: 1.1 for Amazon EBS
```

Some of these settings will naturally be somewhat confusing, and even a bit intimidating to change. My advice? Don't afraid to experiment, even if you're going outside of the 'norm' of what others say your settings should be.


## A real-world example
When we saw huge performance slowdowns on our database, we knew we needed more aggressive caching of our data, but how would we accomplish that? The `shared_buffers` paramater controls how much memory is dedicated to caching data in Postgres, but every online resource we found said that 8GB was as large as was feasible. Nonsense, I say!

The first step to solving any problem is determining where the problem is. We needed to be able to cache several entire tables of our database for certain heavily-used, customer facing read operations. When our data was smaller, the settings above were just fine. But as we've grown, it quickly became apparent that an 8GB cache for a 20GB table is woefully insufficient. How did we discover this? I'm glad you asked. Here is a handy SQL script to show you what is actually sitting in your shared_buffers:

```
SELECT
c.relname,
pg_size_pretty(count(*) * 8192) as buffered,
round(100.0 * count(*) /
(SELECT setting FROM pg_settings
WHERE name='shared_buffers')::integer,1)
AS buffers_percent,
round(100.0 * count(*) * 8192 /
pg_relation_size(c.oid),1)
AS percent_of_relation
FROM pg_class c
INNER JOIN pg_buffercache b
ON b.relfilenode = c.relfilenode
INNER JOIN pg_database d
ON (b.reldatabase = d.oid AND d.datname = current_database())
GROUP BY c.oid,c.relname
ORDER BY 3 DESC
LIMIT 10;
```

This script will tell show us the top 10 tables being stored in our cache, ranked from highest memory usage to lowest. Especially important is the `percent_of_relation` column. Is your most heavily read table only 65% cached? That can be a pretty big problem. For us, the additional second or two it took for customers to load a page was troublesome, but not our largest problem. This lack of caching caused our tasks to run about 300-500 milliseconds slower on average. A few hundred milliseconds added to a few million tasks quickly caused us to be overrun by tasks that ran too slowly to clear in time for the next set of tasks to be scheduled. The result? We had a task queue that would grow forever and never clear, all thanks to bad caching strategy.

We decided to increase the power of our database by bumping our EC2 instance to an `r3.4xlarge`, giving us 16 cores and 122GB of memory. To fully utilize this much more powerful machine, we needed to tweak our settings far beyond the 'recommended' levels.

Here is what we settled on:
```
### MEMORY SETTINGS
shared_buffers = 25GB
work_mem = 32MB
maintenance_work_mem = 1GB
effective_cache_size = 100GB
```

And here is an action shot, using `htop`, with the yellow coloring denoting memory reserved for our cache:
<center>![Database resource usage as seen by htop](/images/db-usage.png)</center>
