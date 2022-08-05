# rgb_sbit2wrd

rgb_sbit2wrd takes the output from rgb_sinp.v; that module captures serial bits using WS2812b protocol.
One deviation from the protocol
* stream_reset in protocol is 50+ microseconds at serial signal LOW
* stream_reset from rgb_sinp.v is 50+ microseconds at serial signal unchanged at either LOW or HIGH

It interfaces with async_fifo.v, which is Shawn Hymel's (Digi-Key) implementation of Clifford Cummings's asynchronous FIFO design
from the paper at http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf

In my design, everything works from the same 96MHZ clock. async_fifo.v can handle different clock domains, but we don't need that full capability.

rgb_sbit2wrd uses the FIFO to pass 32-bit words (one byte each Status/Green/Red/Blue) on to the next stage of processing.

## input from rgb_sinp.v

The input from rgb_sinp.v consists of a strobe to tell us the data is ready and then the following data bits:
*      in_strobe      high for two clocks when in_stream_reset and in_sbit_value have meaning
in_stream_reset | in_sbit_value | what it means
---- | ---- | ----
 1 | anything | 50 microseconds at same level detected
 0 | 0 | bit with value "0" detected
 0 | 1 | bit with value "1" detected

Any time we see "in_stream_reset" we immediately stop trying to collect bits and just fill in the 32-bit word Status byte with <valid and in_stream_reset> and send the 32-bit word to the FIFO.

## interface to async_fifo.v

async_fifo.v 

As mentioned above, both rgb_sbit2wrd and the write-side of the FIFO operate on the same synchronous clock.

The output consists of signals to put a 32-bit word out_word into the FIFO. From most-significant-byte to least
MSbyte | byte | byte | LSbyte
---- | ---- | ---- | ----
 Status | Green | Red | Blue
 
 The Status byte consists of this, with msbit 7 and lsbit 0
 7 | 6 | 5 to 0
---- | ---- | ----
 valid | in_stream_reset | spare
 
 When we have collected a valid out_word, we check the FIFO input in_wr_fifo_full to make sure there is room to store the word.
 
 Usually there is room to store the word so we strobe out_strobe for 1 clock. This stores the word in the FIFO
 
 Otherwise if there is no room (in_wr_fifo_full says the FIFO is full) and we wanted to write something; that is an overflow.
 
 ## FIFO overflow processing
 
 If we get a FIFO overflow, we set our output out_wr_fifo_overflow to HIGH and the only way to bring it low is to reset us.
 out_wr_fifo_overflow might be used at a higher level to light some LEDs to indicate the problem.
 This kind of problem can only be solved by adjusting the input.
 
 At this point we are in some arbitrary point in a stream of data to a string of LEDs and we will lose data.
 The approach to re-synchronize with the input stream is to stop placing data into the FIFO until 
 we get in_stream_reset AND in_wr_fifo_full is 0. This is end of a string of LED words; the next LED word starts at the first LED. It is the perfect place to start up processing again.
  
 
