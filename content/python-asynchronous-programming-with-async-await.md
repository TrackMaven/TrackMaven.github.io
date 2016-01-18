Title: Python Asynchronous Programming with async/await
Date: 2016-01-04
Category: Python
Tags: programming
Slug: python-asynchronous-programming-with-async-await
Author: Salar Rahmanian
Avatar: salar-rahmanian

When [Python 3.5](https://docs.python.org/3/whatsnew/3.5.html) was released in September 2015 it added [PEP-492](https://www.python.org/dev/peps/pep-0492/) to its feature set. PEP-492 enables asynchronous programming with Python and today we will demonstrate how to use this new feature and syntax.

### What is Python Asynchronous Programming?

A normal Python application consists of a single thread, or process, and tasks are executed synchronously, or one after another. This means that any task which takes a long time will delay all other tasks in the sequence being executed. Thus, in a synchronous application, a single slow task can have an outsize impact on the performance of the entire application.

Asyncio enables multitasking-style process scheduling within a single thread. What this means is that we can have tasks running effectively simultaneously instead of sequentially. 

The new syntax in Python 3.5 makes it possible to schedule your tasks to run in parallel and wait for them to complete when needed.

### Overview

To illustrate this new feature we are going to develop a simple python website uptime monitoring app which will monitor multiple websites to see if they are up and available.

    import asyncio
    import requests


    async def get_site(url):
        try:
            r = requests.get(url)
            print("{} returned {}".format(url, r.status_code))
        except Exception as c:
            print("{} is down".format(url))

    async def main():
        await asyncio.wait([
            get_site("http://trackmaven.com/"),
            get_site("http://engineroom.trackmaven.com/"),
            get_site("https://httpbin.org/delay/3"),  # Responds with 3 seconds delay
            get_site("https://httpbin.org/delay/10"),  # Responds with 10 seconds delay
            get_site("http://idontexist")  # a Site that doesn't exist
        ])

    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())

The function `get_site` gets the response from a given url.

In the ```main``` function ```await asyncio.wait``` contains a list of tasks that should be run asynchronously. It will wait for all tasks to complete before returning.

Running the script will give this output:

    http://idontexist is down
    https://httpbin.org/delay/3 returned 200
    http://trackmaven.com/ returned 200
    https://httpbin.org/delay/10 returned 200
    http://engineroom.trackmaven.com/ returned 200

The order of these responses may vary each time you run your script as they are running in parallel and will return at different times.

As you can see the program completes only once all 5 sites called have responded, but a slow response from one site, which may have been at the top of the list, prevents the entire application from finishing but does not prevent sites to check farther down in the list from returning. 

You can find the source code to my example script on [GitHub](https://github.com/TrackMaven/blog-uptimemaven)

Got any questions about using ```async``` and ```await```? Let me know in the comments.
