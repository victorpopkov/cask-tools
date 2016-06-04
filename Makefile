PREFIX ?= /usr/local

help:
	@echo "Please use \`make <target>' where <target> is one of:\n"
	@echo "   test      to perform tests."
	@echo "   install   to install. Use PREFIX to customize."

# Bats is used for testing: https://github.com/sstephenson/bats
test:
	bats test/

.PHONY: help test
