// Mark Olson 2022-08-04
// Reads WS2812b RGB LED words from FIFO
// Sends serial bits per SK6812 RGBW
//    see: https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf
//    see: https://cdn-shop.adafruit.com/product-files/2757/p2757_SK6812RGBW_REV01.pdf
//
// We expect to use a 96 MHz clock; derived from the PLL based on our 12 MHz internal clock
//
// inputs:
//     Red/Green/Blue/Status 32-bit word and place in FIFO
//          Status: bit7            bit6            bit5
//                  valid           in_stream_reset



//      clk         expected to be 96 MHz clock
//      rst         if high on 2-3 (or more) consecutive clock posedge: reset our circuitry
//      sig         serial line input
//
// outputs:
//      strobe      high for two clocks when stream_reset and sbit_value have meaning
//                  stream_reset    sbit_value       what it means
//                      1               anything    50 microseconds at same level detected
//                      0               0           bit with value "0" detected
//                      0               1           bit with value "1" detected
//

// RGBW Serial Output logic
module  rgb_sotp #(

    // Parameters
    parameter COUNTER_MAX = 7800,           // a little extra room in the counter (makes no difference in bit width)
    parameter STREAM_RESET_CLKS = 7681,     // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
) (

    // Inputs
    input           clk,                // clock, expected to be 96 MHz and synchronous with FIFO r_clk
    input           rst,                // reset command: reset this block
    input           in_rd_fifo_empty,   // FIFO read empty signal
    input [31:0]    in_rd_fifo_data,    // FIFO read data
    
    
    // Outputs
    output reg      out_rd_fifo_en,     // FIFO read-enable (request for r_data)
    output reg      out_sig             // output serial signal value
);

    // Calculate number of bits needed for the counter
    localparam WIDTH = $clog2(COUNTER_MAX + 1);

    localparam bnum_stream_reset      = 5'd30;
    localparam bnum_valid             = 5'd31;
    localparam bnum_G_first_data_bit  = 5'd23; // most significant bit highest; order G-R-B
    localparam bnum_G_last_data_bit   = 5'd16; // most significant bit highest; order G-R-B
    localparam bnum_R_first_data_bit  = 5'd15; // most significant bit highest; order G-R-B
    localparam bnum_R_last_data_bit   = 5'd8;  // most significant bit highest; order G-R-B
    localparam bnum_B_first_data_bit  = 5'd7;  // most significant bit highest; order G-R-B
    localparam bnum_B_last_data_bit   = 5'd0;  // most significant bit highest; order G-R-B

    localparam RGBW_T0H = 16; // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T0L = 74; // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1H = 45; // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1L = 45; // num of clocks to use output - see SK6812RGBW spec

    // Internal signals
    wire            sig_edge;

    // Internal storage elements
    reg [1:0]       rstff = 2'b00;                  // to debounce rst
    reg [WIDTH-1:0] count = 0;
    // reg             debug = 0;
    
    // Counter starts when outputs of the two flip-flops are different and ff_2 is HIGH
    assign sig_edge = ff_1 ^ ff_2;

    // Logic
    always @ (posedge clk) begin
        // remove metastability of rst; provide synchronous off
        if (rst == 1'b1) rstff <= 2'b11;
        else             rstff <= {rstff[0], 1'b0};

        if (rstff[1] == 1'b1) begin // Reset processing
            count <= 0;
        // If rising edge on signal, run counter and sample again
        end else begin
        end
    end
    
endmodule