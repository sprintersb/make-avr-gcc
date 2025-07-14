# Useful commands
# ln -s $HOME/gnu/source/make-avr-gcc/Makefile Makefile
# cp    $HOME/gnu/source/make-avr-gcc/Makefile .

.PHONY: help

help:
	@echo "Make avr-gcc in Canadian Cross configuration for MinGW32."
	@echo ""
	@echo "The simplest way is to run"
	@echo "    $$ make GCC_VERSION=8.5.1 -j88 JOBS=88 install-w32"
	@echo "    $$ make GCC_VERSION=8.5.1 deploy-w32"
	@echo "which will download and prepare the sources, configure, build"
	@echo "and install a native-cross (which is needed for the canadian)"
	@echo "and a canadian-cross."
	@echo ""
	@echo "make deploy-w32 will take whatever it finds in install-w32 and"
	@echo ".tar.xz it with appropriate directory name, date and ABOUT.txt."
	@echo ""
	@echo "Notice that this Makefile assumes all required software has"
	@echo "been installed on the build machine, including a GCC toolchain,"
	@echo "a GCC cross compiler to i686-w64-mingw32 (or similar), LaTeX,"
	@echo "Doxygen v1.9.6, fig2dev and probably many more."
	@echo ""
	@echo "Makefile variables that can be adjusted on the command line:"
	@echo "* JOBS        (1)"
	@echo "* HOST_W32    (i686-w64-mingw32)"
	@echo "* GCC_VERSION (15.1)"
	@echo "* TAG_GCC     (releases/gcc-\$$(GCC_VERSION).0) except for v8.5.1"
	@echo "* TAG_BIN     (binutils-2_44)"
	@echo "* TAG_LIBC    (main)"
	@echo ""
	@echo "In order to build a GCC branch, use TAG_GCC=releases/gcc-15."
	@echo "In order to build a LibC release, use TAG_LIBC=avr-libc-2_2_1-release."
	@echo ""

# So that | tee doesn't spoil the exit status.
SHELL=/usr/bin/bash
.SHELLFLAGS = -o pipefail -ec

JOBS ?= 1
J = -j$(JOBS)

PREFIX = $(PWD)/install-host
PREFIX_W32 = $(PWD)/install-w32

HOST_W32 ?= i686-w64-mingw32
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
TAG_GCC ?= releases/gcc-$(GCC_VERSION).0
CONF_GCC = --with-long-double=64
else
URL_GCC = https://github.com/sprintersb/avr-gcc-8
GIT_GCC = https://github.com/sprintersb/avr-gcc-8.git
TAG_GCC = releases/gcc-8
CONF_GCC = --with-bugurl=https://github.com/sprintersb/avr-gcc-8/issues
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

# There is a bug where gcc/system.h defines abort() to fancy_abort(...),
# but /usr/share/mingw-w64/include/msxml.h uses abort() in a declaration,
# leading to a syntax error.  This is worked around now.
CPPFLAGS_W32 = -DWIN32_LEAN_AND_MEAN -DCOM_NO_WINDOWS_H

CONF_LIBC = --host=avr --build=$(BUILD)

TEE  = 2>&1 | tee $(PWD)
TEEa = 2>&1 | tee -a $(PWD)

# Many commands require the native-cross toolchain.
E = export PATH=$(PREFIX)/bin:$$PATH;

STAMP = echo timestamp >

### Binutils ###

s-src-bin:
	echo "=== $@ ===" $(TEE)/src-bin.log
	$(Git) $(TAG_BIN) $(GIT_BIN) src-bin $(TEEa)/src-bin.log
	$(STAMP) $@

s-conf-bin: s-src-bin
	echo "=== $@ ===" $(TEE)/conf-bin.log
	rm -rf obj-bin
	mkdir obj-bin
	cd obj-bin; ../src-bin/configure $(CONF_BIN) --prefix=$(PREFIX) $(TEEa)/conf-bin.log
	$(STAMP) $@

s-obj-bin: s-conf-bin
	echo "=== $@ ===" $(TEE)/obj-bin.log
	cd obj-bin; make $J      $(TEEa)/obj-bin.log
	cd obj-bin; make $J html $(TEEa)/obj-bin.log
#	cd obj-bin; make $J pdf  $(TEEa)/obj-bin.log
	$(STAMP) $@

s-inst-bin: s-obj-bin
	echo "=== $@ ===" $(TEE)/inst-bin.log
	cd obj-bin; make $J install      $(TEEa)/inst-bin.log
	cd obj-bin; make $J install-html $(TEEa)/inst-bin.log
