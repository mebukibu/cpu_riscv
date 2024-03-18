ENTRY(start)

SECTIONS {
  . = 0x8928;

  .text :{
    KEEP(*(.text.start));
    *(.text .text.*);
  }

  .rodata : ALIGN(4) {
    *(.rodata .rodata.*);
  }

  .data : ALIGN(4) {
    *(.data .data.*);
  }

  .bss : ALIGN(4) {
    *(.bss .bss.* .sbss .sbss.*);

    . = ALIGN(16);
    . += 1 * 1024;
    __stack_top = .;
  }
}