CPP := cc -xc -E
QCC ?= gmqcc

PROGS_OUT ?= $(CURDIR)/..
WORKDIR ?= ../.tmp

QCCFLAGS_WATERMARK ?= $(shell git describe --tags --dirty='*')
VER = $(QCCFLAGS_WATERMARK)
NDEBUG ?= 1
BUILD_MOD ?= 0

ifndef ZIP
	ifneq ($(shell which zip),)
		ZIP := zip -9
	endif
	ifneq ($(shell which 7z),)
		ZIP := 7z a -tzip -mx=9
	endif
	ifneq ($(shell which 7za),)
		ZIP := 7za a -tzip -mx=9
	endif
    ifndef ZIP
        $(warning "No zip in ($(PATH))")
        ZIP := : zip_not_found
    endif
endif

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



.PHONY: all
all: qc pk3

$(WORKDIR):
	@mkdir -p $@

.PHONY: clean
clean: | $(WORKDIR)
	$(RM) $(PROGS_OUT)/csprogs.dat
	$(RM) $(PROGS_OUT)/menu.dat
	$(RM) $(PROGS_OUT)/progs.dat
	$(RM) $(WORKDIR)/*.d
	$(RM) $(WORKDIR)/*.qc
	$(RM) $(WORKDIR)/*.txt

.PHONY: qc
qc: $(PROGS_OUT)/csprogs.dat $(PROGS_OUT)/menu.dat $(PROGS_OUT)/progs.dat

.PHONY: pk3
pk3: csprogs-$(VER).pk3





%-$(VER).pk3: $(PROGS_OUT)/%.dat
	$(eval PROG=$*)
	$(eval PK3=$(PROG)-$(VER).pk3)
	$(eval TXT=$(PROG)-$(VER).txt)
	$(eval DAT=$(PROG)-$(VER).dat)
	$(eval LNO=$(PROG)-$(VER).lno)
	@ echo "http://xonotic.org" > $(TXT)
	@ ln -f $(PROGS_OUT)/$(PROG).dat $(DAT)
	@ ln -f $(PROGS_OUT)/$(PROG).lno $(LNO)
	@ $(RM) *.pk3
	$(ZIP) $(PK3) $(TXT) $(DAT) $(LNO)
	@ $(RM) $(TXT) $(DAT) $(LNO)

QCCVERSION := $(shell cd lib && $(QCC) --version)
QCCVERSIONFILE := $(WORKDIR)/qccversion.$(shell echo ${QCCVERSION} | git hash-object --stdin)
$(QCCVERSIONFILE): | $(WORKDIR)
	@ $(RM) $(WORKDIR)/qccversion.*
	@ echo $(QCCVERSION) > $@

export CPP
export QCC
export QCCDEFS
export QCCFLAGS

$(PROGS_OUT)/csprogs.dat: client/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/client\'
	@ ./qcc.sh client $@ $<
-include $(WORKDIR)/client.d

$(PROGS_OUT)/progs.dat: server/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/server\'
	@ ./qcc.sh server $@ $<
-include $(WORKDIR)/server.d

$(PROGS_OUT)/menu.dat: menu/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/menu\'
	@ ./qcc.sh menu $@ $<
-include $(WORKDIR)/menu.d
