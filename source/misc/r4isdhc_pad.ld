OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)

MEMORY {
	RAM  : ORIGIN = 0x02000000, LENGTH = 3840K
}

SECTIONS {
	.r4i_sdhc_pad : {
		KEEP(*(.r4i_sdhc_pad))
	} >RAM = 0x00
}
