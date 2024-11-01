// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 lifehackerhansol

.syntax unified
.align 4
.arm
.section .r4i_sdhc_pad, "ax"

b 0x2000450
.space 0xEC - 0x04

bl 0x2000218
.space 0x450 - 0xF0

.end
