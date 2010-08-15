SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
FTEQCC ?= fteqcc
PERL ?= perl
ZIP ?= 7za a -tzip -mx=9
ZIPEXCLUDE ?= -x\!*.pk3 -xr\!\.svn -x\!qcsrc
DIFF ?= diff

FTEQCCFLAGS_WATERMARK ?= -DWATERMARK='"^1$(shell git describe) TEST BUILD"'
FTEQCCFLAGS ?= -Werror -Wall -Wno-mundane -O3 -Ono-c -Ono-cs -flo $(FTEQCCFLAGS_EXTRA) $(FTEQCCFLAGS_WATERMARK)
FTEQCCFLAGS_PROGS ?= 
FTEQCCFLAGS_MENU ?= 

# NOTE: use -DUSE_FTE instead of -TFTE here!
# It will automagically add an engine check with -TID and then change back to -TFTE
FTEQCCFLAGS_CSPROGS ?= 

# xonotic build system overrides this by command line argument to turn off the update-cvarcount step
XON_BUILDSYSTEM =

all: qc

.PHONY: update-cvarcount
update-cvarcount:
	[ "$(XON_BUILDSYSTEM)" = "" ] || [ "$(XON_BUILDSYSTEM)" = "1" ]
	[ "$(XON_BUILDSYSTEM)" = "1" ] || { DO_NOT_RUN_MAKE=1 sh update-cvarcount.sh; }

.PHONY: qc
qc: update-cvarcount
	$(MAKE) qc-recursive

.PHONY: qc-recursive
qc-recursive: menu.dat progs.dat csprogs.dat

.PHONY: skin
skin: gfx/menu/default/skinvalues.txt

.PHONY: clean
clean:
	rm -f progs.dat menu.dat csprogs.dat

csprogs.dat: qcsrc/client/*.* qcsrc/common/*.* qcsrc/warpzonelib/*.*
	@echo make[1]: Entering directory \`$(PWD)/qcsrc/client\'
	cd qcsrc/client && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_CSPROGS)

progs.dat: qcsrc/server/*.* qcsrc/common/*.* qcsrc/server/*/*.* qcsrc/server/*/*/*.* qcsrc/warpzonelib/*.*
	@echo make[1]: Entering directory \`$(PWD)/qcsrc/server\'
	cd qcsrc/server && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_PROGS)

menu.dat: qcsrc/menu/*.* qcsrc/menu/*/*.* qcsrc/common/*.*
	@echo make[1]: Entering directory \`$(PWD)/qcsrc/menu\'
	cd qcsrc/menu && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_MENU)

gfx/menu/default/skinvalues.txt: qcsrc/menu/skin-customizables.inc
	$(PERL) qcsrc/menu/skin-customizables.inc > gfx/menu/default/skinvalues.txt

.PHONY: testcase
testcase:
	cd qcsrc/testcase && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_CSPROGS) -DTESTCASE="$$TESTCASE"
