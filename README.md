# Engine Room

The TrackMaven development blog powered by [Pelican](http://pelican.readthedocs.org/en/3.4.0/)

## Development.

Install node modules with...
```
fig run builder npm install .
```

Then run
```
fig up
```

Navigate to [localdocker:8080](http://localdocker:8080)

## Setting up article

We have modified the standard preamble to better serve our theme. Below is an example of what preamble is required for our articles.

```
Title: <YOUR TITLE>
Date: <PUBLISH DATE>
Category: <CATEGORY>
Tags: <TAGS SEPERATED BY COMMAS>
Slug: <URL SLUG>
Author: <AUTHOR>
Avatar: <AVATAR (AUTHOR SLUG)>
```

Please note that the common practice has been to create tags in lowercase and the `Avatar:` is the Author's name "slugified" (i.e. Maven the Corgi becomes maven-the-corgi).

## Publishing

Once a new article is ready, simply run the command `fab push` to publish the article to GitHub.
