// SPDX-License-Identifier: Zlib
// SPDX-FileNotice: Modified from the original version for miniboot.
//
// Copyright (c) 2006 Michael Chisholm (Chishm) and Tim Seidel (Mighty Max).
// Copyright (c) 2024 Adrian "asie" Siekierka

#include "dldi_patch.h"
#include "aeabi.h"
#include "console.h"

#define XOR_CONSTANT_VALUE 0xAA55AA55
#define OBFUSCATED_COMPARE(a, b) \
	(xor_constant(a, XOR_CONSTANT_VALUE) == (( \
		(((b) & 0xFF000000) >> 24) | \
		(((b) & 0xFF0000) >> 8) | \
		(((b) & 0xFF00) << 8) | \
		(((b) & 0xFF) << 24)) ^ XOR_CONSTANT_VALUE))

static void dldi_relocate(DLDI_INTERFACE *io, uint8_t *dldiAddress) {
    uint32_t offset;
    uint32_t **address;
    uint32_t *oldStart;
    uint32_t *oldEnd;

    offset = (uint32_t) dldiAddress - (uint32_t) io->dldiStart;
    oldStart = io->dldiStart;
    oldEnd = io->dldiEnd;

    // Correct all pointers to the offsets from the location of this interface
    io->dldiStart = ((uint8_t*) io->dldiStart) + offset;
    io->dldiEnd = ((uint8_t*) io->dldiEnd) + offset;
    io->interworkStart = ((uint8_t*) io->interworkStart) + offset;
    io->interworkEnd = ((uint8_t*) io->interworkEnd) + offset;
    io->gotStart = ((uint8_t*) io->gotStart) + offset;
    io->gotEnd = ((uint8_t*) io->gotEnd) + offset;
    io->bssStart = ((uint8_t*) io->bssStart) + offset;
    io->bssEnd = ((uint8_t*) io->bssEnd) + offset;

    io->startup = (void*)((uint8_t*) io->startup + offset);
    io->isInserted = (void*)((uint8_t*) io->isInserted + offset);
    io->readSectors = (void*)((uint8_t*) io->readSectors + offset);
    io->writeSectors = (void*)((uint8_t*) io->writeSectors + offset);
    io->clearStatus = (void*)((uint8_t*) io->clearStatus + offset);
    io->shutdown = (void*)((uint8_t*) io->shutdown + offset);

    // Fix all addresses with in the DLDI
    if (io->fixSectionsFlags & FIX_ALL) {
        for (address = (uint32_t**) io->dldiStart; address < (uint32_t**) io->dldiEnd; address++) {
            if (oldStart <= *address && *address < oldEnd)
                *address += offset;
        }
    }

    // Fix the interworking glue section
    if (io->fixSectionsFlags & FIX_GLUE) {
        address = (uint32_t**) io->interworkStart;

        for (; address < (uint32_t**) io->interworkEnd; address++) {
            if (oldStart <= *address && *address < oldEnd)
                *address += offset;
        }
    }

    // Fix the global offset table section
    if (io->fixSectionsFlags & FIX_GOT) {
        for (address = (uint32_t**) io->gotStart; address < (uint32_t**) io->gotEnd; address++) {
            if (oldStart <= *address && *address < oldEnd)
                *address += offset;
        }
    }

    // Initialise the BSS to 0
    if (io->fixSectionsFlags & FIX_BSS) {
        __aeabi_memset(io->bssStart, (uint8_t*) io->bssEnd - (uint8_t*) io->bssStart, 0);
    }
}

int dldi_patch_relocate(void *buffer, uint32_t size, DLDI_INTERFACE *driver) {
    uint32_t *data = (uint32_t*) buffer;
    for (; size; size -= 4, data++) {
        // Obfuscate the constants, so that DLDI patchers don't catch the DLDI patching code.
        if (OBFUSCATED_COMPARE(data[0], 0xEDA58DBF) && OBFUSCATED_COMPARE(data[1], 0x20436869) && OBFUSCATED_COMPARE(data[2], 0x73686d00)) {
            dprintf("DLDI found at %d\n", (uint8_t*)data - (uint8_t*)buffer);
            DLDI_INTERFACE *target = (DLDI_INTERFACE*) data;

            void *dldiStart = target->dldiStart;
            uint8_t allocatedSize = target->allocatedSize;
            if (allocatedSize < driver->driverSize) return DLPR_NOT_ENOUGH_SPACE;

            // Skip overwriting the magic number - the driver included as part of miniboot
            // does not always contain it, to evade auto-DLDI patchers in previous stage bootloaders.
            __aeabi_memcpy(((uint8_t*) target) + 4, ((uint8_t*) driver) + 4, (1 << allocatedSize) - 4);
            target->allocatedSize = allocatedSize;
            dldi_relocate(target, dldiStart);
            return DLPR_OK;
        }
    }

    return DLPR_OK;
}
