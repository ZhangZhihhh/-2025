OUTPUT_ARCH(riscv)
ENTRY(kern_entry)

BASE_ADDRESS = 0xFFFFFFFFC0200000;

SECTIONS
{
    . = BASE_ADDRESS;

    .text : AT(0x80200000) {
        *(.text.entry .text.kern_entry .text .stub .text.* .gnu.linkonce.t.*)
    }

    PROVIDE(etext = .);

    .rodata : AT(ADDR(.rodata) - BASE_ADDRESS + 0x80200000) {
        *(.rodata .rodata.* .gnu.linkonce.r.*)
    }

    . = ALIGN(0x1000);

    .data : AT(ADDR(.data) - BASE_ADDRESS + 0x80200000) {
        *(.data)
        *(.data.* .gnu.linkonce.d.*)
    }

    .sdata : AT(ADDR(.sdata) - BASE_ADDRESS + 0x80200000) {
        *(.sdata .sdata.*)
    }

    PROVIDE(edata = .);

    .bss : AT(ADDR(.bss) - BASE_ADDRESS + 0x80200000) {
        *(.bss .bss.* .sbss*)
    }

    PROVIDE(end = .);

    /* Keep boot parameters after BSS to preserve across memset */
    .data.boot_params : {
        boot_hartid = .;
        QUAD(0)
        boot_dtb = .;
        QUAD(0)
    }

    /DISCARD/ : {
        *(.eh_frame .note.GNU-stack)
    }
}
