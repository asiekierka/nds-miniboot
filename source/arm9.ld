/* SPDX-License-Identifier: Zlib */
/* Copyright (c) 2024 Adrian "asie" Siekierka */

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
	ITCM : ORIGIN = 0x01000000, LENGTH = 32K
	DTCM : ORIGIN = 0x0E000000, LENGTH = 16K
	RAM  : ORIGIN = 0x02000000, LENGTH = 3840K
}

SECTIONS {
	/* === Constants === */
	PROVIDE(__dldi_size = 16384);
	__dldi_log2_size = LOG2CEIL(__dldi_size + 1) - 1;

	/* === ITCM === */

	/* Keep everything in one section to make objcopy work fine. */
	.text : ALIGN(4) {
		*(.start)
		*(.text .text.* .gnu.linkonce.t.*)
		*(.rodata .rodata.* .gnu.linkonce.r.*)
		*(.data .data.* .gnu.linkonce.d.*)
		. = ALIGN(512);
		__dldi_start = .;
		*(.dldi .dldi.*)
		. = __dldi_start + __dldi_size;
		. = ALIGN(512);
	} >ITCM AT>RAM

	/* === DTCM === */

	.bss (NOLOAD) : ALIGN(4) {
		*(.arguments)
		*(.bss .bss.* .gnu.linkonce.b.*)
		*(COMMON)
		. = ALIGN(. != 0 ? 4 : 1);
	} >DTCM AT>RAM

	.noinit (NOLOAD) : ALIGN(4) {
		*(.noinit .noinit.* .gnu.linkonce.n.*)
		. = ALIGN(. != 0 ? 4 : 1);
	} >DTCM AT>RAM

	__itcm_start = ADDR(.text);
	__itcm_chunks = (SIZEOF(.text) + 31) >> 5;
	__bss_start = ADDR(.bss);
	__bss_chunks = (SIZEOF(.bss) + 15) >> 4;

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
