// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

    .arm
    .syntax unified

    .global _start
    .section .start, "ax"

_start:
    mov r11, #0
    // Disable IRQs.
    ldr r3, =0x4000000
    str r11, [r3, #0x208]
    // Disable DMA.
    str r11, [r3, #0x0B8]
    str r11, [r3, #0x0C4]
    str r11, [r3, #0x0D0]
    str r11, [r3, #0x0DC]
    // Disable timers.
    str r11, [r3, #0x100]
    str r11, [r3, #0x104]
    str r11, [r3, #0x108]
    str r11, [r3, #0x10C]

    // Copy up to 96 bytes to the stack area.
    adr r0, _stage2
    ldr r1, =0x380FE00
    mov lr, r1
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}

    ldr r8, =arm7_comms_port
    str r11, [r8]

    bx lr

    .pool
    
    // stage2 must be at most 96 bytes.
    // r8 = ARM7 comms port
    // r11 = 0
_stage2:
    ldr r0, [r8]
    cmp r0, #0x80000000
    bne _stage2_cmd2

    // 0x80000000 = jump to entrypoint, which is already set in the header
    str r11, [r8]
    swi 0

_stage2_cmd2:
    cmp r0, #0
    beq _stage2

    // copy N bytes from 0x2000800 to ARM7
    // r0 = size
    str r11, [r8]
    // read next value
_stage2_copy_wait:
    ldr r1, [r8]
    cmp r1, #0
    beq _stage2_copy_wait
    // r1 = destination address
    // r2 = source address
    ldr r2, =0x2000000
_stage2_copy:
    subs r0, r0, #4
    ldrge r3, [r2], #4
    strge r3, [r1], #4
    bgt _stage2_copy
    str r11, [r8]
    b _stage2
