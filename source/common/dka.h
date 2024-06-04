// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#ifndef __DKA_H__
#define __DKA_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* === dkA standards: bootstub header === */

#define DKA_BOOTSTUB_MAGIC 0x62757473746F6F62ULL // "bootstub" in ASCII

typedef struct {
    uint64_t magic;
    void *arm9_entry;
    void *arm7_entry;
    uint32_t loader_size;
} dka_bootstub_t;

#define DKA_BOOTSTUB ((dka_bootstub_t*) 0x2FF4000)

/* === dkA standards: argv header === */

#define DKA_ARGV_MAGIC 0x5F617267 // "_arg" in ASCII

typedef struct {
    uint32_t magic;
    char *cmdline;
    uint32_t cmdline_size;
} dka_argv_t;

#define DKA_ARGV ((dka_argv_t*) 0x2FFFE70)

#endif /* __COMMON_H__ */
