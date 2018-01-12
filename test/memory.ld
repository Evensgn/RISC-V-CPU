SECTIONS
{
	. = 0x00000000;
	.rom :
	{
		*(.rom)
	}

	. = 0x00001000;
	.text :
	{
		*(.text)
	}

	.rodata ALIGN(4) :
	{
		*(.rodata)
	}

	.data ALIGN(4) :
	{
		*(.data)
	}

	__bss_start = .;

	.bss ALIGN(4) :
	{
		*(.bss)
	}

	__bss_end = .;
	__heap_start = (__bss_end + 0xfff) & 0xff000;
}