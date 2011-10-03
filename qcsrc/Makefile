SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
FTEQCC ?= fteqcc
PERL ?= perl

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

.PHONY: qc
qc:
	$(MAKE) qc-recursive

.PHONY: qc-recursive
qc-recursive: ../menu.dat ../progs.dat ../csprogs.dat

.PHONY: clean
clean:
	rm -f ../progs.dat ../menu.dat ../csprogs.dat

FILES_CSPROGS = $(shell find client common warpzonelib -type f -not -name fteqcc.log -not -name qc.asm) $(wildcard server/w_*.qc)
../csprogs.dat: $(FILES_CSPROGS)
	@echo make[1]: Entering directory \`$(PWD)/client\'
	cd client && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_CSPROGS)

FILES_PROGS = $(shell find server common warpzonelib -type f -not -name fteqcc.log -not -name qc.asm) $(wildcard server/w_*.qc)
../progs.dat: $(FILES_PROGS)
	@echo make[1]: Entering directory \`$(PWD)/server\'
	cd server && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_PROGS)

FILES_MENU = $(shell find menu common warpzonelib -type f -not -name fteqcc.log -not -name qc.asm) $(wildcard server/w_*.qc)
../menu.dat: $(FILES_MENU)
	@echo make[1]: Entering directory \`$(PWD)/menu\'
	cd menu && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_MENU)

.PHONY: testcase
testcase:
	cd testcase && $(FTEQCC) $(FTEQCCFLAGS) $(FTEQCCFLAGS_CSPROGS) -DTESTCASE="$$TESTCASE"
