PREFIX ?= /usr/local

help:
	@echo "Please use \`make <target>' where <target> is one of:\n"
	@echo "   install     to install. Use PREFIX to customize."
	@echo "   uninstall   to uninstall. Use PREFIX to customize."
	@echo "   test        to perform tests."

install:
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@mkdir -p ${DESTDIR}${PREFIX}/lib/cask-scripts
	@cp -f bin/* ${DESTDIR}${PREFIX}/bin
	@cp -R lib/* ${DESTDIR}${PREFIX}/lib

uninstall:
	@rm -fR ${DESTDIR}${PREFIX}/lib/cask-scripts
	@rm -f ${DESTDIR}${PREFIX}/bin/cask-appcast
	@rm -f ${DESTDIR}${PREFIX}/bin/cask-check-updates
	@rm -f ${DESTDIR}${PREFIX}/bin/cask-homepage

# Bats is used for testing: https://github.com/sstephenson/bats
test:
	test/bats/bin/bats test/

.PHONY: help install uninstall test
