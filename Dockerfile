FROM node
MAINTAINER Josh Finnie "josh.finnie@trackmaven.com"
RUN apt-get -y update

# Install git.
RUN apt-get -y install git

# Install Ruby
RUN apt-get install -y ruby

# Install ImageMagick
RUN apt-get install -y imagemagick graphicsmagick

# Updating NPM
RUN npm update -g npm

# Install Gulp
RUN npm install -g gulp@3.8.11 > /dev/null 2>&1

# Install SASS
RUN gem install sass -v 3.4.13

# Install Python
RUN apt-get install -y python python-dev python-pip
ADD requirements.txt /code/requirements.txt
RUN pip install -r /code/requirements.txt

ADD development/run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

WORKDIR /code

CMD ["/usr/local/bin/run"]
