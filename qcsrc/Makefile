SCM := $(shell if [ -d .svn ]; then echo svn; elif [ -d ../.git ]; then echo git; fi)
PERL ?= perl
QCCFLAGS_WATERMARK ?= -DWATERMARK='"$(shell git describe)"'
QCC ?= gmqcc
QCCDEFS_EXTRA ?= -DGMQCC
NDEBUG ?= 1
BUILD_MOD ?= 0

QCCVERSIONFILE := qccversion.$(shell (cd server && $(QCC) --version) > qccversion.txt && git hash-object qccversion.txt)

# We eventually need to get rid of these
QCCFLAGS_WTFS ?= \
	-Wno-field-redeclared

QCCDEFS ?= \
	$(QCCFLAGS_WATERMARK) \
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
qc: ../menu.dat ../progs.dat ../csprogs.dat

.PHONY: clean
clean:
	rm -f ../progs.dat ../menu.dat ../csprogs.dat
	rm -f tmp/*.qc tmp/*.d tmp/*.txt

$(QCCVERSIONFILE):
	$(RM) qccversion.*
	echo This file intentionally left blank. > $@

../csprogs.dat: client/progs.inc $(QCCVERSIONFILE)
	@$(CC) -xc $(QCCDEFS) -DCSQC -E -dM 1>tmp/client_macros.txt -H 2>tmp/client_includes.txt $<
	$(CC) -xc $(QCCDEFS) -DCSQC -E -MMD -MP -MT $@ -Wall -Wundef -Werror -CC -o tmp/client.qc $<
	@sed -i 's/^# \([[:digit:]]\+\) "\(.*\)".*/\n#pragma file(\2)\n#pragma line(\1)/g' tmp/client.qc
	@echo make[1]: Entering directory \`$(PWD)/client\'
	cd client && $(QCC) $(QCCFLAGS) -o ../$@ ../tmp/client.qc
-include tmp/client.d

../progs.dat: server/progs.inc $(QCCVERSIONFILE)
	@$(CC) -xc $(QCCDEFS) -DSVQC -E -dM 1>tmp/server_macros.txt -H 2>tmp/server_includes.txt $<
	$(CC) -xc $(QCCDEFS) -DSVQC -E -MMD -MP -MT $@ -Wall -Wundef -Werror -CC -o tmp/server.qc $<
	@sed -i 's/^# \([[:digit:]]\+\) "\(.*\)".*/\n#pragma file(\2)\n#pragma line(\1)/g' tmp/server.qc
	@echo make[1]: Entering directory \`$(PWD)/server\'
	cd server && $(QCC) $(QCCFLAGS) -o ../$@ ../tmp/server.qc
-include tmp/server.d

../menu.dat: menu/progs.inc $(QCCVERSIONFILE)
	@$(CC) -xc $(QCCDEFS) -DMENUQC -E -dM 1>tmp/menu_macros.txt -H 2>tmp/menu_includes.txt $<
	$(CC) -xc $(QCCDEFS) -DMENUQC -E -MMD -MP -MT $@ -Wall -Wundef -Werror -CC -o tmp/menu.qc $<
	@sed -i 's/^# \([[:digit:]]\+\) "\(.*\)".*/\n#pragma file(\2)\n#pragma line(\1)/g' tmp/menu.qc
	@echo make[1]: Entering directory \`$(PWD)/menu\'
	cd menu && $(QCC) $(QCCFLAGS) -o ../$@ ../tmp/menu.qc
-include tmp/menu.d

.PHONY: testcase
testcase:
	cd testcase && $(QCC) $(QCCDEFS) $(QCCFLAGS) -DTESTCASE="$$TESTCASE"
