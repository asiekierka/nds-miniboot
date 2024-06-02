// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#ifndef __CONSOLE_H__
#define __CONSOLE_H__

#include "common.h"

#ifdef NDEBUG
#define debugEnabled false
#define dprintf(...) {}
#else
extern bool debugEnabled;
#define dprintf(...) { if (debugEnabled) eprintf(__VA_ARGS__); }
#endif

/**
 * Reset 2D graphics engine registers, turn off display.
 */
void displayReset(void);

/**
 * Initialize rudimentary console.
 */
void consoleInit(void);

/**
 * Print a string to console; initialize if not initialized.
 *
 * To print only when debug mode is enabled, use dprintf.
 */
int eprintf(const char *format, ...);

#endif
