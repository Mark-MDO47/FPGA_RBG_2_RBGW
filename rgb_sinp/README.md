# TestBench for RGB serial input module

The RGB serial input module monitors the serial input line and converts it to a stream of "1"s, "0"s and "stream reset"s. These are sensed in the output when strobe is high.

The stream reset is the protocol that tells the string of LEDs that we are starting over talking to LED 0 (the first one in the string). It consists of holding the serial line LOW for >= 50 microseconds.
* NOTE: in my implementation, it asserts "stream reset" if either HIGH or LOW are held steady for >= 50 microseconds.

The serial format used by the  WS2812b RGB LEDs is different than that of the SK6812 RGB LEDs; for the WS2812b:
- the "0" bit is nominally 0.4 microsec high followed by 0.85 microsec low
- the "1" bit is nominally 0.85 microsec high followed by 0.4 microsec low
- a "stream reset" is nominally >= 50 microsec low

The "1"s and "0"s are detected by determining the length of the HIGH pulse of the HIGH/LOW which constitute each bit as shown below. The gray line "sample" that goes through the signal timelines illustrates where the sample will be taken. The other lines are various combinations, for "1" bits and for "0" bits, of the minimum and maximum specified timing for the HIGH pulse and LOW pulse. A sample taken at this time shows a HIGH for every "1" bit and a LOW for every "0" bit.
![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/WS2812B_sample_time_scaled.jpg "WS2812B Sample Time Approach")

The WS2812B protocol can be found in this spec:
* https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf

A higher level depiction of this output protocol (taken from the spec) in action is shown here. First is the serial head-to-tail cascade architecture of the LEDs:

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/CascadeLED_SerialProtocol_arch.png "WS2812b RGB serial cascade architecture (from spec)")

Then the high-level serial output protocol as seen by each of the LEDs in the architecture diagram. Note how each LED "swallows" the first set of bytes and passes on the rest. This module in the FPGA will receive the serial stream labelled D1 in this example and process all the bits.

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/WS2812B_RGB_SerialProtocol.png "WS2812b RGB serial output protocol (from spec)")

In the diagram below, this module is part of the block labeled "Serial to Parallel". It will be followed by another internal block that takes the streams of 0 and 1, turns it into 3 @ 8-bit bytes (one RGB LED word), appends a status byte, and places it into the FIFO.

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/Concept_FPGA_scaled.jpg "FPGA Concept for FPGA_RBT_2_RGBW")

Kudos to Shawn Hymel of the Digi-Key team; he did the fantastic YouTube series "Digi-Key Introduction to FPGA". My rgb_sinp.v code is a (heavily) modified form of "debouncer.v" from "Introduction to FPGA Part 10 - Metastability and Clock Domain Crossing" signal logic.
* https://www.youtube.com/watch?v=dXU1py-Od1g
* https://github.com/ShawnHymel/introduction-to-fpga

