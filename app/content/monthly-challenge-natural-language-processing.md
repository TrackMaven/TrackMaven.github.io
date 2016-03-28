Title: Monthly Challenge: Natural Language Processing
Date: 2014-11-24
Category: Monthly Challenge
Tags: nlp, elasticsearch
Slug: monthly-challenge-natural-language-processing
Author: Fletcher Heisler
Avatar: fletcher-heisler

Our topic for this month's [Monthly Challenge meetup](http://www.meetup.com/TrackMaven-Monthly-Challenge/) is NLP! In this post, we'll get you started with one possibility: using [pandas](http://pandas.pydata.org/) and Python's [Natural Language Toolkit](http://www.nltk.org/) to analyze the contents your own Gmail inbox. For those of you who are continuing projects from our last [monthly challenge on Elasticsearch](www.meetup.com/TrackMaven-Monthly-Challenge/events/213296342/), we'll also include some code to make use of [Elasticsearch](http://www.elasticsearch.org/guide/en/elasticsearch/client/python-api/master/) as well at the end of the post.

There are endless possibilities for an NLP-inspired project:

- [Sentiment analysis](http://en.wikipedia.org/wiki/Sentiment_analysis) to put a measure to the emotional content of online reviews, social media, etc. For instance, are tweets about a topic trending to positive or negative opinions? Does a news site cover certain topics using more positive/negative terms or frequently use words correlated with certain emotions? Is this "positive" Yelp review sarcastic? (Good luck with that last one!)
- Analyze the use of language in literature to measure trends in vocabulary or writing style over time/regions/authors.
- Flag content as spam by identifying key characteristics of the language used.
- Use [topic extraction](http://en.wikipedia.org/wiki/Topic_model) to group reviews into similar categories based on what main topics they cover.
- Create a better real-time Twitter search by combining Elasticsearch with [WordNet](http://wordnet.princeton.edu/) via [NLTK's corpus](http://www.nltk.org/howto/wordnet.html) to measure term similarity on Twitter's streaming API
- Join [NaNoGenMo](https://github.com/dariusk/NaNoGenMo-2014) and write some code that generates its own novel! There are plenty of ideas and resources [here](https://github.com/dariusk/NaNoGenMo-2014/issues/1) to get started.

## Load a Gmail inbox into pandas

Let's get started with the example project! First off, we'll need some data. Prepare an archive of *only* your Gmail data (this will include what's currently in your spam and trash folders) here:

[https://www.google.com/settings/takeout](https://www.google.com/settings/takeout)

Now go take a walk. With a 5.1G inbox, my 2.8G archive took a little over an hour to send.

Once you've got the file and a local environment set up for the project, use the script below to read the data into pandas (I highly recommend using [IPython](http://ipython.org/) for data analysis):

```python
from mailbox import mbox
import pandas as pd

def store_content(message, body=None):
    if not body:
        body = message.get_payload(decode=True)
    if len(message):
        contents = {
            "subject": message['subject'] or "",
            "body": body,
            "from": message['from'],
            "to": message['to'],
            "date": message['date'],
            "labels": message['X-Gmail-Labels'],
            "epilogue": message.epilogue,
        }
        return df.append(contents, ignore_index=True)

# Create an empty DataFrame with the relevant columns
df = pd.DataFrame(
    columns=("subject", "body", "from", "to", "date", "labels", "epilogue"))

# Import your downloaded mbox file
box = mbox('All mail Including Spam and Trash.mbox')

fails = []
for message in box:
    try:
        if message.get_content_type() == 'text/plain':
            df = store_content(message)
        elif message.is_multipart():
            # Grab any plaintext from multipart messages
            for part in message.get_payload():
                if part.get_content_type() == 'text/plain':
                    df = store_content(message, part.get_payload(decode=True))
                    break
    except:
        fails.append(message)
```

Above, we used Python's [mailbox](https://docs.python.org/2/library/mailbox.html) module to read and parse "mbox"-formatted messages. This could certainly be done more elegantly (for instance, the messages include a lot of extraneous, duplicated data such as inline messages with ">>>" in replies). Another issue is the inability to handle some special characters, which for simplicity we discard for now; check that you're not ignoring a significant proportion of your inbox here!

Note that we're not actually going to make use of anything but the subject lines, but you could perform all sorts of interesting analysis on timestamps, message bodies, classify by tags, etc. Given that this is just a post to get you started (and happens to show results from my own inbox), I don't want to go into *too* much detail :)

## Finding common terms

Now that we've got some data, let's get the ten most common terms out of all subject lines:

```python
# Top 10 most common subject words
from collections import Counter

subject_word_bag = df.subject.apply(lambda t: t.lower() + " ").sum()

Counter(subject_word_bag.split()).most_common()[:10]

[('re:', 8508), ('-', 1188), ('the', 819), ('fwd:', 666), ('to', 572), ('new', 530), ('your', 528), ('for', 498), ('a', 463), ('course', 452)]
```

Well, that was underwhelming. Let's try limiting out some common terms:

```python
from nltk.corpus import stopwords
stops = [unicode(word) for word in stopwords.words('english')] + ['re:', 'fwd:', '-']
subject_words = [word for word in subject_word_bag.split() if word.lower() not in stops]
Counter(subject_words).most_common()[:10]

[('new', 530), ('course', 452), ('trackmaven', 334), ('question', 334), ('post', 286), ('content', 245), ('payment', 244), ('blog', 241), ('forum', 236), ('update', 220)]
```

Besides removing a couple of the least useful terms on our own, we used NLTK's stopwords corpus, which first needs to be install in a [rather goofy way](http://www.nltk.org/data.html). Now we can see some words that are typical to my inbox but not necessarily as typical to find in English text in general!

## Bigrams and collocations

Another interesting measurement allowed by NLTK is the concept of [collocations](http://en.wikipedia.org/wiki/Collocation). First, let's take a look at common "bigrams" - i.e, which sets of two words frequently appear together in pairs:

```python
from nltk import collocations
bigram_measures = collocations.BigramAssocMeasures()
bigram_finder = collocations.BigramCollocationFinder.from_words(subject_words)

# Filter to top 20 results; otherwise this will take a LONG time to analyze
bigram_finder.apply_freq_filter(20)
for bigram in bigram_finder.score_ngrams(bigram_measures.raw_freq)[:10]:
    print bigram

(('forum', 'content'), 0.005839453284373725)
(('new', 'forum'), 0.005839453284373725)
(('blog', 'post'), 0.00538045695634435)
(('domain', 'names'), 0.004870461036311709)
(('alpha', 'release'), 0.0028304773561811506)
(('default', 'widget.'), 0.0026519787841697267)
(('purechat:', 'question'), 0.0026519787841697267)
(('using', 'default'), 0.0026519787841697267)
(('release', 'third'), 0.002575479396164831)
(('trackmaven', 'application'), 0.002524479804161567)
```

We could repeat the same process for trigrams (or other ngrams) to find longer phrases; in this case, "new forum content" would appear as a top trigram, but in the case of the above list it ended up getting split into two pieces at the top of the bigram list.

Another slightly different type of collocation measurement is based on [pointwise mutual information](http://en.wikipedia.org/wiki/Pointwise_mutual_information); essentially, this measures how likely one word is to appear given that we've seen the other word in a specific document *relative to* their general individual frequencies throughout all documents. For instance, if my email subjects use the word "blog" and/or the word "post" a lot in general, then the bigram "blog post" is not as interesting of a signal since it's still likely that one word might appear *not* paired with the other. Using this measure, we get a different set of bigrams:

```python
for bigram in bigram_finder.nbest(bigram_measures.pmi, 5):
    print bigram

('4:30pm', '5pm')
('motley', 'fool')
('60,', '900,')
('population', 'cap')
('simple', 'goods')
```

So, I don't get a lot of email subjects mentioning the words "motley" or "fool" - but when I see either one, it's probably something "Motley Fool"-related!

## Sentiment analysis

Finally, let's try out some sentiment analysis. For a quick start, we can use the [TextBlob](http://textblob.readthedocs.org/en/dev/index.html) library, which sits on top of NLTK to provide simple access to lots of common NLP tasks. We can use its built-in [sentiment analysis](http://textblob.readthedocs.org/en/dev/quickstart.html#sentiment-analysis) (which relies on [pattern](http://www.clips.ua.ac.be/pages/pattern-en#sentiment)) to calculate the "polarity" of subject lines, from -1.0 for highly negative sentiment up to 1.0 for positive, with 0 being neutral (lack of a clear signal):

```python
from textblob import TextBlob
df['feels'] = df.subject.apply(
    lambda s: TextBlob(unicode(s, errors='ignore')).sentiment.polarity)

# Output a few subject lines with their calculated sentiment scores
df[['subject', 'feels']]

0                                      Fw: this and that    0.00000
1                                             Fw: Review    0.00000
2                          Re: Thanks for your purchase!       0.25
3            Re: Monte Carlo is a little bit confusing !   -0.28125
...
19481                              Re: Great to see you!     1.0000
19482                                            Re: API       0.00
19483                                           Question       0.00
19484                              Re: HAPPY BIRTHDAY!!!    1.00000
```

## Using Elasticsearch

If you need a primer on using Elasticsearch in Python, check out our previous [monthly challenge blog post](http://engineroom.trackmaven.com/blog/first-monthly-challenge-elasticsearch/) to get started. If you've already got a similar project going or want to try analyzing your mail in Elasticsearch, you can run the following (while your ES instance is running) to index your inbox:

```python
from mailbox import mbox
from elasticsearch import Elasticsearch

mapping = {
    "message": {
        "_timestamp": {
            "enabled": True,
            "path": "date",
            "format": "E, d MMM yyyy HH:mm:ss Z"
        },
        "properties": {
            "subject": {"type": "string"},
            "body": {"type": "string"},
            "from": {"type": "string"},
            "to": {"type": "string"},
            "date": {
                "type": "date",
                "format": "E, d MMM yyyy HH:mm:ss Z"
            },
            "labels": {"type": "string"},
            "epilogue": {"type": "string"}
        }
    }
}

es = Elasticsearch()
es.indices.create("gmail")

# When re-running with modifications, you'll need to remove the current index:
# es.indices.delete_mapping(index="gmail", doc_type="message")
es.indices.put_mapping(index="gmail", doc_type="message", body=mapping)

def store_content(message, body=None):
    if not body:
        body = message.get_payload(decode=True)
    if len(message):
        contents = {
            "subject": message['subject'],
            "body": body,
            "from": message['from'],
            "to": message['to'],
            "date": message['date'],
            "labels": message['X-Gmail-Labels'],
            "epilogue": message.epilogue,
        }
        es.index(index="gmail", doc_type='message', body=contents)

fails = []
box = mbox('All mail Including Spam and Trash.mbox')
for message in box:
    try:
        if message.get_content_type() == 'text/plain':
            store_content(message)
        elif message.is_multipart():
            for part in message.get_payload():
                if part.get_content_type() == 'text/plain':
                    store_content(message, part.get_payload(decode=True))
                    break
    except:
        fails.append(message)
```

We can then quickly repeat a few of our pandas analyses in an Elasticsearch-friendly way. For instance, let's get the most common terms out of all subject lines:

```
curl -XPOST 'http://localhost:9200/gmail/_search?pretty=true&search_type=count' -d'
{
    "aggregations": {
        "most_popular_term": {
            "terms": {
                "field": "body", 
                "size": 15,
                "stopwords": ["the", "and"]
            }
        }
    }
}'
```

As before, the results are less than stunning by default:

```
{
  "took" : 54,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 17466,
    "max_score" : 0.0,
    "hits" : [ ]
  },
  "aggregations" : {
    "most_popular_term" : {
      "buckets" : [ {
        "key" : "the",
        "doc_count" : 15330
      }, {
        "key" : "to",
        "doc_count" : 15310
      }, {
        "key" : "and",
        "doc_count" : 14303
      }, {
        "key" : "you",
        "doc_count" : 14254
      }, {
        "key" : "for",
        "doc_count" : 14081
      }, {
        "key" : "a",
        "doc_count" : 13751
      }, {
        "key" : "of",
        "doc_count" : 12552
      }, {
        "key" : "is",
        "doc_count" : 11864
      }, {
        "key" : "on",
        "doc_count" : 11091
      }, {
        "key" : "i",
        "doc_count" : 10766
      }, {
        "key" : "at",
        "doc_count" : 10653
      }, {
        "key" : "fletcher",
        "doc_count" : 10571
      }, {
        "key" : "your",
        "doc_count" : 10468
      }, {
        "key" : "in",
        "doc_count" : 10343
      }, {
        "key" : "if",
        "doc_count" : 10293
      } ]
    }
  }
}
```

We could in this case configure a [custom analyzer](http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/custom-analyzers.html) that uses the [stopwords token filter](http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/using-stopwords.html). Of course, the same TextBlob/NLTK analyses could be used directly on Elasticsearch-indexed content just as well.

Next steps: analyze your inbox over time; see if you can classify messages to determine sender/label/spam based attributes of the body text; use [latent semantic indexing](http://en.wikipedia.org/wiki/Latent_semantic_indexing) to uncover the most common general topics covered; feed your sent folder into a Markov model combined with some part-of-speech tagging to generate seemingly coherent auto-replies...

Please [let us know](mailto:engineroom@trackmaven.com) if you try out any interesting side projects using NLP - bonus points if you include an open-source repo. You can see previous presentations at [challenge.hackpad.com](http://challenge.hackpad.com) for more inspiration!
