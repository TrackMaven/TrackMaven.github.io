Title: Introducing docker-node-express-skeleton
Date: 2016-03-30
Category: Docker
Tags: node.js, express.js, docker
Slug: introducing-docker-node-express-skeleton
Author: Josh Finnie
Avatar: josh-finnie

At TrackMaven, we love Docker. and personally, I love JavaScript. As we in the TrackMaven Engine Room move our technology stack from a monolithic Django application to more managible micro-services, I thought I'd take the time to develop a skeleton application using [Node.js](https://nodejs.org/en/). So this blog post will take you through my thought process when creating _docker-node-express-skeleton_. ([repo](https://github.com/TrackMaven/docker-node-express-skeleton)) But first, a note; this is a very opinionated skeleton project. The tools I use here are not the only tools available, nor are they the best (perhaps), but they are the ones I have chosen. Please feel free to comment on the repo or below to strike up a conversation as to why I am wrong, or why I am right.

## The Basics

_docker-node-express-skeleton_ is comprised of the following tools:

* [Docker](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Node.js v4](https://github.com/nodejs/LTS)
* [Express.js](http://expressjs.com/)
* [PM2](http://pm2.keymetrics.io/)
* [Babel.js](http://babeljs.io/)

It is these tools that make up the running skeleton application within a Docker container. Below, I will walk you through my thoughts as to why I selected these tools and the very basic code included within _docker-node-express-skeleton_.

### Docker & Docker Compose

The biggest part of this

### Node.js, Express.js, PM2 & Babel.js
