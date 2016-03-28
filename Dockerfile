FROM node:4.3
MAINTAINER Josh Finnie "josh.finnie@trackmaven.com"

RUN apt-get -y update

# Install git, python & ruby.
RUN apt-get -y install git python python-dev python-pip

# Update NPM
RUN npm install -g npm@3.8.2

# Install Gulp
RUN npm install -g gulp@3.9.1

# Install NPM packages
ADD package.json /tmp/package.json
RUN cd /tmp && npm install
RUN mkdir -p /code && cp -a /tmp/node_modules /code

# Install Python packages
ADD requirements.txt /tmp/requirements.txt
RUN cd /tmp && pip install -r requirements.txt

ADD .babelrc /code/.babelrc
ADD gulpfile.js /code/gulpfile.js
ADD gulpfile.es6 /code/gulpfile.es6

WORKDIR /code

CMD ["gulp"]
