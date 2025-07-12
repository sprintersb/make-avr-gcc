# Useful commands
# ln -s $HOME/gnu/source/make-avr-gcc/Makefile Makefile
# cp    $HOME/gnu/source/make-avr-gcc/Makefile .

.PHONY: help

help:
	echo "Help"

# So that | tee doesn't spoil the exit status.
SHELL=/usr/bin/bash
.SHELLFLAGS = -o pipefail -ec

PREFIX = $(PWD)/install-host
PREFIX_W32 = $(PWD)/install-w32

HOST_W32 = i686-w64-mingw32
BUILD = $(shell $(PWD)/src-libc/config.guess)

# For now, we only support cloning from Git repos.
# Notice that after --branch there may be a branch or tag name.
Git = git clone --depth 1 --branch

# Binutils tags are like binutils-2_42.
# Binutils branches are like master.
GIT_BIN = git://sourceware.org/git/binutils-gdb.git
TAG_BIN ?= binutils-2_44

GCC_VERSION ?= 15.1

# GCC branches are like releases/gcc-15 or trunk.
# GCC tags are like releases/gcc-15.1.0

ifneq ($(GCC_VERSION),8.5.1)
URL_GCC = https://gcc.gnu.org
GIT_GCC = git://gcc.gnu.org/git/gcc.git
TAG_GCC = releases/gcc-$(GCC_VERSION).0
CONF_GCC = --with-long-double=64
else
URL_GCC = https://github.com/sprintersb/avr-gcc-8
GIT_GCC = https://github.com/sprintersb/avr-gcc-8.git
TAG_GCC = releases/gcc-8
endif

# AVR-LibC tags are like avr-libc-2_2_1-release.
# AVR-LibC branches are like main.

GIT_LIBC = https://github.com/avrdudes/avr-libc.git
TAG_LIBC ?= main

# For now, disable GDB so we don't need GMP etc.
CONF_BIN = --target=avr --disable-nls --disable-werror --disable-sim --disable-gdb
CONF_BIN_W32 = $(CONF_BIN) --host=$(HOST_W32) --build=$(BUILD)

CONF_GCC += --target=avr --enable-languages=c,c++
CONF_GCC += --with-gnu-as --with-gnu-ld --with-dwarf2
CONF_GCC += --disable-nls --disable-libcc1 --disable-libssp --disable-plugin
CONF_GCC += --enable-checking=release

CONF_GCC_W32 = $(CONF_GCC) --host=$(HOST_W32) --build=$(BUILD) --enable-mingw-wildcard

CONF_LIBC = --host=avr --build=$(BUILD)

TEE  = 2>&1 | tee $(PWD)
TEEa = 2>&1 | tee -a $(PWD)

# Maky commands require the native-cross toolchain.
E = export PATH=$(PREFIX)/bin:$$PATH;

### Binutils ###

s-src-bin:
	$(Git) $(TAG_BIN) $(GIT_BIN) src-bin $(TEE)/src-bin.log
	touch $@

s-conf-bin: s-src-bin
	rm -rf obj-bin
	mkdir obj-bin
	cd obj-bin; ../src-bin/configure $(CONF_BIN) --prefix=$(PREFIX) $(TEE)/conf-bin.log
	touch $@

s-obj-bin: s-conf-bin
	cd obj-bin; make -j44 $(TEE)/obj-bin.log
	cd obj-bin; make -j44 html $(TEEa)/obj-bin.log
#	cd obj-bin; make -j44 pdf  $(TEEa)/obj-bin.log
	touch $@

s-inst-bin: s-obj-bin
	cd obj-bin; make -j44 install $(TEE)/inst-bin.log
	cd obj-bin; make -j44 install-html $(TEEa)/inst-bin.log
#	cd obj-bin; make -j44 install-pdf  $(TEEa)/inst-bin.log
	touch $@

s-conf-bin-w32: s-src-bin
	rm -rf obj-bin-w32
	mkdir obj-bin-w32
	cd obj-bin-w32; ../src-bin/configure $(CONF_BIN_W32) --prefix=$(PREFIX_W32) $(TEE)/conf-bin-w32.log
	touch $@

s-obj-bin-w32: s-conf-bin-w32
	cd obj-bin-w32; make -j44 $(TEE)/obj-bin-w32.log
	cd obj-bin-w32; make -j44 html $(TEEa)/obj-bin-w32.log
