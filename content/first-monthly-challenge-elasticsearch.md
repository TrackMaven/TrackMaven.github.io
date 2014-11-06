Title: First Monthly Challenge: Elasticsearch!
Date: 2014-10-20
Category: Monthly Challenge
Tags: elasticsearch
Slug: first-monthly-challenge-elasticsearch
Author: Fletcher Heisler
Avatar: fletcher-heisler

TrackMaven has begun hosting a [Monthly Challenge meetup](http://www.meetup.com/TrackMaven-Monthly-Challenge/)! Each month, we will name a general topic, a new technology, or something in between. We'll collect a few resources and examples to get everyone started (hence this post), then we'll meet up in a month to share short presentations on everyone's new projects.

Our first topic is **Elasticsearch**, an incredibly powerful search and analytics engine. Go [here](http://www.elasticsearch.org/overview/elasticsearch) for a high level, buzzword-heavy overview, or just jump into [the documentation](http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/) if you're feeling bold.

Built on top of [Lucene](http://lucene.apache.org/core/), Elasticsearch is most frequently used to add full text search functionality; it comes out of the box with a rich query language that supports fuzzy matching and advanced [parsing patterns](http://lucene.apache.org/core/3_0_3/queryparsersyntax.html).

We'll go into the details of a sample project to get you started below. A few Elasticsearch-inspired possibilities for projects might be:

- Provide real-time text search over a large corpus (ie, some subset of [Project Gutenburg](http://www.gutenberg.org/), a bunch of product reviews, etc.)
- Beyond search, *analysis* of a large set of text: determine similar authors based on vocabulary, compare word usage over time using Google Books data, or see what stands out in the language of spammy emails
- Task logging and visualization of results with [Logstash](http://www.elasticsearch.org/overview/logstash/) and [Kibana](http://www.elasticsearch.org/overview/kibana/), the Elasticsearch ["ELK" stack](http://www.elasticsearch.org/webinars/introduction-elk-stack/)
- Data analyses using [aggregations](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations.html) on any sort of tabular data: financial records, movie reviews, census results...
- Find unusual patterns in weather data or crime data by location
- Create a better real-time Twitter search by combining Elasticsearch with NLP on Twitter's streaming API

Elasticsearch communicates over a RESTful API using JSON. There are a [large number of clients](http://www.elasticsearch.org/guide/en/elasticsearch/client/) to get you started in many different languages. We will be using the [Python wrapper](http://elasticsearch-py.readthedocs.org/en/master/) in our examples, but there is also [Elasticsearch.js](http://www.elasticsearch.org/guide/en/elasticsearch/client/javascript-api/current/quick-start.html) if that's more your style. You can also cURL POST data directly into Elasticsearch manually, although that may not scale well...

Let's get started! [Download ES](http://www.elasticsearch.org/download/) and unpack it into a directory/project of your choice. You can then run:

`/bin/elasticsearch`

By default, Elasticsearch sits on port 9200. Once it's booted up, you can visit:
http://localhost:9200/

in your browser and see something like:

```
{
  "status" : 200,
  "name" : "Some Really Weird Name",
  "version" : {
    "number" : "1.3.4",
    "build_hash" : "a70f3ccb52200f8f2c87e9c370c6597448eb3e45",
    "build_timestamp" : "2014-11-01T09:07:17Z",
    "build_snapshot" : false,
    "lucene_version" : "4.9"
  },
  "tagline" : "You Know, for Search"
}
```

Now let's put some data in! Install the libraries `elasticsearch` and `requests`:

```
pip install elasticsearch requests
```

You can then run this demo script to load in the top 100 Reddit "IAMA" posts (where a famous or otherwise interesting person makes a Reddit post to say "I Am A ___, Ask Me Anything"):

```python
import requests
from elasticsearch import Elasticsearch

es = Elasticsearch()

# Return a response of the top 100 IAMA Reddit posts of all time
response = requests.get("http://api.reddit.com/r/iama/top/?t=all&limit=100", 
                        headers={"User-Agent":"TrackMaven"})

fields = ['title', 'selftext', 'author', 'score', 
        'ups', 'downs', 'num_comments', 'url', 'created']

# Loop through results and add each data dictionary to the ES "reddit" index
for i, iama in enumerate(response.json()['data']['children']):
    content = iama['data']
    doc = {}
    for field in fields:
        doc[field] = content[field]
    es.index(index="reddit", doc_type='iama', id=i, body=doc)
```

Elasticsearch arranges everything by an **indexes**, which can usually be thought of as the equivalent of a database in SQL terms, and **document types**, which in SQL terms would be individual tables. Each document type can then hold chunks of JSON data (the **body**), each labeled by an **id**.

In Elasticsearch, if an index does not already exist then it will be created automatically when you first try to add data to it. Note that if we had just tried to run:

```python
for i, iama in enumerate(response.json()['data']['children']):
    es.index(index='reddit', doc_type='iama', id=i, body=iama['data'])
```

and stored *all* the returned fields, we would have run into a parsing error. This is because Elasticsearch tries to guess at the data types best suited for storing on the fly, but it doesn't always guess correctly. This is one reason why it's a good idea to create a new index using an explicit [mapping](http://www.elasticsearch.org/guide/reference/mapping/) to define how you want each field stored ahead of time.

Now that the index is populated with data, you can run search queries against Elasticsearch through cURL or directly in your browser. Try these out:

```
http://localhost:9200/reddit/iama/_search?pretty=true&size=3
http://localhost:9200/reddit/iama/_search?pretty=true&q=title:almost
```

The Elasticsearch documentation [here](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html) gives some more examples of the types of queries you can make.

Let's use the Python wrapper to make some queries as well:

```python
from elasticsearch import Elasticsearch

es = Elasticsearch()

# Fetch a specific result
res = es.get(index='reddit', doc_type='iama', id=1)
print res['_source']

# Update the index to be able to query against it
es.indices.refresh(index="reddit")

# Query for results: nothing will match this author
res = es.search(index="reddit", 
                body={"query": {"match": {"author": "no results here!"}}})
print res

# Query for all results (no matching criteria)
res = es.search(index="reddit", body={"query": {"match_all": {}}})
print res['hits']['total']
print res['hits']['hits'][1]['_source']['title']

# Query based on text appearing in the title
# (by default matches across capitalization, pluralization, etc)
res = es.search(index="reddit", body={"query": {"match": {"title": "obama"}}})
print res['hits']['total']
print res['hits']['hits'][0]['_source']['title']
```

At this point, you could build more functionality around the built-in search or use [aggregations](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations.html) to perform broader analysis on the data.

For now, let's try working with some time series data so that we can make some pretty charts. Download a CSV of some [trip history data](http://www.capitalbikeshare.com/trip-history-data) from Capital Bikeshare.

We'll create a mapping before storing our data this time. We can specify that certain string fields are "not_analyzed" as well, meaning that rather than try to parse out the text in "D St & Maryland Ave NE", Elasticsearch will treat it as a single string not to be broken up:

```python
import csv
from elasticsearch import Elasticsearch

# Map the fields of a new "trip" doc_type
mapping = {
    "trip": {
        "properties": {
            "duration": {"type": "integer"},
            "start_date": {"type": "string"},
            "start_station": {"type": "string", "index": "not_analyzed"},
            "start_terminal": {"type": "integer"},
            "end_date": {"type": "string"},
            "end_station": {"type": "string", "index": "not_analyzed"},
            "end_terminal": {"type": "integer"},
            "bike_id": {"type": "string"},
            "subscriber": {"type": "string"}
        }
    }
}

# Create a new "bikeshare" index that includes "trips" with the above mapping
es = Elasticsearch()
es.indices.create("bikeshare")
es.indices.put_mapping(index="bikeshare", doc_type="trip", body=mapping)

# Import a CSV file of trip data - this will take quite a while!
with open('2014-Q2-Trips-History-Data.csv', 'rb') as csvfile:
    reader = csv.reader(csvfile)
    reader.next() # Skip header row
    for id, row in enumerate(reader):
        h, m, s = row[0].split()
        trip_seconds = int(h[:-1])*60*60 + int(m[:-1])*60 + int(s[:-1])
        content = {
            "duration": trip_seconds,
            "start_date": row[1],
            "start_station": row[2],
            "start_terminal": row[3],
            "end_date": row[4],
            "end_station": row[5],
            "end_terminal": row[6],
            "bike_id": row[7],
            "subscriber": row[8],
        }
        es.index(index="bikeshare", doc_type='trip', id=id, body=content)
```

Run a couple queries to make sure data stored as expected:

```
http://localhost:9200/bikeshare/trip/_search?size=3&pretty=true
```

Now let's graph some results with Kibana! A browser-based analytics dashboard built for adding visualization to Elasticsearch, Kibana is usually used for analyzing data over time (ie, tracking log events as a time series). In this case, we haven't collected timestamps, but 

Start by [downloading Kibana](http://www.elasticsearch.org/overview/kibana/installation/). While Elasticsearch is still up and running, you can separately visit Kibana's directory and run:

```
python -m SimpleHTTPServer 9201
```

If you now visit:
```
http://localhost:9201/
```

you should be able to see Kibana's default interface. Click "Blank Dashboard" at the bottom to get started, or let Kibana fill in some default panels. Add a row of query results using a "table" panel and try searching for `subscriber:registered` at the top instead of the default `*` to see the results limit. (To add a panel to a new row, click the green "+" on the far left.)

Let's see the proportion of registered users in a chart. Add a new row to the dashboard, then add a **terms** type panel to that row. Give it a title "Subscriber types" and take the **count** of the **field** "subscribers" for a *style** of "bar" or "pie". This should create a chart of the registered versus casual bikeshare users:
<center>![](/images/ESchart1.png)</center>

Try taking a look at the distribution of top ending stations, `end_station`, in a similar way:
<center>![](/images/ESchart2.png)</center>

Now we can run search queries and get real-time updates on these charts; try searching for `start_station:"Lincoln Memorial"` to see where riders end their journey when they start at the Lincoln Memorial.

Next steps: examine results across time, analyze the total duration of trips, add geocoding and map the results, find the bikes that have traveled the farthest total distance... Even if you aren't attending the meetup, please let us know if you try out any interesting side projects using Elasticsearch - bonus points if you include an open-source repo that we could share here!
