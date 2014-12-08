# So you want another PostgreSQL database? (part 3)
## Tuning your PostgreSQL servers on Amazon EC2
These settings are taken and combined from Christophe Pettus' talk [PostgreSQL when it's not your job](http://thebuild.com/presentations/not-your-job.pdf).

### Memory settings
* shared_buffers: Set to 25% of total system RAM (or 8GB if RAM > 32GB)
* work_mem: Start at 32-64MB. 
  * Look for `temporary file` lines in logs then set it to 2-3x the size of the largest temp file you see
* maintenance_work_mem: 10% of RAM, up to 1GB
* effective_cache_size: 50-75% of total RAM

### Checkpoint settings
* wal_buffers: 16MB
* checkpoint_completion_target: 0.9
* checkpoint_timeout: 10min
* checkpoint_segments: 32
  * Check logs for checkpoint entries. Adjust checkpoint_segments so that checkpoints happen due to timeouts rather than filling segments

### Planner settings
* random_page_cost: 1.1 for Amazon EBS
