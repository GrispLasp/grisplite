# EXCLUDE_FROM_SOURCE="_build,_grisp,config,_elixir_build"
 # see : https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=898744
 # https://www.gnu.org/software/make/manual/html_grisplite/MAKE-Variable.html#MAKE-Variable
 # https://www.gnu.org/software/make/manual/html_grisplite/Options_002fRecursion.html#Options_002fRecursion
 # https://www.gnu.org/software/make/manual/html_grisplite/Instead-of-Execution.html#Instead-of-Execution
 # http://erlang.org/pipermail/erlang-questions/2001-November/004120.html
 # https://www3.ntu.edu.sg/home/ehchua/programming/cpp/gcc_make.html
 # http://erlang.org/pipermail/erlang-questions/2002-January/004295.html
REBAR            ?= $(shell which rebar3)
# REVISION 		    ?= $(shell git rev-parse --short HEAD)
GRISPAPP         ?= $(shell basename `find src -name "*.app.src"` .app.src)
BASE_DIR         ?= $(shell pwd)
DEPLOYMENTS_DIR		?= $(BASE_DIR)/priv/deployment_args
GRISPFILES_DIR		?= $(BASE_DIR)/grisp/grisp_base/files
CACHE_DIR         ?= $(HOME)/.cache/rebar3
# ERLANG_BIN       ?= $(shell dirname $(shell which erl))
# HOSTNAME         ?= $(shell hostname)
COOKIE           ?= MyCookie
VERSION 	       ?= 0.1.0
DEPLOY_DEST		?=	/media/laymer/GRISP
# MAKE						 = make
#
# .PHONY: grispbuild rel deps plots dcos logs fpm no-cfg-build tarball-build \
# 	build compile-no-deps test docs xref dialyzer-run dialyzer-quick dialyzer \
# 	cleanplt upload-docs wipeout clean cacheclean rebar3
# EXCLUDE=$(subst src/bar.cpp,,${SRC_FILES})
# SRC_FILES = $(filter-out $(wildcard ./_*))

# .PHONY: grispbuild rel deps test plots dcos logs fpm no-cfg-build tarball-build build

.PHONY: compile testshell shell 2shell 3shell deploy 10deploy 11deploy rel stage doubledeploy ndeploy \
	# cleaning targets :
	wipe clean buildclean grispclean cacheclean elixirclean checkoutsclean ⁠\
	# currently not working targets :
	build no-cfg-build tarball-build \
	# Others
	test-app-src prod-app-src

all: compile

##
## Compilation targets
##


compile:
	$(REBAR) compile

# rebar3_grisp build call to sh(./otp_build boot -a) forces single directory change that make cannot overwrite
# open issue?
build:
	$(REBAR) grisp build

no-cfg-build:
	$(REBAR) grisp build -c false

tarball-build:
	$(REBAR) grisp build -t true

#
# Cleaning targets
#

wipe: clean grispclean
	$(REBAR) update
	$(REBAR) unlock
	$(REBAR) upgrade

clean: buildclean elixirclean checkoutsclean cacheclean
	$(REBAR) clean

buildclean:
	rm -rdf $(BASE_DIR)/_build

grispclean:
	rm -rdf $(BASE_DIR)/_grisp

elixirclean:
	$(foreach var,$(shell find $(BASE_DIR)/elixir_libs/ -type d -name "_build"),rm -rdf $(var);)
	rm -rdf $(BASE_DIR)/_elixir_build

cacheclean:
	rm -rdf $(CACHE_DIR)/hex
	rm -rdf $(CACHE_DIR)/plugins/rebar3_grisp
checkoutsclean:
	rm -rdf $(BASE_DIR)/_checkouts/*/ebin/*
#
# Test targets
#
shell: test-app-src
	$(REBAR) shell --sname $(GRISPAPP) --setcookie $(COOKIE) --apps grisplite

testshell: test-app-src
	$(REBAR) as test shell --sname $(GRISPAPP) --setcookie $(COOKIE) --apps grisplite

2shell: test-app-src
	$(REBAR) as test shell --sname $(GRISPAPP)2 --setcookie $(COOKIE) --apps grisplite

3shell: test-app-src
	$(REBAR) as test shell --sname $(GRISPAPP)3 --setcookie $(COOKIE) --apps grisplite

test-app-src:
	cp $(BASE_DIR)/src/grisplite.app.src $(BASE_DIR)/src/grisplite.app.src.prod
	cp $(DEPLOYMENTS_DIR)/grisplite.app.src.test $(BASE_DIR)/src/grisplite.app.src



##
## Release targets
##

rel: prod-app-src
	$(REBAR) release

stage: prod-app-src
	$(REBAR) release -d

# deploy: prod-app-src
# 	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION)
#
# 1deploy: prod-app-src
# 	cp $(DEPLOYMENTS_DIR)/1/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
# 	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION)
#
# 2deploy: prod-app-src
# 	cp $(DEPLOYMENTS_DIR)/2/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
# 	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION)


doubledeploy: deploy 1deploy
	echo "deployed"

ndeploy:
	cp $(DEPLOYMENTS_DIR)/$(n)/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
	rm -rdf $(DEPLOY_DEST)$(d)/*
	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION) --destination $(DEPLOY_DEST)$(d) --force true
	umount $(DEPLOY_DEST)$(d)

deploy:
	# cp $(DEPLOYMENTS_DIR)/$(n)/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
	rm -rdf $(DEPLOY_DEST)/*
	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION) --destination $(DEPLOY_DEST) --force true
	umount $(DEPLOY_DEST)

1deploy:
	cp $(DEPLOYMENTS_DIR)/2/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
	rm -rdf $(DEPLOY_DEST)1/*
	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION) --destination $(DEPLOY_DEST)1 --force true
	umount $(DEPLOY_DEST)1

3deploy:
	cp $(DEPLOYMENTS_DIR)/3/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
	rm -rdf $(DEPLOY_DEST)/*
	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION) --destination $(DEPLOY_DEST) --force true
	umount $(DEPLOY_DEST)

10deploy: prod-app-src
	cp $(DEPLOYMENTS_DIR)/10/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION)

11deploy: prod-app-src
	cp $(DEPLOYMENTS_DIR)/11/grisp.ini.mustache $(GRISPFILES_DIR)/grisp.ini.mustache
	$(REBAR) grisp deploy -n $(GRISPAPP) -v $(VERSION)

prod-app-src:
	cp $(BASE_DIR)/src/grisplite.app.src.prod $(BASE_DIR)/src/grisplite.app.src
