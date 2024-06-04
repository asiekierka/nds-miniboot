// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#include "common.h"
#include "bios.h"
#include "dka.h"
#include "bootstub.h"
#include "dldi_patch.h"
#include "ff.h"
#include "console.h"

// #define DEBUG

static FATFS fs;

#define DLDI_BACKUP   ((DLDI_INTERFACE*) 0x6820000)

/* === Error reporting === */

void checkErrorFatFs(const char *msg, int result) {
    if (result == FR_OK) return;

    const char *error_detail = NULL;
    switch (result) {
        case FR_DISK_ERR: error_detail = "Drive I/O error."; break;
        case FR_INT_ERR: case FR_INVALID_PARAMETER: error_detail = "Internal FatFs error."; break;
        case FR_NOT_READY: error_detail = "Drive not ready."; break;
        case FR_NO_FILE: case FR_NO_PATH: error_detail = "File not found."; break;
        case FR_NO_FILESYSTEM: error_detail = "FAT filesystem not found.\nIs the memory card formatted\ncorrectly?"; break;
    }

    eprintf("%s.\n", msg);
    if (error_detail != NULL) {
        eprintf("%s", error_detail);
    } else {
        eprintf("FatFs error %d.", result);
    }

    while(1);
}

/* === Main logic === */

#define IPC_ARM7_NONE  0x000
#define IPC_ARM7_COPY  0x100
#define IPC_ARM7_RESET 0x200
#define IPC_ARM7_SYNC  0xF00

void ipc_arm7_cmd(uint32_t cmd) {
    uint32_t next_sync = REG_IPCSYNC & 0xF;
    uint32_t last_sync = next_sync;
    REG_IPCSYNC = cmd;
    while (last_sync == next_sync) next_sync = REG_IPCSYNC & 0xF;
}

const char *executable_path = "/BOOT.NDS";

