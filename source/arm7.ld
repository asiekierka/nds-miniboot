/* SPDX-License-Identifier: Zlib */
/* Copyright (c) 2024 Adrian "asie" Siekierka */

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
	RAM  : ORIGIN = 0x03800000, LENGTH = 64K
}

SECTIONS {
	.text : ALIGN(4) {
		*(.start)
		*(.text .text.* .gnu.linkonce.t.*)
		*(.rodata .rodata.* .gnu.linkonce.r.*)
		*(.data .data.* .gnu.linkonce.d.*)
		. = ALIGN(512);
	} >RAM

	.bss (NOLOAD) : ALIGN(4) {
		*(.arguments)
		*(.bss .bss.* .gnu.linkonce.b.*)
		*(COMMON)
		. = ALIGN(. != 0 ? 4 : 1);
	} >RAM

	.noinit (NOLOAD) : ALIGN(4) {
		*(.noinit .noinit.* .gnu.linkonce.n.*)
		. = ALIGN(. != 0 ? 4 : 1);
	} >RAM

	__bss_start = ADDR(.bss);
	__bss_chunks = (SIZEOF(.bss) + 31) >> 5;

	/* === DWARF 2 debug sections === */

	.debug 0 : { *(.debug) }
	.line 0 : { *(.line) }
	.debug_srcinfo 0 : { *(.debug_srcinfo) }
	.debug_sfnames 0 : { *(.debug_sfnames) }
	.debug_aranges 0 : { *(.debug_aranges) }
	.debug_pubnames 0 : { *(.debug_pubnames) }
	.debug_info 0 : { *(.debug_info .gnu.linkonce.wi.*) }
	.debug_abbrev 0 : { *(.debug_abbrev) }
	.debug_line 0 : { *(.debug_line .debug_line.* .debug_line_end) }
	.debug_frame 0 : { *(.debug_frame) }
	.debug_str 0 : { *(.debug_str) }
	.debug_loc 0 : { *(.debug_loc) }
	.debug_macinfo 0 : { *(.debug_macinfo) }
	.debug_weaknames 0 : { *(.debug_weaknames) }
	.debug_funcnames 0 : { *(.debug_funcnames) }
	.debug_typenames 0 : { *(.debug_typenames) }
	.debug_varnames 0 : { *(.debug_varnames) }
}
