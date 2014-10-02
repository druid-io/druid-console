#!/bin/bash

export PATH="./node/current/bin:./node_modules/.bin:$PATH"
exec coffee "./src/server/server.coffee"
