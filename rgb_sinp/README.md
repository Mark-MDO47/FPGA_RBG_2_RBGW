# TestBench for RGB serial input module

The RGB serial input module monitors the serial input line and converts it to a stream of "1"s, "0"s and "stream reset"s. These are sensed in the output when strobe is high.

The stream reset is the protocol that tells the string of LEDs that we are starting over talking to LED 0 (the first one in the string). It consists of holding the serial line LOW for >= 50 microseconds.
* NOTE: in my implementation, it asserts "stream reset" if either HIGH or LOW are held steady for >= 50 microseconds.

The "1"s and "0"s are detected by determining the length of the HIGH pulse of the HIGH/LOW which constitute each bit.

The protocol can be found in this spec:
* https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf

In the diagram below, this module is part of the block labeled "Serial to Parallel". It will be followed by another internal block that takes the streams of 0 and 1, turns it into 3 @ 8-bit bytes (one RGB LED word), appends a status byte, and places it into the FIFO.

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/Concept_FPGA_scaled.jpg "FPGA Concept for FPGA_RBT_2_RBGW")

Kudos to Shawn Hymel of the Digi-Key team; he did the fantastic YouTube series "Digi-Key Introduction to FPGA". My rgb_sinp.v code is a (heavily) modified form of "debouncer.v" from "Introduction to FPGA Part 10 - Metastability and Clock Domain Crossing" signal logic.
* https://www.youtube.com/watch?v=dXU1py-Od1g
* https://github.com/ShawnHymel/introduction-to-fpga

