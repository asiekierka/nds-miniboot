# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Adrian "asie" Siekierka, 2024

export WONDERFUL_TOOLCHAIN ?= /opt/wonderful
export BLOCKSDS ?= /opt/blocksds/core

# Tools
# -----

LUA		:= $(WONDERFUL_TOOLCHAIN)/bin/wf-lua
DLDIPATCH	:= $(BLOCKSDS)/tools/dldipatch/dldipatch
NDSTOOL		:= $(BLOCKSDS)/tools/ndstool/ndstool
CC		:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-gcc
OBJCOPY		:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-objcopy
CP		:= cp
MAKE		:= make
MKDIR		:= mkdir
RM		:= rm -rf

# Verbose flag
# ------------

ifeq ($(V),1)
_V		:=
else
_V		:= @
endif

# Build rules
# -----------

ARM9ELF		:= build/arm9.elf
ARM7ELF		:= build/arm7.elf
NDSROM		:= build/miniboot.nds

SCRIPT_R4CRYPT		:= scripts/r4crypt.lua

NDSROM_ACE3DS_DLDI	:= blobs/dldi/acep.dldi
NDSROM_AK2_DLDI		:= blobs/dldi/ak2.dldi
NDSROM_DSONE_DLDI	:= blobs/dldi/scds.dldi
NDSROM_DSONE_SDHC_DLDI	:= blobs/dldi/scdssdhc.dldi
NDSROM_DSTT_DLDI	:= blobs/dldi/ttio.dldi
NDSROM_EZ5_DLDI		:= blobs/dldi/ez5h.dldi
NDSROM_EZ5N_DLDI	:= blobs/dldi/ez5n.dldi
NDSROM_GMTF_DLDI	:= blobs/dldi/gmtf.dldi
NDSROM_MKR6_DLDI	:= blobs/dldi/nmk6.dldi
NDSROM_R4_DLDI		:= blobs/dldi/r4tf.dldi
NDSROM_R4DSPRO_DLDI	:= blobs/dldi/ak2_cmd24.dldi
NDSROM_R4IDSN_DLDI	:= blobs/dldi/r4idsn.dldi
NDSROM_STARGATE_DLDI	:= blobs/dldi/sg3d.dldi

NDSROM_ACE3DS		:= dist/ace3dsplus/_ds_menu.dat
NDSROM_AK2		:= dist/generic/akmenu4.nds
NDSROM_DSONE	:= dist/generic/scfw.sc
NDSROM_DSONE_SDHC	:= dist/dsonesdhc/scfw.sc
NDSROM_DSTT		:= dist/generic/ttmenu.dat
NDSROM_EDGEI	:= dist/generic/dsedgei.dat
NDSROM_EZ5		:= dist/generic/ez5sys.bin
NDSROM_EZ5N		:= dist/generic/ezds.dat
NDSROM_GMTF		:= dist/generic/bootme.nds
NDSROM_GWBLUE		:= dist/gwblue/_dsmenu.dat
NDSROM_MKR6		:= dist/mkr6/_boot_ds.nds
NDSROM_R4		:= dist/generic/_DS_MENU.DAT
NDSROM_R4DSPRO	:= dist/r4dspro/_ds_menu.dat
NDSROM_R4IDSN		:= dist/r4idsn/_dsmenu.dat
NDSROM_R4ILS		:= dist/ace3dsplus/_dsmenu.dat
NDSROM_R4ISDHC		:= dist/generic/r4.dat
NDSROM_R4ITT		:= dist/r4itt/_ds_menu.dat
NDSROM_STARGATE		:= dist/stargate/_ds_menu.dat

.PHONY: all clean arm9 arm7

all: \
	$(NDSROM) \
	$(NDSROM_ACE3DS) \
	$(NDSROM_AK2) \
	$(NDSROM_DSONE) \
	$(NDSROM_DSONE_SDHC) \
	$(NDSROM_DSTT) \
	$(NDSROM_EDGEI) \
	$(NDSROM_EZ5) \
	$(NDSROM_EZ5N) \
	$(NDSROM_GMTF) \
	$(NDSROM_GWBLUE) \
	$(NDSROM_MKR6) \
	$(NDSROM_R4) \
	$(NDSROM_R4DSPRO) \
	$(NDSROM_R4IDSN) \
	$(NDSROM_R4ILS) \
	$(NDSROM_R4ISDHC) \
	$(NDSROM_R4ITT) \
	$(NDSROM_STARGATE)
	$(_V)$(CP) LICENSE README.md dist/

$(NDSROM_ACE3DS): $(NDSROM) $(NDSROM_ACE3DS_DLDI) $(SCRIPT_R4CRYPT)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_ACE3DS_DLDI) $@
	@echo "  R4CRYPT $@"
	$(_V)$(LUA) $(SCRIPT_R4CRYPT) $@ 4002

