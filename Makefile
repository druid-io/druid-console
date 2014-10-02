ROOT_DIR := $(shell pwd)
PATH := ${ROOT_DIR}/node/current/bin:${ROOT_DIR}/node_modules/.bin:${PATH}

all: compile

init: install-node install-custom-node-modules install-node-modules copy-bower-css-and-fonts
#
# node
#

install-node:
	make/install-node

install-node-modules:
	@npm install

install-custom-node-modules:
	make/install-custom-node-modules

copy-bower-css-and-fonts:
	@mkdir -p static/css
	@cp bower_components/bootstrap/dist/css/bootstrap-theme.css bower_components/bootstrap/dist/css/bootstrap.css bower_components/font-awesome/css/font-awesome.css static/css
	@mkdir -p static/fonts
	@cp bower_components/font-awesome/fonts/* static/fonts

#
# app
#

compile:
	@mkdir -p target/src
	@cd target && ln -s ../build && ln -s ../static
	@cd target/src && ln -s ../../src/server

jenkins-release: clean init compile

#
# clean
#

clean-all: clean clean-node clean-node-modules

clean:
	@rm -rfv target

clean-node-modules:
	@rm -rfv node_modules

clean-node:
	@rm -rfv node
