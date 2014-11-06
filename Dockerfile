FROM rouge8/node-phantomjs
MAINTAINER Cameron Maske "cam@trackmaven.com"

# Update + remove unnecessary packages
RUN apt-get -y update --fix-missing && apt-get -y autoremove

# Install git.
RUN apt-get -y install git

# Install Ruby
RUN apt-get install -y libgemplugin-ruby ruby

# Install Gulp
# Need to supress the logs due to https://github.com/orchardup/fig/issues/212
RUN npm install -g gulp@3.5.2 > /dev/null 2>&1

# Install SASS
RUN gem install sass -v 3.2

RUN apt-get install -y python python-pip python-dev
ADD requirements.txt /code/requirements.txt
RUN pip install -r /code/requirements.txt
WORKDIR /code
