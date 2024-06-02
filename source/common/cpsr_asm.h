// SPDX-License-Identifier: Zlib
//
// Copyright (C) 2024 Adrian "asie" Siekierka

#ifndef __CPSR_ASM_H__
#define __CPSR_ASM_H__

#define CPSR_I 0x80
#define CPSR_F 0x40
#define CPSR_USER       0x10
#define CPSR_FIQ        0x11
#define CPSR_IRQ        0x12
#define CPSR_SUPERVISOR 0x13
#define CPSR_ABORT      0x17
#define CPSR_UNDEFINED  0x1B
#define CPSR_SYSTEM     0x1F

#endif
