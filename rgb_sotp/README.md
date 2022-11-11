# Serial Output Formatter

The serial format used by the  SK6812 RGBW LEDs is different than that of the WS2812b RGB LEDs.

For the SK6812
- the "0" bit is nominally 0.3 microsec high followed by 0.9 microsec low
- the "1" bit is nominally 0.6 microsec high followed by 0.6 microsec low

