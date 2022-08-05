# FPGA_RBG_2_RBGW

Lattice iCE40 Verilog FPGA convert WS2812b RGB from ESP32 to SK6812 RGBW

# What's the big idea?

The idea is to use an iCE40 FPGA to input the serial lines of an ESP32 talking to WS2812b RGB individually addressable color LEDs and convert it to serial lines that would operate SK6812 RGBW individually addressable color LEDs.
* https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf
* https://cdn-shop.adafruit.com/product-files/2757/p2757_SK6812RGBW_REV01.pdf

Here is the overall concept:

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/Concept_649x351.jpg "Overall Concept for FPGA_RBT_2_RBGW")

I will use the iCEstick evaluation board to house the FPGA part of the project; I am certainly not able to solder a ball-grid-array FPGA myself. The iCEstick uses the iCE40HX1K-TQ144 package from Lattice Semiconductor.
* https://www.latticesemi.com/products/developmentboardsandkits/icestick
* note: one iCEstick delivered today 25 July!

## The Story

I have friends with SK6812 RGBW installed on the outside of their house, but the controller does not do patterns as exciting as the FastLED library can produce. For instance, see https://github.com/FastLED/FastLED/blob/master/examples/DemoReel100/DemoReel100.ino

I found the code for the ESP32 that generates the bit stream and it looks like I could hack it up to do the job, but somehow that didn't interest me as much as I thought it would. Even if I did that, it wouldn't help with other FastLED controllers besides the ESP32. It did have the advantage of getting me to see some details about the ESP32 "RMT" device; this is a fascinating capability!

Placing an FPGA inline to do the conversion allows me to learn about Verilog, FPGAs, apio, and a host of new material. This did seem interesting!
* https://www.youtube.com/watch?v=lLg1AgA2Xoo&t=3s "Introduction to FPGA Part 1 - What is an FPGA? | Digi-Key Electronics"
* https://verilogguide.readthedocs.io/en/latest/index.html - similar to above but readable, not video 

## 4 pounds of potatos in a 3 pound sack

However, reading the specs of the two LED controllers I discovered that if the bitrate for the WS2812b is at the spec maximum then it will overflow the spec maximum bitrate of the SK6812 (because we need to transmit 4 bytes RGBW for every three bytes RGB we receive).

Looking again at the FastLED code, it looks like the ESP32 code actually sends 3-byte words at a rate of 33,333 per second (instead of the fastest spec rate of 43,860 per second); this will fit inside the fastest spec 4-byte word rate of 34,722 per second. I still need to validate this data rate.

## ... and then the rate of NOT transmitting bits

The reset gap on the WS2812b is "above 50" microseconds while the reset on the SK6812 is 80 microseconds, so between each refresh I lose up to 30 microseconds

## ... and FastLED.delay() continues sending while delaying

Admittedly, they do that so that the dithering algorithms can get more accurate colors. See for instance https://github.com/FastLED/FastLED/issues/1206

However, with my application and the reset gap loss, this is a killer.

I will just make it a rule that when using my FPGA, one must use delay() not FastLED.delay() and the delay must be tuned to avoid a problem.

## FPGA concept

My first attempt will operate just slightly inside that fastest spec RBGW rate at 34,091 32-bit LED colors per second, to give a little margin for clock error. Not that I calculated what the max clock error might be; I might need to slow it a little more to make it reliable.

I plan to have a two-port FIFO in between the input and output; maybe this would allow it to work with other controllers that send the RGB data closer to the maximum rate if the LED string is not too long and they don't continuously send (see the reset gap discussion above).

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/Concept_FPGA_scaled.jpg "FPGA Concept for FPGA_RBT_2_RBGW")

## Oh my aching brain...

Please excuse me if I get RGB and RBG mixed up; Jim and I just finished the SciFi Rubber Band Gun (RBG) that uses WS2812b LEDs. Because of this I am very used to typing RBG.
* https://github.com/Mark-MDO47/RubberBandGun

## My collection of references

https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/References.md
