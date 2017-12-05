FROM node:8.9.1-alpine

## install crbot code
RUN adduser -D crbot
RUN mkdir /app
RUN chown -R crbot:crbot /app
USER crbot
WORKDIR /app
CMD bin/hubot

COPY *.json /app/
RUN npm install

COPY bin bin
COPY scripts scripts
