druid-console
=============

This repository contains a standalone web application ([angularjs](https://angularjs.org) in `src/client/druid.coffee`).  The web app can be built into the druid source, and will be served by druid's built-in jetty server.

## Standalone console build instructions

Prerequisites: [node](http://nodejs.org/), [compass](http://compass-style.org/)

Install node packages:  `npm install`

Install bower packages: `bower install`

The druid repo and this repo should be siblings under the same parent directory.  The `build-into-druid` bash script will compile the coffeescript and the sass into the `build` directory, and then copy them into the druid source at `../druid/server/src/main/resources/static`.  If you wish to build to a different location, edit the DEST in `build-into-druid`.

## Built-in proxy server

This repo also includes a webserver that can proxy to various druid installations if they are present in zookeeper.  To run the server, export the dns name of your zookeeper and the discovery path into environment variables, and then run `run-server`, like so:

```
export ZK_HOSTNAME="zookeeper.sweet.com"
export ZK_SERVICE_DISC_PATH="/path/to/discovery"
./run-server
```
