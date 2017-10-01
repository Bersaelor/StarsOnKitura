FROM ibmcom/swift-ubuntu:4.0

MAINTAINER konrad@tactica.de

#swift talk example code
WORKDIR /app

COPY Package.swift ./
COPY Sources ./Sources
COPY Views ./Views
COPY Resources ./Resources

RUN swift package resolve
RUN swift build

ENV PATH ${PATH}:/app/.build/debug

CMD while true; do sleep 3600; done
