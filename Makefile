.DEFAULT_GOAL := help
scriptname := ./packer_builder.sh
.PHONY: help simplenodejs

help:
	@echo "Sets up global config files"
	@echo ""
	@echo "Targets:"
	@echo "simplenodejs   build a simple nodejs AMI"

simplenodejs: basescript selectami simplenodejs-setup build cleanup

basescript:
	-rm -f $(scriptname)
	echo "#!/bin/bash" > $(scriptname)
	echo "">> $(scriptname)
	echo "set -euo pipefail" >> $(scriptname)
	echo "" >> $(scriptname)

# Fetch latest debian-jessie from debian account
selectami:
	$(eval SOURCE_AMI := $(shell aws --region us-east-1 ec2 describe-images \
					 --owners 379101102735 \
					 --filters "Name=name,Values=debian-jessie-amd64-hvm*" \
					 --query "Images[*].[ImageId]" \
					 --output text | tail -1))
	@echo Using $(SOURCE_AMI) as base ami
	echo "export SOURCE_AMI=$(SOURCE_AMI)" >> $(scriptname)
	echo "export ROOT_USERNAME=admin" >> $(scriptname)

simplenodejs-setup:
	$(eval SYSTEM_CATEGORY = simplenodejs)

build:
	echo "export SYSTEM_CATEGORY=$(SYSTEM_CATEGORY)" >> $(scriptname)
	echo "packer build ./packer_files/$(SYSTEM_CATEGORY)_ami.json" >> $(scriptname)
	bash $(scriptname)

cleanup:
	rm $(scriptname)
