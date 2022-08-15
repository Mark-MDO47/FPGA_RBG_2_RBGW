# all_tb.v - simulation of all blocks except for PLL

This simulation sends rgb serial into the input and gets rgbw serial at the output.

The hex input file for rgb is
* 00123456
* 0055AAFF
* 00387942
* FF000000
* 00FF55AA

The FF000000 indicates sending a stream_reset (long time of serial input LOW).

The output can be seen here. Serial input and output are orange, r_empty (FIFO empty) is red.

![alt text](https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW/blob/master/images/all_tb_big.jpg "GTKwave output of all_tb simulation")
