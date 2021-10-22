# WS2812 Driver
This folder contains a component that can be used to control a WS2812 (also known as Neopixel) chain of N leds.

## Interface
The interface consists of 3 bits, one 5 bit bus and three 8 bit busses. One of the single bits is an ```UPD``` bit that's used for storing the currently present color on the ```red, green and blue``` busses in memory. The index of the led of which the color is changed depends on the input of the ```IDX``` bus.

Now that we have changed the contents in memory, we're able to flush it by asserting the ```FLSH``` bit. Please note that the ```UPD and FLSH``` bits should be made low again to prevent unneccesary updates and flushes. Last but not least, one can reset (turn off) all leds by asserting the ```RST``` bit and then 

## Statemachine
