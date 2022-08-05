# async_fifo.v in directory rgb_fifo

async_fifo.v is Shawn Hymel's (Digi-Key) implementation of Clifford Cummings's asynchronous FIFO design from the paper at http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf

I have made no changes to async_fifo.v; it is unchanged from https://github.com/ShawnHymel/introduction-to-fpga.git as of 2022-08-04. I have changed the testbed a bit.

async_fifo.v is instantiated to implement a FIFO of 256 @ 32-bit words.

In the FPGA_RBG_2_RBGW design, everything works from the same 96MHZ clock. async_fifo.v can handle different clock domains, but we don't need that full capability.

It is also the case that in FPGA_RBG_2_RBGW, consecutive read accesses and consecutive write accesses are separated by many clocks and are done one 32-bit word at a time.
It is, however, possible that a read and a write happen at the same time, but we will not be doing consecutive reads or consecutive writes.
async_fifo.v is capable of handling multiple consecutive reads or writes but that capability is not used in FPGA_RBG_2_RBGW.

One consequence of this widely separated use of the read or write interface is that the FIFO-full or FIFO-empty inputs will be valid (for our use)
at the time we look at them. FIFO-full might actually lag a bit if words are being removed, but for our use we would prefer that this signal be TRUE
for a little longer than for it not to show TRUE when we are ready to store a word. The same with FIFO-empty.

For information on the format of the 32-bit data words, see the READMEs for
* rbg_sbit2wrd - the block that stores data into the FIFO
* rbg_sotp - the block that reads data from the FIFO