#	cd obj-bin-w32; make -j44 pdf  $(TEEa)/obj-bin-w32.log
	touch $@

s-inst-bin-w32: s-obj-bin-w32
	cd obj-bin-w32; make -j44 install $(TEE)/inst-bin-w32.log
	cd obj-bin-w32; make -j44 install-html $(TEEa)/inst-bin-w32.log
#	cd obj-bin-w32; make -j44 install-pdf  $(TEEa)/inst-bin-w32.log
	touch $@

### GCC ###

s-src-gcc:
	$(Git) $(TAG_GCC) $(GIT_GCC) src-gcc $(TEE)/src-gcc.log
	cd src-gcc; ./contrib/gcc_update --touch     $(TEEa)/src-gcc.log
	cd src-gcc; ./contrib/download_prerequisites $(TEEa)/src-gcc.log
	touch $@

s-conf-gcc: s-src-gcc s-inst-bin
	rm -rf obj-gcc
	mkdir obj-gcc
	cd obj-gcc; ../src-gcc/configure $(CONF_GCC) --prefix=$(PREFIX) $(TEE)/conf-gcc.log
	touch $@

s-obj-gcc: s-conf-gcc
	cd obj-gcc; make -j88 $(TEE)/obj-gcc.log
	cd obj-gcc; make -j44 html $(TEEa)/obj-gcc.log
#	cd obj-gcc; make -j44 pdf  $(TEEa)/obj-gcc.log
	touch $@

s-inst-gcc: s-obj-gcc
	cd obj-gcc; make -j88 install-strip-host $(TEE)/inst-gcc.log
	cd obj-gcc; make -j88 install-target     $(TEEa)/inst-gcc.log
	cd obj-gcc; make -j44 install-html $(TEEa)/inst-gcc.log
#	cd obj-gcc; make -j44 install-pdf  $(TEEa)/inst-gcc.log
	touch $@

s-conf-gcc-w32: s-inst-gcc
	rm -rf obj-gcc-w32
	mkdir obj-gcc-w32
	$E cd obj-gcc-w32; ../src-gcc/configure $(CONF_GCC_W32) --prefix=$(PREFIX_W32) $(TEE)/conf-gcc-w32.log
	touch $@

s-obj-gcc-w32: s-conf-gcc-w32
	$E cd obj-gcc-w32; make -j88 all-host $(TEE)/obj-gcc-w32.log
	touch $@

s-inst-gcc-w32: s-obj-gcc-w32 install-host s-obj-libc
	$E cd obj-gcc-w32; make -j88 install-strip-host $(TEE)/inst-gcc-w32.log
	$E cd obj-gcc; make -j88 install-target prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
	$E cd obj-gcc; make -j44 install-html   prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
#	$E cd obj-gcc; make -j44 install-pdf    prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc; make -j44 install prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc/doc/api; make clean $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc/doc/api; make html  $(TEEa)/inst-gcc-w32.log
#	$E cd obj-libc/doc/api; make pdf   $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc/doc/api; make install-dox-html prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
	touch $@

### AVR-LibC ###

s-src-libc:
	$(Git) $(TAG_LIBC) $(GIT_LIBC) src-libc $(TEE)/src-libc.log
	cd src-libc; ./bootstrap               $(TEEa)/src-libc.log
	touch $@

s-conf-libc: s-src-libc s-inst-gcc
	rm -rf obj-libc
	mkdir obj-libc
	$E cd obj-libc; ../src-libc/configure $(CONF_LIBC) --prefix=$(PREFIX) $(TEE)/conf-libc.log
	touch $@

s-obj-libc: s-conf-libc
	$E cd obj-libc; make -j88 $(TEE)/obj-libc.log
	touch $@

s-inst-libc: s-obj-libc
	$E cd obj-libc; make -j88 install $(TEE)/inst-libc.log
	touch $@

.PHONY: all-host all-w32 install-host install-w32

all-host: s-obj-bin s-obj-gcc s-obj-libc

all-w32:  s-obj-bin-w32 s-obj-gcc-w32 s-obj-libc # sic! no s-obj-libc-w32

install-host: s-inst-bin s-inst-gcc s-inst-libc

install-w32: s-inst-bin-w32 s-inst-gcc-w32 # sic! no s-inst-libc-w32

.PHONY: deploy-w32

GIT_ID = git log -n1 --pretty=format:'%H (%as) %s'

