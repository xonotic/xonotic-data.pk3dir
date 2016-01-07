SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
PERL ?= perl
QCCFLAGS_WATERMARK ?= $(shell git describe)
CPP := cc -xc -E
QCC ?= gmqcc
NDEBUG ?= 1
PROGS_OUT ?= $(CURDIR)/..
BUILD_MOD ?= 0

QCCVERSIONFILE := qccversion.$(shell (cd server && $(QCC) --version) > qccversion.txt && git hash-object qccversion.txt)

# We eventually need to get rid of these
QCCFLAGS_WTFS ?= \
	-Wno-field-redeclared

QCCDEFS ?= \
	-DWATERMARK="$(QCCFLAGS_WATERMARK)" \
	-DNDEBUG=$(NDEBUG) \
	-DBUILD_MOD=$(BUILD_MOD) \
	$(QCCDEFS_EXTRA)

# -Ooverlap-locals is required
QCCFLAGS ?= \
	-std=gmqcc \
	-Ooverlap-locals \
	-O3 \
	-Werror -Wall \
	$(QCCFLAGS_WTFS) \
	-flno -futf8 -fno-bail-on-werror \
	-frelaxed-switch -freturn-assignments \
	$(QCCFLAGS_EXTRA)

# xonotic build system overrides this by command line argument to turn off the update-cvarcount step
XON_BUILDSYSTEM =

.PHONY: all
all: qc

.PHONY: qc
qc: $(PROGS_OUT)/menu.dat $(PROGS_OUT)/progs.dat $(PROGS_OUT)/csprogs.dat

.PHONY: clean
clean:
	rm -f $(PROGS_OUT)/progs.dat $(PROGS_OUT)/menu.dat $(PROGS_OUT)/csprogs.dat
	rm -f tmp/*.qc tmp/*.d tmp/*.txt

$(QCCVERSIONFILE):
	$(RM) qccversion.*
	echo This file intentionally left blank. > $@

export QCC
export CPP
export QCCDEFS
export QCCFLAGS

$(PROGS_OUT)/csprogs.dat: client/progs.inc $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/client\'
	sh ./qcc.sh client $@ $<
-include tmp/client.d

$(PROGS_OUT)/progs.dat: server/progs.inc $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/server\'
	sh ./qcc.sh server $@ $<
-include tmp/server.d

$(PROGS_OUT)/menu.dat: menu/progs.inc $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/menu\'
	sh ./qcc.sh menu $@ $<
-include tmp/menu.d

.PHONY: testcase
testcase:
	cd testcase && $(QCC) $(QCCDEFS) $(QCCFLAGS) -DTESTCASE="$$TESTCASE"
