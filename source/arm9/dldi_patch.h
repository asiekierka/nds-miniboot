// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#ifndef __DLDI_PATCH_H__
#define __DLDI_PATCH_H__

#include "common.h"
#include "dldi.h"

#define DLPR_OK                  0
#define DLPR_NOT_ENOUGH_SPACE    1

/**
 * @brief Patch a binary's DLDI driver, if any.
 * 
 * @param buffer The buffer containing the binary to patch.
 * @param size The size of the binary, in bytes.
 * @param driver Source DLDI driver.
 * @return int The error code, if any.
 */
int dldi_patch_relocate(void *buffer, uint32_t size, DLDI_INTERFACE *driver);

#endif /* __DLDI_PATCH_H__ */
