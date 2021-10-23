# Pseudo-Random Number Generator
This folder contains a component that can be used to generate Pseudo-Random Numbers.

## Interface
The interface is as simple as possible; 3 input bits and one 8-bit output bus.

The input bits consist of a ```CLK```, ```RST``` line for resetting the number and an ```EN``` during which it is asserted the LFSR is shifted on rising edge of the clock.

The random number will be present on the 8-bit output bus.