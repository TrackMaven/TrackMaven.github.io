FROM node:argon
MAINTAINER Josh Finnie "josh.finnie@trackmaven.com"
RUN apt-get -y update

# Install Gulp
RUN npm install -g gulp@3.9.1

# Install Python
RUN apt-get install -y python python-dev python-pip
ADD requirements.txt /code/requirements.txt
RUN pip install -r /code/requirements.txt

ADD development/run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

WORKDIR /code

CMD ["/usr/local/bin/run"]
