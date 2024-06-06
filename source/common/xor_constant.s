// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

    .arm
    .syntax unified

    .global xor_constant
    .section .text.xor_constant, "ax"
xor_constant:
    eor r0, r0, r1
    bx lr
