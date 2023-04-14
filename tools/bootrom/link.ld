OUTPUT_ARCH( "riscv" )
ENTRY( entry )
SECTIONS
{
    . = 0x01000000;
    .text :
    {
        *(.text)
    }
    _end = .;
}
