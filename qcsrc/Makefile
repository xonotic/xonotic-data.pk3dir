SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
PERL ?= perl
QCCFLAGS_WATERMARK ?= -DWATERMARK='"$(shell git describe)"'
QCC ?= gmqcc
 
QCCVERSIONFILE := qccversion.$(shell (cd server && $(QCC) --version) > qccversion.txt && git hash-object qccversion.txt)

# We eventually need to get rid of these.
QCCFLAGS_WTFS ?= \
	-Wno-field-redeclared

QCCFLAGS_FEATURES ?= \
	-DVEHICLES_ENABLED=1 \
	-DVEHICLES_USE_ODE=0 \
	-DBUILD_MOD=$(BUILD_MOD)

QCCFLAGS ?= \
	-std=gmqcc \
	-O3 \
	-Werror -Wall -Wcpp \
	$(QCCFLAGS_WTFS) \
	-fftepp -flno -futf8 -fno-bail-on-werror -fftepp-predefs \
	-frelaxed-switch -freturn-assignments \
	$(QCCFLAGS_WATERMARK) \
	$(QCCFLAGS_FEATURES) \
	$(QCCFLAGS_EXTRA)

# xonotic build system overrides this by command line argument to turn off the update-cvarcount step
XON_BUILDSYSTEM =

.PHONY: all
all: qc

.PHONY: qc
qc: ../menu.dat ../progs.dat ../csprogs.dat

.PHONY: clean
clean:
	rm -f ../progs.dat ../menu.dat ../csprogs.dat

$(QCCVERSIONFILE):
	$(RM) qccversion.*
	echo This file intentionally left blank. > $@

FILES_CSPROGS = $(shell find client lib common warpzonelib csqcmodellib -type f -not -name fteqcc.log -not -name qc.asm)
../csprogs.dat: $(FILES_CSPROGS) $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/client\'
	cd client && $(QCC) $(QCCFLAGS) -DCSQC

FILES_PROGS = $(shell find server lib common warpzonelib csqcmodellib -type f -not -name fteqcc.log -not -name qc.asm)
../progs.dat: $(FILES_PROGS) $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/server\'
	cd server && $(QCC) $(QCCFLAGS) -DSVQC

FILES_MENU = $(shell find menu lib common warpzonelib -type f -not -name fteqcc.log -not -name qc.asm)
../menu.dat: $(FILES_MENU) $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/menu\'
	cd menu && $(QCC) $(QCCFLAGS) -DMENUQC

.PHONY: testcase
testcase:
	cd testcase && $(QCC) $(QCCFLAGS) -DTESTCASE="$$TESTCASE"
