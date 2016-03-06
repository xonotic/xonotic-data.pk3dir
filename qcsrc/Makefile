QCCFLAGS_WATERMARK ?= $(shell git describe --tags --dirty=*)
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
all: qc pk3

.PHONY: qc
qc: $(PROGS_OUT)/menu.dat $(PROGS_OUT)/progs.dat $(PROGS_OUT)/csprogs.dat

.PHONY: pk3
pk3: qc
	$(eval PROG=csprogs)
	$(eval VER=${QCCFLAGS_WATERMARK})
	$(eval PK3=${PROG}-${VER}.pk3)
	$(eval TXT=${PROG}-${VER}.txt)
	$(eval DAT=${PROG}-${VER}.dat)
	$(eval LNO=${PROG}-${VER}.lno)
	@ echo "http://xonotic.org" > ${TXT}
	@ ln -f $(PROGS_OUT)/${PROG}.dat ${DAT}
	@ ln -f $(PROGS_OUT)/${PROG}.lno ${LNO}
	@ rm -f *.pk3
	zip -9 ${PK3} ${TXT} ${DAT} ${LNO}
	@ rm ${TXT} ${DAT} ${LNO}

.PHONY: clean
clean:
	rm -f $(PROGS_OUT)/csprogs.dat
	rm -f $(PROGS_OUT)/progs.dat
	rm -f $(PROGS_OUT)/menu.dat
	rm -f ../.tmp/*.qc
	rm -f ../.tmp/*.d
	rm -f ../.tmp/*.txt

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
-include ../.tmp/client.d

$(PROGS_OUT)/progs.dat: server/progs.inc $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/server\'
	sh ./qcc.sh server $@ $<
-include ../.tmp/server.d

$(PROGS_OUT)/menu.dat: menu/progs.inc $(QCCVERSIONFILE)
	@echo make[1]: Entering directory \`$(PWD)/menu\'
	sh ./qcc.sh menu $@ $<
-include ../.tmp/menu.d

.PHONY: testcase
testcase:
	cd testcase && $(QCC) $(QCCDEFS) $(QCCFLAGS) -DTESTCASE="$$TESTCASE"
