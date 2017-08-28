#!/bin/bash

VERSION=2.7.1
PORT=1234

java -jar wiremock-standalone-$VERSION.jar --port $PORT
