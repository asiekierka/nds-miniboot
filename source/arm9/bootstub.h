// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#ifndef __BOOTSTUB_H__
#define __BOOTSTUB_H__

#include <stdint.h>

typedef struct {
    uint32_t arm9_entry;
    uint32_t arm7_entry;
    void *arm9_target_entry;
    void *arm7_target_entry;
} bootstub_header_t;

extern bootstub_header_t bootstub;
extern char bootstub_end;
#define bootstub_size ((uint32_t) (((uint8_t*) &bootstub_end) - ((uint8_t*) &bootstub)))

#endif
