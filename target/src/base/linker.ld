ENTRY(_start)

OUTPUT_FORMAT(binary)

SECTIONS
{
	. = 0x100000;

	.text : AT(ADDR(.text) - 0x100000) {
		_code = .;
		*(.text)
		*(.rodata*)
		. = ALIGN(4096);
	}

	.data : AT(ADDR(.data) - 0x100000) {
		_data = .;
		*(.data)
		. = ALIGN(4096);
	}

	.eh_frame : AT(ADDR(.eh_frame) - 0x100000) {
		_ehframe = .;
		*(.eh_frame)
		. = ALIGN(4096);
	}

	.bss : AT(ADDR(.bss) - 0x100000) {
		_bss = .;
		*(.bss)

		*(COMMON)
		. = ALIGN(4096);
	}

	_end = .;

	/DISCARD/ : 
	{
		*(.comment)
	}
}

