// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

/* Rudimentary text console implementation. */

#include "bios.h"
#include "console.h"
#include "dldi.h"

static bool displayInitialized = false;
bool debugEnabled = false;

extern const uint8_t default_font[760];
#define DISPLAY_TILES ((uint32_t*) 0x6000000)
#define DISPLAY_MAP   ((uint16_t*) 0x6007800)

#define FONT_X_MIN 0
#define FONT_Y_MIN 3
#define FONT_X_MAX 31
#define FONT_Y_MAX 23

static uint16_t fontPalette = 0x0000;
static uint16_t fontX = 0;
static uint16_t fontY = 0;
static bool fontLimited = false;

static void consolePutc(int ch, void *userdata) {
    if ((ch & 0xFF) == 10)
        goto newLine;

    DISPLAY_MAP[fontY * 32 + fontX] = (ch & 0xFF) | fontPalette;

    ++fontX;
    if (fontLimited && fontX > FONT_X_MAX) {
newLine:
        fontX = FONT_X_MIN;
        if ((++fontY) > FONT_Y_MAX) {
            --fontY;
            __aeabi_memmove4(DISPLAY_MAP + (FONT_Y_MIN * 32), DISPLAY_MAP + ((FONT_Y_MIN + 1) * 32), (FONT_Y_MAX - FONT_Y_MIN) * 64);
            __aeabi_memset(DISPLAY_MAP + (fontY * 32) + FONT_X_MIN, (FONT_X_MAX - FONT_X_MIN + 1) * 2, 0);
        }
    }
}

void consoleInit(void);

int eprintf(const char *format, ...) {
  consoleInit();

  va_list val;
  va_start(val, format);
  int rv = npf_vpprintf(consolePutc, NULL, format, val);
  va_end(val);
  return rv;
}

void displayReset(void) {
    // Clear display registers, force blanking.
    REG_DISPCNT = DISPCNT_FORCE_DISABLE;
    __ndsabi_wordset4((void*) 0x4000004, 0x58 - 4, 0);
}

void consoleInit(void) {
    if (displayInitialized) return;

    // Configure palette
    MEM_PALETTE_BG[0] = RGB555(0, 0, 0);
    MEM_PALETTE_BG[1] = RGB555(31, 31, 31);
    MEM_PALETTE_BG[1 + (1 << 4)] = RGB555(16, 16, 16);

    // Clear background map, tile 0.
    __ndsabi_wordset4(DISPLAY_TILES, 32, 0);
    __ndsabi_wordset4(DISPLAY_MAP, 2048, 0);

    // Unpack font tiles.
    uint32_t unpackParams[2] = {760 | (1 << 16) | (4 << 24), 0};
    swiBitUnpack(default_font, DISPLAY_TILES + (32 * 32 / 4), unpackParams);

    // Configure background layer 0.
    REG_BG0CNT = BGCNT_TILE_BASE(0) /* +0KB */
        | BGCNT_MAP_BASE(15) /* +30KB */
        | BGCNT_MAP_32x32
        | BGCNT_16_COLOR;

    // Enable main display.
    REG_DISPCNT = DISPCNT_BG_MODE(0)
        | DISPCNT_BG0_ENABLE
        | DISPCNT_BG_DISPLAY;

    // Draw header, initialize cursor X/Y.
    displayInitialized = true;
    fontX = (32 - 8) >> 1;
    fontY = 0;
    fontPalette = 0x0000;
    fontLimited = false;
    eprintf("miniboot");

    {
        fontY = 1;
        fontPalette = 0x1000;
        int len = strlen(_io_dldi_stub.friendlyName);
        if (len > 32) {
            fontX = 0;
            char c = _io_dldi_stub.friendlyName[29];
            _io_dldi_stub.friendlyName[29] = 0;
            eprintf("%s...", _io_dldi_stub.friendlyName);
            _io_dldi_stub.friendlyName[29] = c;
        } else {
            fontX = (32 - len) >> 1;
            eprintf("%s", _io_dldi_stub.friendlyName);
        }
    }

    fontX = FONT_X_MIN;
    fontY = FONT_Y_MIN;
    fontPalette = 0x0000;
    fontLimited = true;
}
