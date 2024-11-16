// SPDX-License-Identifier: Zlib
// SPDX-FileNotice: Modified from the original version by the BlocksDS project.
//
// Copyright (c) 2006 Michael Chisholm (Chishm) and Tim Seidel (Mighty Max).

#ifndef LIBNDS_NDS_ARM9_DLDI_H__
#define LIBNDS_NDS_ARM9_DLDI_H__

#include <stdint.h>

#define FEATURE_MEDIUM_CANREAD  0x00000001
#define FEATURE_MEDIUM_CANWRITE 0x00000002
#define FEATURE_SLOT_GBA        0x00000010 // This is a slot-2 flashcard
#define FEATURE_SLOT_NDS        0x00000020 // This is a slot-1 flashcart

#define FIX_ALL                 0x01
#define FIX_GLUE                0x02
#define FIX_GOT                 0x04
#define FIX_BSS                 0x08

#define DLDI_SIZE_32KB  0x0f
#define DLDI_SIZE_16KB  0x0e
#define DLDI_SIZE_8KB   0x0d
#define DLDI_SIZE_4KB   0x0c
#define DLDI_SIZE_2KB   0x0b
#define DLDI_SIZE_1KB   0x0a

#define DLDI_MAGIC_STRING_LEN   8
#define DLDI_FRIENDLY_NAME_LEN  48

// I/O interface with DLDI extensions
typedef struct DLDI_INTERFACE {
    uint32_t magicNumber;
    char magicString [DLDI_MAGIC_STRING_LEN];
    uint8_t versionNumber;
    uint8_t driverSize;       // Log-2 of driver size in bytes
    uint8_t fixSectionsFlags;
    uint8_t allocatedSize;    // Log-2 of the allocated space in bytes

    char friendlyName [DLDI_FRIENDLY_NAME_LEN];

    // Pointers to sections that need address fixing
    uint8_t *dldiStart;
    uint8_t *dldiEnd;
    uint8_t *interworkStart;
    uint8_t *interworkEnd;
    uint8_t *gotStart;
    uint8_t *gotEnd;
    uint8_t *bssStart;
    uint8_t *bssEnd;

    // Original I/O interface data
    uint32_t ioType;
    uint32_t features;
    bool (*startup)(void);
    bool (*isInserted)(void);
    bool (*readSectors)(uint32_t sector, uint32_t numSectors, void *buffer);
    bool (*writeSectors)(uint32_t sector, uint32_t numSectors, const void *buffer);
    bool (*clearStatus)(void);
    bool (*shutdown)(void);
} DLDI_INTERFACE;

extern DLDI_INTERFACE _io_dldi_stub;

#endif // LIBNDS_NDS_ARM9_DLDI_H__
