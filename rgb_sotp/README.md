# TestBench for RGB serial output module

The RGB serial output module rgb_sotp.v reads a series of 32-bit words from the FIFO (Status/Green/Red/Blue). Status has two defined bits: valid and in_stream_reset. The stream reset is the protocol that tells the string of LEDs that we are starting over talking to LED 0 (the first one in the string).

<br>
It converts these to a stream of serial "1"s, "0"s and "stream reset"s. These are sensed in the output when strobe is high. The serial format used by the  SK6812 RGBW LEDs is different than that of the WS2812b RGB LEDs; for the SK6812:
- the "0" bit is nominally 0.3 microsec high followed by 0.9 microsec low
- the "1" bit is nominally 0.6 microsec high followed by 0.6 microsec low
- a "stream reset" is nominally >= 80 microsec low

The SK6812RGBW protocol can be found in this spec:
* https://cdn-shop.adafruit.com/product-files/2757/p2757_SK6812RGBW_REV01.pdf

A higher level depiction of this output protocol (taken from the spec) is shown here:

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/SK6812RGB_SerialProtocol.png "SK6812RBGW serial output protocol (from spec)")

There are two state machines in rgb_sotp.v.
- State Machine 1 coordinates reading from the FIFO, converting 3-bytes to 4-bytes, and buffering the data to State Machine 2
- State Machine 2 blindly does the serial output based on data from State Machine 1, leaving the serial line LOW at the end if it is idle.

In the diagram below, this module is part of the block labeled "Convert 2 RGBW".

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/Concept_FPGA_scaled.jpg "FPGA Concept for FPGA_RBT_2_RBGW")

Kudos to Shawn Hymel of the Digi-Key team; he did the fantastic YouTube series "Digi-Key Introduction to FPGA".
* https://www.youtube.com/watch?v=dXU1py-Od1g
* https://github.com/ShawnHymel/introduction-to-fpga
