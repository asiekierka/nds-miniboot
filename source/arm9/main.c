// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#include "common.h"
#include "bios.h"
#include "dldi_patch.h"
#include "ff.h"
#include "console.h"

// #define DEBUG

static FATFS fs;

/**
 * @brief ARM7 communication port.
 *
 * We only need ARM9->ARM7 communication and acknowledgement,
 * so relying on a single memory value is fine. IPC FIFO might be better,
 * though...
 */
extern volatile uint32_t arm7_comms_port;
#define WAIT_ARM7_ACK() while (arm7_comms_port)

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

__attribute__((noreturn))
extern void finish(void);

int main(void) {
    FIL fp;
    unsigned int bytes_read;
    int result;

    WAIT_ARM7_ACK();

    // Reset display.
    displayReset();

    // Initialize VRAM (128KB to main engine, 384KB to CPU).
    REG_VRAMCNT_ABCD = VRAMCNT_ABCD(0x81, 0x80, 0x80, 0x80);

    // Ensure ARM9 has control over the cartridge slots.
    // Restoring this variable to its previous state is required!
    uint16_t old_exmemcnt = REG_EXMEMCNT;
    REG_EXMEMCNT = 0x4000; // ARM9 memory priority, ARM9 slot access, "slow" GBA timings

    // If holding START while booting, or DEBUG is defined, enable 
    // debug output.
#ifndef NDEBUG
#ifdef DEBUG
    debugEnabled = true;
#else
    debugEnabled = !(REG_KEYINPUT & KEY_START);
#endif
#endif

    // Create a copy of the DLDI driver in VRAM before initializing it.
    // We'll make use of this copy for patching the ARM9 binary later.
    __aeabi_memcpy4(DLDI_BACKUP, &_io_dldi_stub, 16384);

    // Mount the filesystem. Try to open BOOT.NDS.
    dprintf("Mounting FAT filesystem... ");
    checkErrorFatFs("Could not mount FAT filesystem", f_mount(&fs, "", 1));
    dprintf("OK\n");
    checkErrorFatFs("Could not find BOOT.NDS", f_open(&fp, "/BOOT.NDS", FA_READ));
    dprintf("BOOT.NDS found.\n");

    // Read the .nds file header.
    checkErrorFatFs("Could not read BOOT.NDS", f_read(&fp, NDS_HEADER, sizeof(nds_header_t), &bytes_read));

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
            arm7_comms_port = NDS_HEADER->arm7_size;
            WAIT_ARM7_ACK();
            arm7_comms_port = NDS_HEADER->arm7_start;
            // No WAIT_ARM7_ACK here - allow it to copy asynchronously.
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
        // Finish copying ARM7 binary, if necessary, before writing more data to main RAM.
        WAIT_ARM7_ACK();
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

    dprintf("Launching");

    // Restore/clear system state.
    displayReset();
    REG_EXMEMCNT = old_exmemcnt;

    // Start the ARM7 binary.
    arm7_comms_port = 0x80000000;
    while (arm7_comms_port);

    // Start the ARM9 binary.
    swiSoftReset();
}
