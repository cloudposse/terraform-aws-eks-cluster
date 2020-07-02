PACKAGE  = terraform-aws-eks-cluster
GOEXE   ?= /usr/bin/go

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

.PHONY : test
## Run tests
test: $(GOEXE)
	go mod download
	go test -v -timeout 60m -run TestExamplesComplete

.PHONY : clean
## Clean up files
clean:
	rm -rf $(GOEXE) $(TF_DATA_DIR)
