Title: Minifying Angular.js
Date: 2014-06-30
Category: Javascript
Tags: javascript, angularjs, how-to
Slug: minifying-angularjs
Author: Josh Finnie
Summary: !

# Minifying Angular.js

At [TrackMaven](http://trackmaven.com) our stack consists of a [Django REST
backend](http://www.django-rest-framework.org/) and an 
[Angular.js](https://angularjs.org/) frontend. As our codebase grows we are
always looking to streamline our process and make the app as quick as possible.

One of the areas I have been interested in to help with the speed was the 
minification of our javascript. I took some time when I first started here to 
hookup our third-party libraries to [Bower](http://bower.io/) and using 
[Gulp](http://gulpjs.com/) concatinated and minified all third-party
javascript. This included the Angular.js core library and the plugins we use. 
(This will be a blog post in the future!) What it didn't include is our custom 
Angular.js application.