#	cd obj-bin; make $J install-pdf  $(TEEa)/inst-bin.log
	$(STAMP) $@

s-conf-bin-w32: s-src-bin
	echo "=== $@ ===" $(TEE)/conf-bin-w32.log
	rm -rf obj-bin-w32
	mkdir obj-bin-w32
	cd obj-bin-w32; ../src-bin/configure $(CONF_BIN_W32) --prefix=$(PREFIX_W32) $(TEEa)/conf-bin-w32.log
	$(STAMP) $@

s-obj-bin-w32: s-conf-bin-w32
	echo "=== $@ ===" $(TEE)/obj-bin-w32.log
	cd obj-bin-w32; make $J      $(TEEa)/obj-bin-w32.log
	cd obj-bin-w32; make $J html $(TEEa)/obj-bin-w32.log
#	cd obj-bin-w32; make $J pdf  $(TEEa)/obj-bin-w32.log
	$(STAMP) $@

s-inst-bin-w32: s-obj-bin-w32
	echo "=== $@ ===" $(TEE)/inst-bin-w32.log
	cd obj-bin-w32; make $J install      $(TEEa)/inst-bin-w32.log
	cd obj-bin-w32; make $J install-html $(TEEa)/inst-bin-w32.log
#	cd obj-bin-w32; make $J install-pdf  $(TEEa)/inst-bin-w32.log
	$(STAMP) $@

### GCC ###

s-src-gcc:
	echo "=== $@ ===" $(TEE)/src-gcc.log
	$(Git) $(TAG_GCC) $(GIT_GCC) src-gcc         $(TEEa)/src-gcc.log
	cd src-gcc; ./contrib/gcc_update --touch     $(TEEa)/src-gcc.log
	cd src-gcc; ./contrib/download_prerequisites $(TEEa)/src-gcc.log
	$(STAMP) $@

s-conf-gcc: s-src-gcc s-inst-bin
	echo "=== $@ ===" $(TEE)/conf-gcc.log
	rm -rf obj-gcc
	mkdir obj-gcc
	cd obj-gcc; ../src-gcc/configure $(CONF_GCC) --prefix=$(PREFIX) $(TEEa)/conf-gcc.log
	$(STAMP) $@

s-obj-gcc: s-conf-gcc
	echo "=== $@ ===" $(TEE)/obj-gcc.log
	cd obj-gcc; make $J      $(TEEa)/obj-gcc.log
	cd obj-gcc; make $J html $(TEEa)/obj-gcc.log
#	cd obj-gcc; make $J pdf  $(TEEa)/obj-gcc.log
	$(STAMP) $@

s-inst-gcc: s-obj-gcc
	echo "=== $@ ===" $(TEE)/inst-gcc.log
	cd obj-gcc; make $J install-strip-host $(TEEa)/inst-gcc.log
	cd obj-gcc; make $J install-target     $(TEEa)/inst-gcc.log
	cd obj-gcc; make $J install-html       $(TEEa)/inst-gcc.log
#	cd obj-gcc; make $J install-pdf        $(TEEa)/inst-gcc.log
	$(STAMP) $@

s-conf-gcc-w32: s-src-gcc s-inst-bin-w32 s-inst-libc
	echo "=== $@ ===" $(TEE)/conf-gcc-w32.log
	rm -rf obj-gcc-w32
	mkdir obj-gcc-w32
	$E cd obj-gcc-w32; ../src-gcc/configure $(CONF_GCC_W32) --prefix=$(PREFIX_W32) $(TEEa)/conf-gcc-w32.log
	$(STAMP) $@

s-obj-gcc-w32: s-conf-gcc-w32
	echo "=== $@ ===" $(TEE)/obj-gcc-w32.log
	$E cd obj-gcc-w32; make $J CPPFLAGS="$(CPPFLAGS_W32)" all-host $(TEEa)/obj-gcc-w32.log
	$(STAMP) $@

s-inst-gcc-w32: s-obj-gcc-w32 s-obj-gcc s-obj-libc
	echo "=== $@ ===" $(TEE)/inst-gcc-w32.log
	$E cd obj-gcc-w32; make $J install-strip-host              $(TEEa)/inst-gcc-w32.log
	$E cd obj-gcc; make $J install-target prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
	$E cd obj-gcc; make $J install-html   prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
#	$E cd obj-gcc; make $J install-pdf    prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc; make $J install prefix=$(PREFIX_W32)       $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc/doc/api; make clean                         $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc/doc/api; make html                          $(TEEa)/inst-gcc-w32.log
#	$E cd obj-libc/doc/api; make pdf                           $(TEEa)/inst-gcc-w32.log
	$E cd obj-libc/doc/api; make install-dox-html prefix=$(PREFIX_W32) $(TEEa)/inst-gcc-w32.log
	$(STAMP) $@

