Title: Announcing Celery Once
Date: 2015-02-03
Category: Development
Tags: celery, redis, open source
Slug: announcing-celery-once
Author: Cameron Maske
Avatar: cameron-maske

At TrackMaven we are big users of [Celery](http://www.celeryproject.org/), an asynchronous task queue written in Python. Today we're happy to release a useful package we have been using internally called [Celery Once!](https://pypi.python.org/pypi/celery_once/)

Celery Once allows you to specify and run unique tasks across your distributed Celery cluster. It can be used to prevent workers performing the same task when scheduled multiple times.

## Example usage

Imagine the scenario of generating and send a PDF report to a user.
On our web app, a user could kick off this task by submitting a form to a web server, which then triggers our Celery task.

If generating the report is slow and our user hits submit multiple times, we don't want to queue up additional repeated tasks that end up spamming the user's inbox.

Here is how we could solve the scenario using Celery Once!
After [setting up](https://github.com/TrackMaven/celery-once#usage) `celery` with `celery_once` installed, we can write a mutually exclusive task, like so...

```python
# tasks.py
import celery
from reports import generate_report
from celery_once import QueueOnce

@celery.task(base=QueueOnce)
def send_pdf_report(email):
    report = generate_report()
    report.send(email=email)
```

Behind the scenes, `QueueOnce` uses [Redis](http://redis.io) to [check against or set a lock](https://github.com/TrackMaven/celery-once/blob/c7b8902a52ee727e4e68392887d905f1e436f7ef/celery_once/tasks.py#L98) based on the task's name and its arguments.

If we try to run the same task, while it's already queued, an `AlreadyQueued` exception is raised.

```python
# Run the initial task, not yet queued up...
>>> result = send_pdf_report.delay("alice@example.com")
# Duplicate task run before previous one completes..
>>> send_pdf_report.delay("alice@example.com")
Traceback (most recent call last):
    ..
AlreadyQueued()
# Running for a different user has its own lock
>>> send_pdf_report.delay("bob@example.com")
```

That's Celery Once in a nutshell! More documentation on how to install, set up and tweak it to your needs can be found [here](https://github.com/TrackMaven/celery-once).
