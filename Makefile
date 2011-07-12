SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
FTEQCC ?= fteqcc
PERL ?= perl
ZIP ?= 7za a -tzip -mx=9
ZIPEXCLUDE ?= -x\!*.pk3 -xr\!\.svn -x\!qcsrc
DIFF ?= diff

FTEQCCFLAGS_WATERMARK ?= -DWATERMARK='"$(shell git describe)"' -DCVAR_POPCON
FTEQCCFLAGS ?= -Werror -Wno-Q302 -O3 -Ono-c -Ono-cs $(FTEQCCFLAGS_EXTRA) $(FTEQCCFLAGS_WATERMARK)
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

FILES_CSPROGS = $(shell find qcsrc/client qcsrc/common qcsrc/warpzonelib -type f -not -name fteqcc.log -not -name qc.asm) qcsrc/server/w_*.qc
csprogs.dat: $(FILES_CSPROGS)
	@echo make[1]: Entering directory \`$(PWD)/qcsrc/client\'
	cd qcsrc/client && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_CSPROGS)

FILES_PROGS = $(shell find qcsrc/server qcsrc/common qcsrc/warpzonelib -type f -not -name fteqcc.log -not -name qc.asm) qcsrc/server/w_*.qc
progs.dat: $(FILES_PROGS)
	@echo make[1]: Entering directory \`$(PWD)/qcsrc/server\'
	cd qcsrc/server && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_PROGS)

FILES_MENU = $(shell find qcsrc/menu qcsrc/common qcsrc/warpzonelib -type f -not -name fteqcc.log -not -name qc.asm) qcsrc/server/w_*.qc
menu.dat: $(FILES_MENU)
	@echo make[1]: Entering directory \`$(PWD)/qcsrc/menu\'
	cd qcsrc/menu && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_MENU)

gfx/menu/default/skinvalues.txt: qcsrc/menu/skin-customizables.inc
	$(PERL) qcsrc/menu/skin-customizables.inc > gfx/menu/default/skinvalues.txt

.PHONY: testcase
testcase:
	cd qcsrc/testcase && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_CSPROGS) -DTESTCASE="$$TESTCASE"