### AVR-LibC ###

s-src-libc:
	echo "=== $@ ===" $(TEE)/src-libc.log
	$(Git) $(TAG_LIBC) $(GIT_LIBC) src-libc $(TEEa)/src-libc.log
	cd src-libc; ./bootstrap                $(TEEa)/src-libc.log
	$(STAMP) $@

s-conf-libc: s-src-libc s-inst-gcc
	echo "=== $@ ===" $(TEE)/conf-libc.log
	rm -rf obj-libc
	mkdir obj-libc
	$E cd obj-libc; ../src-libc/configure $(CONF_LIBC) --prefix=$(PREFIX) $(TEEa)/conf-libc.log
	$(STAMP) $@

s-obj-libc: s-conf-libc
	echo "=== $@ ===" $(TEE)/obj-libc.log
	$E cd obj-libc; make $J $(TEEa)/obj-libc.log
	$(STAMP) $@

s-inst-libc: s-obj-libc
	echo "=== $@ ===" $(TEE)/inst-libc.log
	$E cd obj-libc; make $J install $(TEEa)/inst-libc.log
	$(STAMP) $@

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
.PHONY: clean-bin clean-gcc clean-libc
.PHONY: clean-inst

.PHONY: clean-bin-w32 clean-gcc-w32
.PHONY: clean-inst-w32

# There is no really good way to separate clean-conf-foo from clean-obj-foo,
# so do them together as clean-foo.

# Similarly, there is no way to partially clean up an install.
# We use several clean targets to avoid circular dependencies.
.PHONY: clean-inst-bin clean-inst-gcc clean-inst-libc
.PHONY: clean-inst-bin-w32 clean-inst-gcc-w32

clean-src-bin: clean-bin clean-bin-w32
	rm -rf $(wildcard s-src-bin src-bin.log src-bin)

clean-src-gcc: clean-gcc clean-gcc-w32
	rm -rf $(wildcard s-src-gcc src-gcc.log src-gcc)

clean-src-libc: clean-libc
	rm -rf $(wildcard s-src-libc src-libc.log src-libc)

clean-bin: clean-gcc clean-inst-bin
	rm -rf $(wildcard s-conf-bin conf-bin.log)
	rm -rf $(wildcard s-obj-bin   obj-bin.log obj-bin)

clean-bin-w32: clean-inst-bin-w32 clean-gcc-w32
	rm -rf $(wildcard s-conf-bin-w32 conf-bin-w32.log)
	rm -rf $(wildcard s-obj-bin-w32   obj-bin-w32.log obj-bin-w32)

clean-gcc: clean-inst-gcc clean-libc
	rm -rf $(wildcard s-conf-gcc conf-gcc.log)
	rm -rf $(wildcard s-obj-gcc   obj-gcc.log obj-gcc)

clean-gcc-w32: clean-inst-gcc-w32
	rm -rf $(wildcard s-conf-gcc-w32 conf-gcc-w32.log)
	rm -rf $(wildcard s-obj-gcc-w32   obj-gcc-w32.log obj-gcc-w32)

clean-libc: clean-inst-libc clean-inst-gcc-w32
	rm -rf $(wildcard s-conf-libc conf-libc.log)
	rm -rf $(wildcard s-obj-libc   obj-libc.log obj-libc)

clean-inst-bin clean-inst-gcc clean-inst-libc:
	rm -rf $(wildcard s-inst-bin s-inst-gcc s-inst-libc)
	rm -rf $(wildcard $(PREFIX) inst-bin.log inst-gcc.log inst-libc.log)

clean-inst-bin-w32 clean-inst-gcc-w32:
	rm -rf $(wildcard s-inst-bin-w32 s-inst-gcc-w32)
	rm -rf $(wildcard $(PREFIX_W32) inst-bin-w32.log inst-gcc-w32.log)

clean-inst-bin: clean-gcc
clean-inst-gcc: clean-libc
clean-inst-libc clean-inst-bin-w32: clean-gcc-w32
clean-libc: clean-inst-gcc-w32

clean-inst-w32: clean-inst-bin-w32 clean-inst-gcc-w32

clean-inst: clean-inst-bin clean-inst-gcc clean-inst-libc

.PHONY: clean-w32 clean-host

clean-host: clean-bin clean-gcc clean-libc

clean-w32: clean-bin-w32 clean-gcc-w32

make.png: make.dot
	dot $< -Tpng > $@