int main(void) {
    FIL fp;
    unsigned int bytes_read;
    int result;

    // Initialize VRAM (128KB to main engine, rest to CPU, 32KB WRAM to ARM7).
    REG_VRAMCNT_ABCD = VRAMCNT_ABCD(0x81, 0x80, 0x82, 0x8A);
    REG_VRAMCNT_EFGW = VRAMCNT_EFGW(0x80, 0x80, 0x80, 0x03);
    REG_VRAMCNT_HI = VRAMCNT_HI(0x80, 0x80);

    REG_POWCNT = POWCNT_LCD | POWCNT_2D_MAIN | POWCNT_DISPLAY_SWAP;
    // Ensure ARM9 has control over the cartridge slots.
    REG_EXMEMCNT = 0x6000; // ARM9 memory priority, ARM9 slot access, "slow" GBA timings

    // Reset display.
    displayReset();

    // If holding START while booting, or DEBUG is defined, enable 
    // debug output.
#ifndef NDEBUG
#ifdef DEBUG
    debugEnabled = true;
#else
    debugEnabled = !(REG_KEYINPUT & KEY_START);
#endif
#endif

    dprintf("ARM7 sync");
    for (int i = 1; i <= 16; i++) {
        dprintf(".");
        ipc_arm7_cmd((i << 8) & 0xF00);
    }
    dprintf(" OK\n");

    // Create a bootstub in memory, if one doesn't already exist.
    if (DKA_BOOTSTUB->magic != DKA_BOOTSTUB_MAGIC) {
        uint8_t *bootstub_loc = ((uint8_t*) DKA_BOOTSTUB) + sizeof(dka_bootstub_t);
        uint8_t *arm9_bin_loc = bootstub_loc + bootstub_size;
        uint8_t *arm7_bin_loc = arm9_bin_loc + NDS_HEADER->arm9_size;
        
        bootstub.arm9_target_entry = arm9_bin_loc;
        bootstub.arm7_target_entry = arm7_bin_loc;

        __aeabi_memcpy(bootstub_loc, &bootstub, bootstub_size);
        __aeabi_memcpy(arm9_bin_loc, (void*) NDS_HEADER->arm9_start, NDS_HEADER->arm9_size);
        __aeabi_memcpy(arm7_bin_loc, (void*) NDS_HEADER->arm7_start, NDS_HEADER->arm7_size);

        DKA_BOOTSTUB->magic = DKA_BOOTSTUB_MAGIC;
        DKA_BOOTSTUB->arm9_entry = bootstub_loc;
        DKA_BOOTSTUB->arm7_entry = bootstub_loc + 4;
        DKA_BOOTSTUB->loader_size = 0;
    }

    // Create a copy of the DLDI driver in VRAM before initializing it.
    // We'll make use of this copy for patching the ARM9 binary later.
    __aeabi_memcpy4(DLDI_BACKUP, &_io_dldi_stub, 16384);

    // Mount the filesystem. Try to open BOOT.NDS.
    dprintf("Mounting FAT filesystem... ");
    checkErrorFatFs("Could not mount FAT filesystem", f_mount(&fs, "", 1));
    dprintf("OK\n");
    checkErrorFatFs("Could not find BOOT.NDS", f_open(&fp, executable_path, FA_READ));
    dprintf("BOOT.NDS found.\n");

    // Read the .nds file header.
    checkErrorFatFs("Could not read BOOT.NDS", f_read(&fp, NDS_HEADER, sizeof(nds_header_t), &bytes_read));

    bool waiting_arm7 = false;
    // Load the ARM7 binary.
    {
        dprintf("ARM7: %d bytes @ %X\n", NDS_HEADER->arm7_size, NDS_HEADER->arm7_start);
        bool in_main_ram = IN_RANGE_EX(NDS_HEADER->arm7_start, 0x2000000, 0x23BFE00);
        bool in_arm7_ram = IN_RANGE_EX(NDS_HEADER->arm7_start, 0x37F8000, 0x380FE00);
        if (!NDS_HEADER->arm7_size
            || !IN_RANGE_EX(NDS_HEADER->arm7_entry - NDS_HEADER->arm7_start, 0, NDS_HEADER->arm7_size)
            || (!in_main_ram && !in_arm7_ram)
            || (in_main_ram && !IN_RANGE_EX(NDS_HEADER->arm7_start + NDS_HEADER->arm7_size, 0x2000001, 0x23BFE01))
            || (in_arm7_ram && !IN_RANGE_EX(NDS_HEADER->arm7_start + NDS_HEADER->arm7_size, 0x37F8001, 0x380FE01))) {
            eprintf("Invalid ARM7 binary location."); while(1);
        }

        checkErrorFatFs("Could not read BOOT.NDS", f_lseek(&fp, NDS_HEADER->arm7_offset));
        checkErrorFatFs("Could not read BOOT.NDS", f_read(&fp, (void*) (in_arm7_ram ? 0x2000000 : NDS_HEADER->arm7_start), NDS_HEADER->arm7_size, &bytes_read));

        // If the ARM7 binary has to be relocated to ARM7 RAM, the ARM7 CPU
        // has to relocate it from main memory.
        if (in_arm7_ram) {
            REG_IPCFIFOSEND = NDS_HEADER->arm7_size;
            REG_IPCFIFOSEND = 0x2000000;
            REG_IPCFIFOSEND = NDS_HEADER->arm7_start;
            ipc_arm7_cmd(IPC_ARM7_COPY);
            waiting_arm7 = true;
        }
    }

    // Load the ARM9 binary.
    {
        dprintf("ARM9: %d bytes @ %X\n", NDS_HEADER->arm9_size, NDS_HEADER->arm9_start);
        bool in_main_ram = IN_RANGE_EX(NDS_HEADER->arm9_start, 0x2000000, 0x23BFE00);
        if (!NDS_HEADER->arm9_size
            || !IN_RANGE_EX(NDS_HEADER->arm9_entry - NDS_HEADER->arm9_start, 0, NDS_HEADER->arm9_size)
            || !in_main_ram
            || !IN_RANGE_EX(NDS_HEADER->arm9_start + NDS_HEADER->arm9_size, 0x2000001, 0x23BFE01)) {
            eprintf("Invalid ARM9 binary location."); while(1);
        }

        checkErrorFatFs("Could not read BOOT.NDS", f_lseek(&fp, NDS_HEADER->arm9_offset));
        if (waiting_arm7) {
            ipc_arm7_cmd(IPC_ARM7_NONE);
            waiting_arm7 = false;
        }
        checkErrorFatFs("Could not read BOOT.NDS", f_read(&fp, (void*) NDS_HEADER->arm9_start, NDS_HEADER->arm9_size, &bytes_read));

        // Try to apply the DLDI driver patch.
        result = dldi_patch_relocate((void*) NDS_HEADER->arm9_start, NDS_HEADER->arm9_size, DLDI_BACKUP);
        if (result) {
            eprintf("Failed to apply DLDI patch.\n");
            switch (result) {
                case DLPR_NOT_ENOUGH_SPACE: eprintf("Not enough space."); break;
            }
            while(1);
        }
    }

    // Set up argv.
    DKA_ARGV->cmdline = (char*) 0x2FFFEB0;
    DKA_ARGV->cmdline_size = strlen(executable_path) + 1;
    __aeabi_memcpy(DKA_ARGV->cmdline, executable_path, DKA_ARGV->cmdline_size);
    DKA_ARGV->magic = DKA_ARGV_MAGIC;

    dprintf("Launching");

    // If debug enabled, wait for user to stop holding START
    if (debugEnabled) while (!(REG_KEYINPUT & KEY_START));

    // Restore/clear system state.
    displayReset();
    REG_EXMEMCNT = 0xE880;

    // Start the ARM7 binary.
    ipc_arm7_cmd(IPC_ARM7_RESET);

    // Start the ARM9 binary.
    swiSoftReset();
}