ABOUT.txt: FORCE
	echo "=== GCC ===" > $@
	echo "git: $(GIT_GCC)" >> $@
	echo "branch/tag: $(TAG_GCC)" >> $@
	echo "hash: $$(cd src-gcc; $(GIT_ID))" >> $@
	echo >> $@
	echo "=== Binutils ===" >> $@
	echo "git: $(GIT_BIN)" >> $@
	echo "branch/tag: $(TAG_BIN)" >> $@
	echo "hash: $$(cd src-bin; $(GIT_ID))" >> $@
	echo >> $@
	echo "=== AVR-LibC ===" >> $@
	echo "git: $(GIT_LIBC)" >> $@
	echo "branch/tag: $(TAG_LIBC)" >> $@
	echo "hash: $$(cd src-libc; $(GIT_ID))" >> $@

FORCE:

WNAME = avr-gcc-$(GCC_VERSION)_$(shell date -u +'%F')_mingw32
HNAME = avr-gcc-$(GCC_VERSION)_$(shell date -u +'%F')_x86_64

deploy-w32: ABOUT.txt
	cp ABOUT.txt install-w32
	ln -s install-w32 $(WNAME)
	tar chfJ $(WNAME).tar.xz $(WNAME)
	md5sum $(WNAME).tar.xz > $(WNAME).tar.xz.md5
	unlink $(WNAME)

deploy-x86_64: ABOUT.txt
	cp ABOUT.txt install-host
	ln -s install-host $(HNAME)
	tar chfJ $(HNAME).tar.xz $(HNAME)
	md5sum $(HNAME).tar.xz > $(HNAME).tar.xz.md5
	unlink $(HNAME)

.PHONY: clean-src-bin clean-src-gcc clean-src-libc
.PHONY: clean-conf-bin clean-conf-gcc clean-conf-libc
.PHONY: clean-obj-bin clean-obj-gcc clean-obj-libc
.PHONY: clean-inst

.PHONY: clean-conf-bin-w32 clean-conf-gcc-w32
.PHONY: clean-obj-bin-w32 clean-obj-gcc-w32
.PHONY: clean-inst-w32

clean-src-bin: clean-conf-bin clean-conf-bin-w32
	rm -rf $(wildcard s-src-bin src-bin src-bin.log)

clean-conf-bin: clean-obj-bin
	rm -rf $(wildcard s-conf-bin conf-bin.log)

clean-conf-bin-w32: clean-obj-bin-w32
	rm -rf $(wildcard s-conf-bin-w32 conf-bin-w32.log)

clean-obj-bin: clean-inst
	rm -rf $(wildcard s-obj-bin obj-bin obj-bin.log)

clean-obj-bin-w32: clean-inst-w32
	rm -rf $(wildcard s-obj-bin-w32 obj-bin-w32 obj-bin-w32.log)

clean-src-gcc: clean-conf-gcc clean-conf-gcc-w32
	rm -rf $(wildcard s-src-gcc src-gcc src-gcc.log)

clean-conf-gcc: clean-obj-gcc
	rm -rf $(wildcard s-conf-gcc conf-gcc.log)

clean-conf-gcc-w32: clean-obj-gcc-w32
	rm -rf $(wildcard s-conf-gcc-w32 conf-gcc-w32.log)

clean-obj-gcc: clean-inst
	rm -rf $(wildcard s-obj-gcc obj-gcc obj-gcc.log)

clean-obj-gcc-w32: clean-inst-w32
	rm -rf $(wildcard s-obj-gcc-w32 obj-gcc-w32 obj-gcc-w32.log)

clean-src-libc: clean-conf-libc
	rm -rf $(wildcard s-src-libc src-libc src-libc.log)

clean-conf-libc: clean-obj-libc
	rm -rf $(wildcard s-conf-libc conf-libc.log)

clean-obj-libc: clean-inst
	rm -rf $(wildcard s-obj-libc obj-libc obj-libc.log)

clean-inst:
	rm -rf $(wildcard s-inst-bin s-inst-gcc s-inst-libc $(PREFIX) inst-bin.log inst-gcc.log inst-libc.log)

clean-inst-w32:
	rm -rf $(wildcard s-inst-bin-w32 s-inst-gcc-w32 $(PREFIX_W32) inst-bin-w32.log inst-gcc-w32.log)

.PHONY: clean-w32 clean-host

clean-host: clean-obj-bin clean-obj-gcc clean-obj-libc

clean-w32: clean-obj-bin-w32 clean-obj-gcc-w32
