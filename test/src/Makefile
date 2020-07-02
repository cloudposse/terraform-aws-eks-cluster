PACKAGE  = terraform-aws-eks-cluster
GOEXE   ?= $(shell which go)

export TF_DATA_DIR ?= $(CURDIR)/.terraform
export TF_CLI_ARGS_init ?= -get-plugins=true

.PHONY: all
## Default target
all: test

ifneq (,$(wildcard /sbin/apk))
## Install go, if not installed
$(GOEXE):
	apk add --update go
endif

.PHONY : init
## Initialize tests
init: $(GOEXE)
	@exit 0

.PHONY : test
## Run tests
test: init
	$(GOEXE) mod download
	$(GOEXE) test -v -timeout 60m -run TestExamplesComplete

## Run tests in docker container
docker/test:
	docker run -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e GITHUB_TOKEN -v $(CURDIR)/../../:/module/ golang:1.13 make -C /module/test/src test

.PHONY : clean
## Clean up files
clean:
	rm -rf $(TF_DATA_DIR)