$(NDSROM_GWBLUE): arm9 arm7 $(NDSROM_ACE3DS_DLDI) $(SCRIPT_R4CRYPT)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000450 -e9 0x2000450 -h 0x200 \
		-g "####" "##" "R4IT"
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_ACE3DS_DLDI) $@
	@echo "  R4CRYPT $@"
	$(_V)$(LUA) $(SCRIPT_R4CRYPT) $@ 4002

$(NDSROM_R4ILS): arm9 arm7 $(NDSROM_ACE3DS_DLDI) $(SCRIPT_R4CRYPT)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000450 -e9 0x2000450 -h 0x200 \
		-g "####" "##" "R4XX"
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_ACE3DS_DLDI) $@
	@echo "  R4CRYPT $@"
	$(_V)$(LUA) $(SCRIPT_R4CRYPT) $@ 4002

$(NDSROM_R4IDSN): arm9 arm7 $(NDSROM_R4IDSN_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000000 -e9 0x2000000 -h 0x200
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_R4IDSN_DLDI) $@

$(NDSROM_MKR6): arm9 arm7 $(NDSROM_MKR6_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000000 -e9 0x2000000 -h 0x200
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_MKR6_DLDI) $@

$(NDSROM_R4ITT): arm9 arm7 $(NDSROM_AK2_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000800 -e9 0x2000800 -h 0x200
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_AK2_DLDI) $@

$(NDSROM_DSONE): arm9 arm7 $(NDSROM_DSONE_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000450 -e9 0x2000450 -h 0x200 \
		-g "ENG0"
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_DSONE_DLDI) $@

$(NDSROM_DSONE_SDHC): arm9 arm7 $(NDSROM_DSONE_SDHC_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000450 -e9 0x2000450 -h 0x200 \
		-g "ENG0"
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_DSONE_SDHC_DLDI) $@

$(NDSROM_R4ISDHC): arm9_r4isdhc arm7 $(NDSROM_DSTT_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9_r4isdhc.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000000 -e9 0x2000450 -h 0x200
	@echo "  DLDI    $@"
	$(_V)$(DLDIPATCH) patch $(NDSROM_DSTT_DLDI) $@

$(NDSROM_R4): $(NDSROM) $(NDSROM_R4_DLDI) $(SCRIPT_R4CRYPT)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_R4_DLDI) $@
	@echo "  R4CRYPT $@"
	$(_V)$(LUA) $(SCRIPT_R4CRYPT) $@

$(NDSROM_AK2) $(NDSROM_EDGEI): $(NDSROM) $(NDSROM_AK2_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_AK2_DLDI) $@

$(NDSROM_EZ5): $(NDSROM) $(NDSROM_EZ5_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_EZ5_DLDI) $@

$(NDSROM_EZ5N): $(NDSROM) $(NDSROM_EZ5N_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_EZ5N_DLDI) $@
	$(_V)sed -i "s|\xED\xA5\x8D\xBF|\x00\x00\x00\x00|g" $@

$(NDSROM_GMTF): $(NDSROM) $(NDSROM_GMTF_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_GMTF_DLDI) $@

$(NDSROM_R4DSPRO): $(NDSROM) $(NDSROM_R4DSPRO_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_R4DSPRO_DLDI) $@

$(NDSROM_STARGATE): $(NDSROM) $(NDSROM_STARGATE_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_STARGATE_DLDI) $@

$(NDSROM_DSTT): $(NDSROM) $(NDSROM_DSTT_DLDI)
	@$(MKDIR) -p $(@D)
	@echo "  DLDI    $@"
	$(_V)$(CP) $(NDSROM) $@
	$(_V)$(DLDIPATCH) patch $(NDSROM_DSTT_DLDI) $@

$(NDSROM): arm9 arm7
	@$(MKDIR) -p $(@D)
	@echo "  NDSTOOL $@"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-9 build/arm9.bin -7 build/arm7.bin \
		-r7 0x2380000 -e7 0x2380000 \
		-r9 0x2000450 -e9 0x2000450 -h 0x200

clean:
	@echo "  CLEAN"
	$(_V)$(RM) build dist	

arm9:
	$(_V)+$(MAKE) -f Makefile.miniboot TARGET=arm9 --no-print-directory

arm9_r4isdhc: arm9
	@echo "  R4ISDHC"
	$(_V)$(CC) -o build/r4isdhc_pad.elf -nostartfiles -Tsource/misc/r4isdhc_pad.ld source/misc/r4isdhc_pad.s
	$(_V)$(OBJCOPY) -O binary build/r4isdhc_pad.elf build/r4isdhc_pad.bin
	$(_V)cat build/r4isdhc_pad.bin build/arm9.bin > build/arm9_r4isdhc.bin
	$(_V)truncate -s 433264 build/arm9_r4isdhc.bin

arm7:
	$(_V)+$(MAKE) -f Makefile.miniboot TARGET=arm7 --no-print-directory
