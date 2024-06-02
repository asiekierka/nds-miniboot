// SPDX-License-Identifier: Zlib
//
// Copyright (C) 2022-2023 gba-hpp contributors
// Copyright (c) 2024 Adrian "asie" Siekierka

#ifndef __BIOS_H__
#define __BIOS_H__

#include "common.h"

__attribute__((always_inline))
static inline void swiSoftReset(void) {
    asm volatile inline ("swi 0x0 << ((1f - . == 4) * -16); 1:");
    __builtin_unreachable();
}

__attribute__((always_inline))
static inline void swiBitUnpack(const uint8_t *source, uint32_t *destination, const void *params) {
    register const uint8_t* r0 asm("r0") = source;
    register uint32_t* r1 asm("r1") = destination;
    register const void* r2 asm("r2") = params;
    asm volatile inline ("swi 0x10 << ((1f - . == 4) * -16); 1:" : "+r"(r0), "+r"(r1), "+r"(r2) :: "r3", "memory");
}

#endif
