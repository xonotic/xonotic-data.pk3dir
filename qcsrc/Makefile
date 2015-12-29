SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
PERL ?= perl
QCCFLAGS_WATERMARK ?= -DWATERMARK='"$(shell git describe)"'
QCC ?= gmqcc
NDEBUG ?= 1

QCCVERSIONFILE := qccversion.$(shell (cd server && $(QCC) --version) > qccversion.txt && git hash-object qccversion.txt)

# We eventually need to get rid of these
QCCFLAGS_WTFS ?= \
	-Wno-field-redeclared

QCCFLAGS_FEATURES ?= \
	-DBUILD_MOD=$(BUILD_MOD)

# -Ooverlap-locals is required
QCCFLAGS ?= \
	-std=gmqcc \
	-Ooverlap-locals \
	-O3 \
	-Werror -Wall -Wcpp \
	$(QCCFLAGS_WTFS) \
	-fftepp -flno -futf8 -fno-bail-on-werror -fftepp-predefs \
	-frelaxed-switch -freturn-assignments \
	$(QCCFLAGS_WATERMARK) \
	-DNDEBUG=$(NDEBUG) \
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
	rm -f progs.d menu.d csprogs.d

$(QCCVERSIONFILE):
	$(RM) qccversion.*
	echo This file intentionally left blank. > $@

../csprogs.dat: client/progs.inc $(QCCVERSIONFILE)
	@$(CC) -MM -MP -MF csprogs.d -MT $@ -x c -DCSQC -o $@ $<
	@echo make[1]: Entering directory \`$(PWD)/client\'
	cd client && $(QCC) $(QCCFLAGS) -DCSQC -o ../$@ ../$<
-include csprogs.d

../progs.dat: server/progs.inc $(QCCVERSIONFILE)
	@$(CC) -MM -MP -MF progs.d -MT $@ -x c -DSVQC -o $@ $<
	@echo make[1]: Entering directory \`$(PWD)/server\'
	cd server && $(QCC) $(QCCFLAGS) -DSVQC -o ../$@ ../$<
-include progs.d

../menu.dat: menu/progs.inc $(QCCVERSIONFILE)
	@$(CC) -MM -MP -MF menu.d -MT $@ -x c -DMENUQC -o $@ $<
	@echo make[1]: Entering directory \`$(PWD)/menu\'
	cd menu && $(QCC) $(QCCFLAGS) -DMENUQC -o ../$@ ../$<
-include menu.d

.PHONY: testcase
testcase:
	cd testcase && $(QCC) $(QCCFLAGS) -DTESTCASE="$$TESTCASE"
