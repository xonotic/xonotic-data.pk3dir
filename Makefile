SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
PERL ?= perl
ZIP ?= 7za a -tzip -mx=9
ZIPEXCLUDE ?= -x\!*.pk3 -xr\!\.svn -x\!qcsrc
DIFF ?= diff

# xonotic build system overrides this by command line argument to turn off the check-cvars step
XON_BUILDSYSTEM =

.PHONY: all
all: check-cvars
	$(MAKE) -C qcsrc all

.PHONY: check-cvars
check-cvars:
	[ "$(XON_BUILDSYSTEM)" = "" ] || [ "$(XON_BUILDSYSTEM)" = "1" ]
	[ "$(XON_BUILDSYSTEM)" = "1" ] || { DO_NOT_RUN_MAKE=1 sh check-cvars.sh; }

.PHONY: qc
qc: check-cvars
	$(MAKE) -C qcsrc qc

.PHONY: skin
skin: gfx/menu/default/skinvalues.txt

.PHONY: clean
clean:
	$(MAKE) -C qcsrc clean

gfx/menu/default/skinvalues.txt: qcsrc/menu/skin-customizables.inc
	$(PERL) qcsrc/menu/skin-customizables.inc > gfx/menu/default/skinvalues.txt

.PHONY: sv
sv:
	$(MAKE) -C qcsrc sv

.PHONY: pk3
pk3:
	$(MAKE) -C qcsrc pk3
