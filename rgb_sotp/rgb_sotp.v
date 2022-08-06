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
    localparam WID_MSB = WIDTH-1;

    localparam bnum_valid             = 5'd31;
    localparam bnum_stream_reset      = 5'd30;
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


    // state machine one (supervisor) gets data from FIFO and feeds serial output
    localparam state1_wait_rst       = 4'd0;
    localparam state1_wait_start     = 4'd1;
    localparam state1_get_fifo_dat   = 4'd2;
    localparam state1_cnvrt_dat_1    = 4'd3;
    localparam state1_cnvrt_dat_2    = 4'd4;
    localparam state1_cnvrt_dat_3    = 4'd5;
    localparam state1_out_red        = 4'd6;
    localparam state1_out_green      = 4'd7;
    localparam state1_out_blue       = 4'd8;
    localparam state1_out_white      = 4'd9;
    localparam state1_out_strm_rst   = 4'd5;

    // state machine 2 (serial output) outputs a byte 1 bit at a time
    localparam state2_wait_rst       = 3'd0;
    localparam state2_wait_start     = 3'd1;
    localparam state2_send_bit       = 3'd2;
    localparam state2_next_bit       = 3'd3;
    localparam state2_send_t0h       = 3'd4;
    localparam state2_send_t0l       = 3'd5;
    localparam state2_send_t1h       = 3'd6;
    localparam state2_send_t1l       = 3'd7;

    // Internal signals
    wire            sig_edge;

    // Internal storage elements
    reg [1:0]       rstff = 2'b00;                  // to debounce rst
    reg [WID_MSB:0] count = WIDTH'd0;
    reg [3:0]       state = state1_wait_rst;
    // reg [7:0]       fifo_dat_status = 8'b0;
    reg [7:0]       fifo_dat_red = 8'b0;
    reg [7:0]       fifo_dat_green = 8'b0;
    reg [7:0]       fifo_dat_blue = 8'b0;
    reg [7:0]       calc_min_color = 8'b0;
    // reg          debug = 0;
    
    // Logic
    always @ (posedge clk) begin
        // remove metastability of rst; provide synchronous off
        if (rst == 1'b1) rstff <= 2'b11;
        else             rstff <= {rstff[0], 1'b0};

        if (rstff[1] == 1'b1) begin // Reset processing
            out_sig <= 1'b0;
            out_rd_fifo_en <= 1'b0;
            count <= WIDTH'd0;
            state = state1_wait_fifo;
        // If rising edge on signal, run counter and sample again
        end else begin
            case (state)
                case state1_wait_fifo: begin
                    if (1'b0 == in_rd_fifo_empty) begin
                        out_rd_fifo_en = 1'b1;
                        state <= state1_get_fifo_dat;
                    end
                end // case state1_wait_fifo

                case state1_get_fifo_dat: begin
                    out_rd_fifo_en = 1'b0;
                    if (1'b1 == in_rd_fifo_data[bnum_stream_reset]) begin
                        count = STREAM_RESET_CLKS;
                        state <= state1_strm_rst;
                    end else begin
                        fifo_dat_red   <= in_rd_fifo_data[bnum_R_first_data_bit:bnum_R_last_data_bit];
                        fifo_dat_green <= in_rd_fifo_data[bnum_G_first_data_bit:bnum_G_last_data_bit];
                        fifo_dat_blue  <= in_rd_fifo_data[bnum_B_first_data_bit:bnum_B_last_data_bit];
                        calc_min_color <= in_rd_fifo_data[bnum_B_first_data_bit:bnum_B_last_data_bit];
                        state <= state1_cnvrt_dat_1;
                    end
                end // case state1_wait_fifo

                case state1_cnvrt_dat_1: begin
                    if (calc_min_color > fifo_dat_red) calc_min_color <= fifo_dat_red;
                    state <= state1_cnvrt_dat_2;
                end // case state1_cnvrt_dat_1
                case state1_cnvrt_dat_2: begin
                    if (calc_min_color > fifo_dat_green) calc_min_color <= fifo_dat_green;
                    state <= state1_cnvrt_dat_3;
                end // case state1_cnvrt_dat_2
                case state1_cnvrt_dat_3: begin
                    fifo_dat_red   <= fifo_dat_red - calc_min_color;
                    fifo_dat_green <= fifo_dat_green - calc_min_color;
                    fifo_dat_blue  <= fifo_dat_blue - calc_min_color;

                    state <= state1_SEND_COLORS; FIXME
                end // case state1_cnvrt_dat_3


                case state1_: begin
                        state <= state1_;
                end // case state1_
                case state1_: begin
                    state <= state1_;
                end // case state1_
                case state1_: begin
                        state <= state1_;
                end // case state1_
                case state1_: begin
                    state <= state1_;
                end // case state1_
                case state1_: begin
                        state <= state1_;
                end // case state1_
                case state1_: begin
                    state <= state1_;
                end // case state1_
                case state1_: begin
                        state <= state1_;
                end // case state1_

                // Go to wait_fifo if in unknown state
                default: state <= state1_wait_fifo;
			endcase // on state
        end
    end // always
    
endmodule