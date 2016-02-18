FROM debian:jessie
MAINTAINER booi@brandonooi.com

RUN apt-get update && apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_5.x | bash - && apt-get install -y nodejs

## install crbot code
RUN useradd -m crbot && mkdir /home/crbot/crbot
COPY bin /home/crbot/crbot/bin
COPY scripts /home/crbot/crbot/scripts
COPY *.json /home/crbot/crbot/
RUN cd /home/crbot/crbot && chown -R crbot:crbot /home/crbot/crbot && npm install

USER crbot
CMD cd /home/crbot/crbot && bin/hubot_docker
