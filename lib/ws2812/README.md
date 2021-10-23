# WS2812 Driver
This folder contains a component that can be used to control a WS2812 (also known as Neopixel) chain of N leds.

## Interface
The interface is relatively simple, but quite large; some explanation is required. It consists of 6 input bits, 2 output bits, one 5-bit bus and 3 8-bit buses.

One of the single bits is an ```UPD``` bit that's used for storing the currently present color on the ```red, green and blue``` busses in memory. The index of the led of which the color is changed depends on the input of the ```IDX``` bus.

Now that we have changed the contents in memory, we're able to flush it by asserting the ```FLSH``` bit. Please note that the ```UPD and FLSH``` bits should be made low again to prevent unneccesary updates and flushes. Last but not least, one can reset (turn off) all leds by asserting the ```RST``` bit and then flushing again.

Since a very common part of patterns consist of shifting the leds, this functionality has been provided at the touch of one bit, or button as one might say. Assert ```LSHFT or RSHFT``` to respecitvely shift left or right on rising edge of the clock.

Last but not least, the developer is able to determine when the Leds are 'open' for new commands; the ```RDY``` bit is then asserted.

## Statemachine
The interface description above neatly aligns with the STD underneath. There is one thing to note; the PREP_L and PREP_H states aren't really states as they take one single clock-cycle. It however, helps with readability to implement these as states.

![State-Transition Diagram](doc/State-Transition-Diagram.svg "State-Transition Diagram")