PREFIX ?= /usr/local

help:
	@echo "Please use \`make <target>' where <target> is one of:\n"
	@echo "   test      to perform tests."
	@echo "   install   to install. Use PREFIX to customize."

# Bats is used for testing: https://github.com/sstephenson/bats
test:
	bats test/

install:
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@mkdir -p ${DESTDIR}${PREFIX}/libexec/cask-scripts
	@cp -f bin/* ${DESTDIR}${PREFIX}/bin
	@cp -R libexec/* ${DESTDIR}${PREFIX}/libexec

uninstall:
	@rm -R ${DESTDIR}${PREFIX}/libexec/cask-scripts
	@rm ${DESTDIR}${PREFIX}/bin/cask-appcast
	@rm ${DESTDIR}${PREFIX}/bin/cask-check-updates

.PHONY: help test
