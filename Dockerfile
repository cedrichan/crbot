FROM alpine:3.7

RUN apk update
RUN apk add nodejs

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

