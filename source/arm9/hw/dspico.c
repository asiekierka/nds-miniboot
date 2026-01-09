// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2026 Adrian "asie" Siekierka

#ifdef HW_DSPICO

#include "common.h"
#include "bios.h"
#include "dka.h"
#include "bootstub.h"
#include "dldi_patch.h"
#include "ff.h"
#include "console.h"

// The DSPico requires some extra initialization before starting the DLDI
// driver.

void dspico_init(void) {
    // Disable scrambling (card side)
    slot1_set_command(0xFC00000000000000ull);
    REG_ROMMCNT = ROMMCNT_MODE_ROM | ROMMCNT_ENABLE;
    REG_ROMCNT = 0xA0404018;
    while (REG_ROMCNT & 0x80000000);

    // Disable scrambling (console side)
    memset((void*) 0x40001B0, 0, 16);
    REG_ROMCNT = 0x2040A000;
}

#endif /* HW_DSPICO */