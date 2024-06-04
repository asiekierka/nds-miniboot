// SPDX-License-Identifier: Zlib
//
// Copyright (c) 2024 Adrian "asie" Siekierka

    .arm
    .syntax unified

// Ensure the code is compatible with both ARM9 and ARM7 CPUs.
    .cpu arm7tdmi

// This implements a dkA-compliant "bootstub", which uses libnds FIFO calls
// to reset one CPU from the other and (hopefully) get both CPUs to execute at 
// the "target entrypoint".
    .global bootstub
bootstub:
    b bootstub_arm9_entry   // ARM9 entrypoint
    b bootstub_arm7_entry   // ARM7 entrypoint
bootstub_arm9_target:
    .word 0                 // ARM9 target entrypoint, user-provided
bootstub_arm7_target:
    .word 0                 // ARM7 target entrypoint, user-provided

// Bootstub code follows here.
bootstub_arm9_entry:
bootstub_arm7_entry:
    mov r0, #0
    ldr r8, =0x4000000    // I/O port base offset in memory.
    ldr r9, =0x2FFFE00    // .nds header base offset in memory

    // Disable IRQs.
    str r0, [r8, #0x208] // IME
    str r0, [r8, #0x210] // IE
    mvn r1, r0
    str r1, [r8, #0x214] // IF

    // Disable DMA.
    add r1, r8, #0xB0
    mov r2, #0x30
.Ldma_clear:
    subs r2, r2, #4
    strge r0, [r1], #4
    bgt .Ldma_clear

    // Disable timers.
    str r0, [r8, #0x100]
    str r0, [r8, #0x104]
    str r0, [r8, #0x108]
    str r0, [r8, #0x10C]

    // Prepare environment for BIOS soft reset.
    ldr r0, bootstub_arm7_target
    str r0, [r9, #0x34]   // Set ARM7 entrypoint.
    ldr r0, bootstub_arm9_target
    str r0, [r9, #0x24]   // Set ARM9 entrypoint.

    // Reset the other CPU via libnds fifo.
    ldr r0, =0x0C04000C   // Reset command.
                          // BlocksDS uses ...000B for ARM7->ARM9 resets,
                          // but it also never calls the ARM7 entrypoint,
                          // so it's fine.
    str r0, [r8, #0x188]  // Send reset command via FIFO.

    // Wait for the other CPU to signal 0x1.
.Lwait_cpu_1:
    ldr r1, [r8, #0x180]
    and r1, r1, #0xF
    cmp r1, #1
    bne .Lwait_cpu_1

    // Send 0x1 to the other CPU.
    mov r0, #0x100
    str r0, [r8, #0x180]

    // Wait for the other CPU to signal 0x0.
.Lwait_cpu_2:
    ldr r1, [r8, #0x180]
    ands r1, r1, #0xF
    bne .Lwait_cpu_2

    // Send 0x0 to the other CPU.
    str r1, [r8, #0x180]

    // BIOS soft reset time!
    swi 0

    .pool

    .global bootstub_end
bootstub_end:
