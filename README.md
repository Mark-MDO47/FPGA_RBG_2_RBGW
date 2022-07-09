# FPGA_RBG_2_RBGW
Lattice iCE40 Verilog FPGA convert WS2812b RGB from ESP32 to SK6812 RGBW

The idea is to use an iCE40 FPGA to input the serial lines of an ESP32 talking to WS2812b RGB individually addressable color LEDs and convert it to serial lines that would operate SK6812 RGBW individually addressable color LEDs.
* https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf
* https://cdn-shop.adafruit.com/product-files/2757/p2757_SK6812RGBW_REV01.pdf

I have friends with SK6812 RGBW installed on the outside of their house, but the controller does not do patterns as exciting as the FastLED library can produce. For instance, see https://github.com/FastLED/FastLED/blob/master/examples/DemoReel100/DemoReel100.ino

I found the code for the ESP32 that generates the bit stream and it looks like I could hack it up to do the job, but somehow that didn't interest me as much as I thought it would. Even if I did that, it wouldn't help with other FastLED controllers besides the ESP32. It did have the advantage of getting me to see some details about the ESP32 "RMT" device; this is a fascinating capability!

Placing an FPGA inline to do the conversion allows me to learn about Verilog, FPGAs, apio, and a host of new material. This did seem interesting!
* https://www.youtube.com/watch?v=lLg1AgA2Xoo&t=3s "Introduction to FPGA Part 1 - What is an FPGA? | Digi-Key Electronics"

However, reading the specs of the two LED controllers I discovered that if the bitrate for the WS2812b is at the spec maximum then it will overflow the spec maximum bitrate of the SK6812 (because we need to transmit 4 bytes RGBW for every three bytes RGB we receive).

Looking again at the FastLED code, it looks like it actually sends 3-byte words at a rate of 33,333 per second (instead of the fastest spec rate of 43,860 per second); this will fit inside the fastest spec 4-byte word rate of 34,722 per second. I still need to validate this data rate.

My first attempt will operate just slightly inside that fastest spec RBGW rate at 34,091 per second, to give a little margin for clock error. Not that I calculated what the max clock error might be; I might need to slow it a little more to make it reliable.

I plan to have a two-port FIFO in between the input and output; maybe this would allow it to work with other controllers that send the RGB data closer to the maximum rate if the LED string is not too long.

If I can get any delivered, I will use the iCEstick evaluation board to house the FPGA part of the project; I am certainly not able to solder a ball-grid-array FPGA myself.
* https://www.latticesemi.com/products/developmentboardsandkits/icestick

Please excuse me if I get RGB and RBG mixed up; Jim and I just finished the SciFi Rubber Band Gun (RBG) that uses WS2812b LEDs:
* https://github.com/Mark-MDO47/RubberBandGun
