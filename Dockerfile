FROM ibmcom/kitura-ubuntu:latest

MAINTAINER konrad.feiler@vimn.com

#swift talk example code
WORKDIR /app

COPY Package.swift ./
COPY Sources ./Sources
COPY Views ./Views
COPY Resources ./Resources

RUN swift package fetch
RUN swift build

ENV PATH ${PATH}:/app/.build/debug

CMD while true; do sleep 3600; done
