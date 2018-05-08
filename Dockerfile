FROM node:8

MAINTAINER Alex Jones <alex@ccautomation.uk>

RUN mkdir -p /usr/local
COPY src/ /usr/local
RUN cd /usr/local/src
WORKDIR /usr/local/src
RUN npm install -g mocha chai && npm install

CMD [ "npm", "run", "start:production" ]
