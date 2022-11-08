CPP := cc -xc -E
QCC ?= ../../../../gmqcc/gmqcc

PROGS_OUT ?= ..
WORKDIR ?= ../.tmp

QCCFLAGS_WATERMARK ?= $(shell git describe --tags --dirty='~')
VER = $(subst *,\*,$(QCCFLAGS_WATERMARK))
NDEBUG ?= 1
XONOTIC ?= 1
ENABLE_EFFECTINFO ?= 0
ENABLE_DEBUGDRAW ?= 0
ENABLE_DEBUGTRACE ?= 0
BUILD_MOD ?=

ifndef ZIP
	ifneq ($(shell which zip 2>/dev/null),)
		ZIP := zip -9mD
	endif
	ifneq ($(shell which 7z 2>/dev/null),)
		ZIP := 7z a -tzip -mx=9 -sdel
	endif
	ifneq ($(shell which 7za 2>/dev/null),)
		ZIP := 7za a -tzip -mx=9 -sdel
	endif
    ifndef ZIP
        $(warning "No zip / 7z / 7za in ($(PATH))")
        ZIP := : zip_not_found
    endif
endif

# Set to empty string to temporarily enable warnings when debugging
QCCFLAGS_WERROR ?= \
	-Werror

# We eventually need to get rid of these
QCCFLAGS_WTFS ?= \
	-Wno-field-redeclared

QCCDEFS ?= \
	-DXONOTIC=$(XONOTIC) \
	-DWATERMARK="$(QCCFLAGS_WATERMARK)" \
	-DNDEBUG=$(NDEBUG) \
	-DENABLE_EFFECTINFO=$(ENABLE_EFFECTINFO) \
	-DENABLE_DEBUGDRAW=$(ENABLE_DEBUGDRAW) \
	-DENABLE_DEBUGTRACE=$(ENABLE_DEBUGTRACE) \
	$(if $(BUILD_MOD), -DBUILD_MOD="$(BUILD_MOD)" -I$(BUILD_MOD), ) \
	$(QCCDEFS_EXTRA)

# -Ooverlap-locals is required
QCCFLAGS ?= \
	-std=gmqcc \
	-Ooverlap-locals \
	-O3 \
	$(QCCFLAGS_WERROR) \
	-Wall \
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
	$(RM) $(PROGS_OUT)/csprogs.lno
	$(RM) $(PROGS_OUT)/menu.lno
	$(RM) $(PROGS_OUT)/progs.lno
	$(RM) $(WORKDIR)/*.d
	$(RM) $(WORKDIR)/*.qc
	$(RM) $(WORKDIR)/*.txt
	$(RM) $(WORKDIR)/qccversion.*
	$(RM) $(WORKDIR)/csprogs-*
	$(RM) $(WORKDIR)/autoexec/csprogs-*.cfg
	$(RM) $(WORKDIR)/*.dat
	$(RM) csprogs-*.pk3

.PHONY: qc
qc: $(PROGS_OUT)/csprogs.dat $(PROGS_OUT)/menu.dat $(PROGS_OUT)/progs.dat

.PHONY: sv
sv: $(PROGS_OUT)/csprogs.dat $(PROGS_OUT)/progs.dat

.PHONY: pk3
pk3: csprogs-$(VER).pk3



COMPTESTS = test-server test-client test-menu
.PHONY: test $(COMPTESTS)
test: $(COMPTESTS)
$(COMPTESTS):
	tools/compilationunits.sh $@



%-$(VER).pk3: $(PROGS_OUT)/%.dat
	$(eval PROG=$*)
	$(eval PK3=$(PROG)-$(VER).pk3)
	$(eval CFG=autoexec/$(PROG)-$(VER).cfg)
	$(eval DAT=$(PROG)-$(VER).dat)
	$(eval LNO=$(PROG)-$(VER).lno)
	@ mkdir -p $(WORKDIR)/autoexec
	@ echo "// http://xonotic.org" > $(WORKDIR)/$(CFG)
	@ echo "set csqc_progname $(DAT)" >> $(WORKDIR)/$(CFG)
	@ cp -f $(PROGS_OUT)/$(PROG).dat $(WORKDIR)/$(DAT)
	@ cp -f $(PROGS_OUT)/$(PROG).lno $(WORKDIR)/$(LNO)
	@ $(RM) $(PROG)-*.pk3
	cd $(WORKDIR) && $(ZIP) $(CURDIR)/$(PK3) $(CFG) $(DAT) $(LNO)

QCCVERSION := $(shell cd lib && $(QCC) --version)
QCCVERSIONFILE := $(WORKDIR)/qccversion.$(shell echo ${QCCVERSION} | git hash-object --stdin)
$(QCCVERSIONFILE): | $(WORKDIR)
	@ $(RM) $(WORKDIR)/qccversion.*
	@ echo $(QCCVERSION) > $@

export WORKDIR
export CPP
export QCC
export QCCDEFS
export QCCFLAGS

$(PROGS_OUT)/csprogs.dat: client/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/client\'
	./tools/qcc.sh client $@ $<
-include $(WORKDIR)/client.d

$(PROGS_OUT)/progs.dat: server/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/server\'
	./tools/qcc.sh server $@ $<
-include $(WORKDIR)/server.d

$(PROGS_OUT)/menu.dat: menu/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/menu\'
	./tools/qcc.sh menu $@ $<
-include $(WORKDIR)/menu.d
