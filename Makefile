ROOT_DIR := $(shell pwd)
PATH := ${ROOT_DIR}/node/current/bin:${ROOT_DIR}/node_modules/.bin:${PATH}

all: compile

init: install-node-modules install-bower-components copy-bower-css-and-fonts
#
# node
#

install-node-modules:
	@npm install

install-bower-components:
	@bower install

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

#
# clean
#

clean-all: clean clean-node-modules

clean:
	@rm -rfv target

clean-node-modules:
	@rm -rfv node_modules

clean-bower-components:
	@rm -rfv bower_components
	@rm -rfv static/css
	@rm -rfv static/fonts
