Title: Django Compressor and s3
Date: 2015-03-17
Category: Development
Tags: Django, Django Compressor, s3, static files
Author: Josh Finnie
Avatar: josh-finnie

Here at [TrackMaven](http://trackmaven.com) we have recently reviewed how we were dealing with static files within our application and felt there was a lot of room for improvement. Dealing with static media is never fun as there are so many edge cases where they can mess up or slow you down. In our case, we were running Django's `collectstatic` command on each box and were begrudgingly taking the productivity hit. This way of handling our static files was fine for the time, but as we grew in size it became a sore spot in our deployment strategy. 

There were a lot of problems with this process. As our infrastructure grew, we started to run `collectstatic` many times; this created an issue of incorrect static media served since new versions were uploaded to s3 before the new code reached all the servers. We couldn't let this go on forever, and this blog post goes into the steps we took to correctly serve Django static media on s3 with a large infrastructure.

## Our Fix

This first thing we needed to do is move the `collectstatic` command to our "manager" box. This made it so that the `collectstatic` command only ran once, but it did not solve the issue about versioning our static media. To do the versioning for us, we reintroduced [Django-Compressor](http://django-compressor.readthedocs.org/en/latest/) to our deployment strategy. Django Compressor "compresses linked and inline JavaScript or CSS into a single cached file," and this single cached file is versioned! Perfect... almost.

### Setting Up Django Compressor & Django Storages

Setting up Django Compressor with s3 should not be difficult, but we found the documentation a bit lacking in the actual steps of how to set it up. Through some trial and error, we came up with the following setup that seems to work:

First, we want to make sure the latest version of Django Compressor is installed (At this time, it is version 1.4) along with [Django Storages](https://django-storages.readthedocs.org) since we are going to be hosting our static media on s3:

```bash
$ pip install django-compressor==1.4 django-storages==1.1.8
```

Next, we want to add Django Compressor to our Django app and hook it up. Add `'compressor',` to you `INSTALLED_APPS` tuple and `'compressor.finders.CompressorFinder',` to your `STATICFILES_FINDERS` tuple. This should give you the basic setup we need to have your static media compressed. 

Finally, we want to make some changes to our `settings.py` folder to allow Django Compressor to work with s3. Since we are using Django Storage, we can simply tie our application's static media to s3 with the following variables in `settings.py`:

```python
# Amazon S3 storage settings.
AWS_ACCESS_KEY_ID = os.environ.get('AWS_S3_KEY', None)
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_S3_SECRET_KEY', None)
AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME', None)
AWS_QUERYSTRING_AUTH = False
max_age = 60 * 60 * 24 * 365  # Currently set to 1 year.
AWS_HEADERS = {
    'x-amz-acl': 'public-read',
    'Expires': http_date(time() + max_age),
    'Cache-Control': 'public, max-age=' + str(max_age),
    'Access-Control-Allow-Origin': '*'
}
```

Reviewing the code above, we did some interesting things to our Django Storages configuration knowing we were going to use Django Compressor. The `max_age` variable, which we use for both `Cache-Control` and `Expires` is set to a year, if you are not going to use Django Compressor, I would recommend lowering this since 1 year is a long caching length for dynamic content. However, it works really well for Django Compressor since the versioning.

Next we want to hook up Django Compressor, but we only want to run Django compressor on our web servers, not locally. Adding the following code to our `settings.py` will do the trick:

```python
if not DEBUG:
    COMPRESS_STORAGE = 'utils.storage.CachedS3BotoStorage'
    STATIC_URL = COMPRESS_URL = os.environ.get('AWS_URL', None)
    COMPRESS_OUTPUT_DIR = ''
    COMPRESS_OFFLINE = True
    DEFAULT_FILE_STORAGE = 'storage.backends.s3boto.S3BotoStorage'
```

You might also note the change to `DEFAULT_FILE_STORAGE` as well, although this is not a Django Compressor specific settings variable, it does ensure that we only use s3 when `DEBUG` is `False` for all your file storage needs. The only think out of the norm above is how we set `COMPRESS_OFFLINE` to `True`. We do this because we have multiple web servers, but only run the compress command on one box. This settings should get you where you need to be with regards to having compressed static media on s3.

We need to also tell our templates to use this newly-created, compressed static media, to do that we simply have to add a bit of django magic to our templates:

```html
<!-- "base.html" -->
{% block javascripts %}
    {% compress js %}
        <script scr="/path/to/javascript.js"></script>
    {% endcompress %}
{% endblock %}
```

Adding the `compress` template tag tells your django compressor what to compress, along with telling your template to have the compressed file name added there.

## Conclusion

After a few iterations of the above set up, we were able to get a consistently awesome result from using Django Compressor along side Django Storages. A bit lesson we learned was that we were accidentally shipping all our code to s3 before we were compressing it. This lead to some interesting version collisions where we were compressing new static media, but the web servers still wanted to use the old compressions. We found it was very important to make sure that you are using the `COMPRESS_OFFLINE=True` flag the second you have more than one web server.
