SECTIONS
{
    . = 0x0000;
    .text : {
        *(.text)
        . = 0x0100;
        *(.romdata)
    }
}