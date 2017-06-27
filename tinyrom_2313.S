/*
 * tinyrom for ATtiny2313.
 *
 * Acts as a 256x7 ROM with output enable. Place the ROM data in
 * a file your-rom.S. The file must have this format:
 *
 *  .section .romdata
 *  .org 0
 *  .byte n[,n...]
 *  .byte n[,n...]
 *  ...
 *  .end
 *
 * where n is any of:
 *   0bnnnnnnnn for binary (n in [01])
 *   0mnn for octal (m in [0-3], n in [0-7])
 *   m for decimal (m must start with a non-zero number, or be 0)
 *   0xnn for hex (n in [0-9a-fA-F])
 *
 * See also http://web.mit.edu/gnu/doc/html/as_3.html#SEC34
 * for a full description of byte formats.
 *
 * Then just append your .S file at the end of the avr-gcc
 * compilation command line as described below.
 *
 * Pinout:
 *
 * /RESET [PA2] 1  o:: 20 VCC
 *     D0 [PD0] 2  ::: 19 [PB7] A7
 *     D1 [PD1] 3  ::: 18 [PB6] A6
 *     OE [PA1] 4  ::: 17 [PB5] A5
 *        [PA0] 5  ::: 16 [PB4] A4
 *     D2 [PD2] 6  ::: 15 [PB3] A3
 *     D3 [PD3] 7  ::: 14 [PB2] A2
 *     D4 [PD4] 8  ::: 13 [PB1] A1
 *     D5 [PD5] 9  ::: 12 [PB0] A0
 *          GND 10 ::: 11 [PD6] D6
 *
 */
#include <avr/io.h>

// Get the AVR tools for Windows at 
//   https://sourceforge.net/projects/winavr
// Or, install the AVR tools for Linux by using
//   sudo apt-get install gcc-avr binutils-avr gdb-avr avr-libc avrdude
//   or see http://avr-eclipse.sourceforge.net/wiki/index.php/The_AVR_GCC_Toolchain
//
// To compile:
//   avr-gcc -nostartfiles -mmcu=attiny2313 -Wl,-Ttinyrom_2313.x -o your-rom.elf your-rom.S tinyrom_2313.S
//   avr-objcopy -j .text -O ihex your-rom.elf your-rom.hex
//
// To program:
//   Get a device programmer.

.text

.org 0
.global init

init:
	rjmp main

.org 0x0020
.global main

main:
	cli

	// Change from 1 MHz to 8 MHz system clock

	out _SFR_IO_ADDR(CLKPR), 0x80
	out _SFR_IO_ADDR(CLKPR), 0x00

	// Disable watchdog timer

	wdr
	ldi r16, 0x00
	out _SFR_IO_ADDR(MCUSR), r16
	in r17, _SFR_IO_ADDR(WDTCSR)
	ori r17, _BV(WDCE) | _BV(WDE)
	out _SFR_IO_ADDR(WDTCSR), r17
	out _SFR_IO_ADDR(WDTCSR), r16

	// Disable input pullups

	ldi r16, _BV(PUD)
	out _SFR_IO_ADDR(MCUCR), r16

	// Pin directions are all
	// inputs on reset.

	// Set pin directions:
	//   PA2 - PA0 are inputs
    //   PB7 - PB0 are inputs
	//   PD6 - PD0 are outputs when PA1 is high,
	//      or inputs when PA1 is low.

    // We store the data table at 0x0100.

	ldi ZH, 0x01
loop:
	// read OE, set direction of port D accordingly

	in r16, _SFR_IO_ADDR(PINA)
	ldi r17, 0x00
	sbrc r16, 1
	ldi r17, 0xFF
	out _SFR_IO_ADDR(DDRD), r17

	in ZL, _SFR_IO_ADDR(PINB)
    lpm r0, Z
    out _SFR_IO_ADDR(PORTD), r0
	rjmp loop
