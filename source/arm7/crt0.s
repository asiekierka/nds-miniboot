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
    str r11, [r3, #0x208] // IME
    str r11, [r3, #0x210] // IE
    mvn r10, r11
    str r10, [r3, #0x214] // IF
    // Disable DMA.
    add r4, r3, #0xB0
    mov r5, #0x30
_dma_clear:
    subs r5, r5, #4
    strge r11, [r4], #4
    bgt _dma_clear
    // Disable timers.
    str r11, [r3, #0x100]
    str r11, [r3, #0x104]
    str r11, [r3, #0x108]
    str r11, [r3, #0x10C]
    // Clear/initialize FIFO.
    str r11, [r3, #0x180] // IPCSYNC
    ldr r4, =0xC008 // Enable, acknowledge error, flush
    str r4, [r3, #0x184] // IPCFIFOCNT

    // Copy up to 160 bytes to the stack area.
    adr r0, _stage2
    ldr r1, =0x380FE00
    mov lr, r1
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}
    ldmiage r0!, {r3-r10}
    stmiage r1!, {r3-r10}

    ldr r8, =0x4000180
    add r9, r8, #8
    mov r10, #0x4100000
    str r11, [r8]
    mov r12, r11

    ldr sp, =0x380FFB0
    bx lr

    .pool
    
    // stage2 must be at most 160 bytes.
    // r8 = IPCSYNC
    // r9 = IPCFIFOSEND
    // r10 = IPCFIFORECV
    // r11 = 0
    // r12 = counter for IPCSYNC
_stage2:
_stage2_init:
    mov r7, #1
_stage2_sync_loop:
    bl _stage2_wait_recv_r7
    add r7, r7, #0x1
    ands r7, r7, #0xF
    bne _stage2_sync_loop
_stage2_next_cmd:
    bl _stage2_bump_counter
    mov r7, #0
    bl _stage2_wait_recv_r7
_stage2_wait_cmd:
    ldr r0, [r8]
    and r0, r0, #0xF
    // command 0xF = synchronize
    cmp r0, #0xF
    beq _stage2_next_cmd
    cmp r0, #0x2
    beq _stage2_cmd2
    cmp r0, #0x1
    bne _stage2_wait_cmd

    // command 0x1 = copy N1 bytes from N2 to N3
_stage2_cmd1:
    ldr r0, [r10]
    ldr r2, [r10]
    ldr r1, [r10]
    // r1 = destination address
    // r2 = source address
_stage2_copy:
    subs r0, r0, #4
    ldrge r3, [r2], #4
    strge r3, [r1], #4
    bgt _stage2_copy
    b _stage2_next_cmd

    // command 0x2 = jump to entrypoint, which is already set in the header
_stage2_cmd2:
    bl _stage2_bump_counter
    swi 0

    // wait to receive the value in r7 from ARM9 via IPC, then send N+1
_stage2_wait_recv_r7:
    ldr r0, [r8]
    and r0, r0, #0xF
    cmp r0, r7
    bne _stage2_wait_recv_r7

    // send N+1 to ARM9 via IPC
_stage2_bump_counter:
    add r12, r12, #0x100
    and r12, r12, #0xF00
    str r12, [r8]
    bx lr
