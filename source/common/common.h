// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* === stub libc - memory copy/fill functions === */
void *memcpy(void *s1, const void *s2, size_t n);
void *memmove(void *s1, const void *s2, size_t n);
void *memset(void *s, int c, size_t n);
#include "libc/aeabi.h"
#include "libc/ndsabi.h" // extensions provided by an agbabi fork

/* === stub libc - other functions === */
int memcmp(const void *s1, const void *s2, size_t n); // used by FatFs
char *strchr(const char *s, int c); // used by FatFs
size_t strlen(const char * s); // used by nanoprintf
#include "libc/nanoprintf.h" // printf replacement, used for error logging

/* === other functions === */
uint32_t xor_constant(uint32_t a, uint32_t b); // a ^ b, implemented in ASM to prevent inlining

/* === code/data attributes === */
#define THUMB_FUNC __attribute__((target("thumb")))

/* === helpers === */
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define RGB555(r, g, b) (0x8000 | (r) | ((g)<<5) | ((b)<<10))

/**
 * @brief Is the value (v) in range [a, b)?
 */
#define IN_RANGE_EX(v, a, b) ((v) >= (a) && (v) < (b))

/* === register defines === */

#define IPCSYNC_INPUT(n)       (n)
#define IPCSYNC_OUTPUT(n)      ((n) << 8)

#define REG_IPCSYNC            (*((volatile uint32_t*) 0x4000180))
#define REG_IPCFIFOCNT         (*((volatile uint32_t*) 0x4000184))
#define REG_IPCFIFOSEND        (*((volatile uint32_t*) 0x4000188))
#define REG_IPCFIFORECV        (*((volatile uint32_t*) 0x4100000))
#define REG_POWCNT             (*((volatile uint16_t*) 0x4000304))

#if defined(ARM9)
#define MEM_PALETTE_BG         ((uint16_t*) 0x5000000)
#define DISPCNT_BG_MODE(n)     (n)
#define DISPCNT_FORCE_DISABLE  (1<<7)
#define DISPCNT_BG0_ENABLE     (1<<8)
#define DISPCNT_BG_DISPLAY     (1<<16)
#define REG_DISPCNT            (*((volatile uint32_t*) 0x4000000))
#define BGCNT_TILE_BASE(n)     ((n)<<2)
#define BGCNT_16_COLOR         (0<<7)
#define BGCNT_MAP_32x32        (0<<14)
#define BGCNT_MAP_BASE(n)      ((n)<<8)
#define REG_BG0CNT             (*((volatile uint16_t*) 0x4000008))

#define VRAMCNT_ABCD(a,b,c,d)  ((a) | ((b)<<8) | ((c)<<16) | ((d)<<24))
#define REG_VRAMCNT_ABCD       (*((volatile uint32_t*) 0x4000240))

#define VRAMCNT_EFGW(e,f,g,w)  ((e) | ((f)<<8) | ((g)<<16) | ((w)<<24))
#define REG_VRAMCNT_EFGW       (*((volatile uint32_t*) 0x4000244))

#define VRAMCNT_HI(h,i)        ((h) | ((i)<<8))
#define REG_VRAMCNT_HI         (*((volatile uint16_t*) 0x4000248))

#define KEY_A                  0x001
#define KEY_B                  0x002
#define KEY_SELECT             0x004
#define KEY_START              0x008
#define KEY_RIGHT              0x010
#define KEY_LEFT               0x020
#define KEY_UP                 0x040
#define KEY_DOWN               0x080
#define KEY_R                  0x100
#define KEY_L                  0x200
#define REG_KEYINPUT           (*((volatile uint16_t*) 0x4000130))

#define REG_EXMEMCNT           (*((volatile uint16_t*) 0x4000204))

#define POWCNT_LCD             0x0001
#define POWCNT_2D_MAIN         0x0002
#define POWCNT_3D              0x0004
#define POWCNT_3D_GEOMETRY     0x0008
#define POWCNT_2D_SUB          0x0200
#define POWCNT_DISPLAY_SWAP    0x8000
#elif defined(ARM7)
#else
#error "No CPU defined!"
#endif

/* === NDS header format (only fields of interest) === */

typedef struct {
    char game_title[12];
    union {
        char game_code[4];
        uint32_t game_code_i;
    };
    union {
        char maker_code[2];
        uint16_t maker_code_i;
    };
    uint8_t unit_code;
    uint8_t _ignored_1[0x20 - 0x13];
    uint32_t arm9_offset;
    uint32_t arm9_entry;
    uint32_t arm9_start;
    uint32_t arm9_size;
    uint32_t arm7_offset;
    uint32_t arm7_entry;
    uint32_t arm7_start;
    uint32_t arm7_size;
    uint8_t _ignored_2[0x68 - 0x40];
    uint32_t banner_offset;
    uint8_t _ignored_3[0x170 - 0x6C];
} nds_header_t;

/**
 * Location of the .nds file header in memory.
 */
#define NDS_HEADER    ((nds_header_t*) 0x27FFE00)

#endif /* __COMMON_H__ */
