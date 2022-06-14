# Makefile for vertica-demo

QUERY?=select version();
SHELL:=/bin/bash

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' "$(firstword $(MAKEFILE_LIST))"

# Keep a copy of the default conf
.PHONY: config
config: etc/vertica-demo.conf ## Edit the configuration file
	@echo "Editing configuration settings in $$PWD/etc/vertica-demo.conf"
	@if [[ -x $$VISUAL ]] ; then \
	  "$$VISUAL" "$$PWD/etc/vertica-demo.conf"; \
	elif [[ -x $$EDITOR ]] ; then \
	  "$$EDITOR" "$$PWD/etc/vertica-demo.conf"; \
	else \
	  echo "Could not find editor $$VISUAL"; \
	fi

.PHONY: env
env: ## set up an environment by running "eval $(env)"
	@echo 'PATH="'$$PWD'/bin:$$PATH"'

# create new conf file or update timestamp if exists
etc/vertica-demo.conf: etc/vertica-demo.conf.default
	@cp -n etc/vertica-demo.conf.default etc/vertica-demo.conf || touch etc/vertica-demo.conf

.PHONY: vertica-install
vertica-install: etc/vertica-demo.conf ## Create a vertica container and start the database.
	@bin/vertica-install

.PHONY: vertica-stop
vertica-stop: ## Stop the vertica container.
	@bin/vertica-stop

.PHONY: vertica-start
vertica-start: etc/vertica-demo.conf ## start/restart the vertica container.
	@bin/vertica-start

.PHONY: vertica-uninstall
vertica-uninstall: ## Remove the vertica container.
	@bin/vertica-uninstall

.PHONY: vsql
vsql: ## Run a basic sanity test (optional -DQUERY="select 'whatever')
	@bin/vsql -c "$(QUERY)"

.PHONY: verticalab-start
verticalab-start: etc/vertica-demo.conf ## Start a jupyterlab
	@bin/verticalab

# this builds the image from the python base image for the purposes of
# updating it on dockerhub.  Not necessary for running the demo.
.PHONY: verticalab-build
verticalab-build:
	@bin/verticalab-build

.PHONY: verticalab-install
verticalab-install: etc/vertica-demo.conf ## Build the image to use for the demo
	@ source etc/vertica-demo.conf; \
	docker pull "vertica/$${VERTICALAB_IMG:-verticapy-jupyterlab}:latest"; \
	docker tag "vertica/$${VERTICALAB_IMG:-verticapy-jupyterlab}:latest" "$${VERTICALAB_IMG:-verticapy-jupyterlab}:latest"

.PHONY: verticalab-stop
verticalab-stop: ## Shut down the jupyterlab server and remove the container
	@ source etc/vertica-demo.conf; \
	docker stop "$${VERTICALAB_CONTAINER_NAME:-verticalab}"

.PHONY: get-ip
get-ip: etc/vertica-demo.conf ## Get the ip of the Vertica container
	@ source etc/vertica-demo.conf; \
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$${VERTICA_CONTAINER_NAME:-vertica-demo}"

.PHONY: test
test: ## suite of tests to make sure everything is working
	@ source etc/vertica-demo.conf; \
	docker exec -i "$${VERTICALAB_CONTAINER_NAME:-verticalab}" vsql -c "select version();"
