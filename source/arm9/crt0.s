// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

#include "cp15_asm.h"
#include "cpsr_asm.h"

    .arm
    .syntax unified

    .global _start
    .section .start, "ax"
_start:
    // Vectors + jump to crt0.
    b .Lstart_real
    ldr pc, =0xFFFF0004
    ldr pc, =0xFFFF0008
    ldr pc, =0xFFFF000C
    ldr pc, =0xFFFF0010
    // ARM7 communications port (accessed as 0x2800014).
    .word 0
    ldr pc, =0xFFFF0018
    ldr pc, =0xFFFF001C

    .pool

.Lstart_real:
    // Is the binary relocated?
    adr r1, _start
    mov r0, #0x01000000
    cmp r0, r1
    beq .Lat_itcm
    // If not, relocate it to ITCM.

    mov r11, #0
    // Disable IRQs.
    ldr r3, =0x4000000
    str r11, [r3, #0x208] // IME
    str r11, [r3, #0x210] // IE
    mvn r10, r11
    str r10, [r3, #0x214] // IF
    // Disable DMA (AK2i, and possibly others, leave unclean state.)
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

    // Initialize ITCM.
    mov r3, #(CP15_TCM_SIZE_32MB << 1)
    mcr CP15_REG9_ITCM_CONTROL(r3)

    // Enable ITCM.
    ldr r3, =(CP15_CONTROL_ALTERNATE_VECTOR_SELECT \
        | CP15_CONTROL_ITCM_ENABLE \
        | CP15_CONTROL_ICACHE_ENABLE \
        | CP15_CONTROL_RESERVED_SBO_MASK)
    mcr CP15_REG1_CONTROL_REGISTER(r3)

    // Copy program to ITCM, cannot use DMA.
    // r1 = source (_start in RAM)
    // r0 = ITCM start
    mov r11, r0
    ldr r2, =__itcm_chunks
.Litcm_copy:
    subs r2, r2, #1
    ldmiage r1!, {r3-r10}
    stmiage r0!, {r3-r10}
    bgt .Litcm_copy

    // Return to _start, now in the correct memory location.
    bx r11

.Lat_itcm:
    // Initialize the rest of the MPU for our needs.
    // We can expect modern homebrew running after miniboot to do a better
    // job, so let's just do what is necessary here.

    // Initialize DTCM to 0x0E000000.
    mov r6, 0x0E000000
    orr r0, r6, (CP15_TCM_SIZE_16KB << 1)
    mcr CP15_REG9_DTCM_CONTROL(r0)

    // Enable ITCM/DTCM, disable DCache and PU.
    ldr r0, =(CP15_CONTROL_ITCM_ENABLE \
        | CP15_CONTROL_DTCM_ENABLE \
        | CP15_CONTROL_RESERVED_SBO_MASK)
    mcr CP15_REG1_CONTROL_REGISTER(r0)

    // Invalidate caches after disabling them.
    mcr CP15_REG7_FLUSH_ICACHE
    mcr CP15_REG7_FLUSH_DCACHE
    // Drain the write buffer, too, just in case.
    mcr CP15_REG7_DRAIN_WRITE_BUFFER

    // Clear BSS in DTCM.
    // r6 = BSS start (DTCM start)
    ldr r1, =__bss_chunks
    mov r2, #0
    mov r3, r2
    mov r4, r2
    mov r5, r2
.Lbss_clear:
    subs r1, r1, #1
    stmiage r6!, {r2-r5}
    bgt .Lbss_clear

    // Initialize stacks
    and r0, r6, 0xFF000000
    add r0, r0, 0x00003EC0
    msr CPSR_fsxc, #(CPSR_I | CPSR_F | CPSR_SUPERVISOR)
    add sp, r0, 0x100
    msr CPSR_fsxc, #(CPSR_I | CPSR_F | CPSR_IRQ)
    add sp, r0, 0xE0
    msr CPSR_fsxc, #(CPSR_SYSTEM)
    mov sp, r0

    b main

    .pool
