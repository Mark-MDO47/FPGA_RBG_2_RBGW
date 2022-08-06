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


    // state machine one (supervisor) gets data from FIFO and feeds serial output
    localparam STATE1_GET_FIFO_DAT   = 4'd0;
    localparam STATE1_CNVRT_DAT_1    = 4'd1;
    localparam STATE1_CNVRT_DAT_2    = 4'd2;
    localparam STATE1_CNVRT_DAT_3    = 4'd3;
    localparam STATE1_OUT_RED        = 4'd4; // output order is R/G/B/W
    localparam STATE1_OUT_GREEN      = 4'd5;
    localparam STATE1_OUT_BLUE       = 4'd6;
    localparam STATE1_OUT_LAST       = 4'd7;

    localparam RGBW_T0H = 16; // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T0L = 74; // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1H = 45; // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1L = 45; // num of clocks to use output - see SK6812RGBW spec

    // state machine 2 (serial output) outputs a byte 1 bit at a time
    localparam STATE2_WAIT_START    = 3'd0;
    localparam STATE2_SEND_T0H      = 3'd1;
    localparam STATE2_SEND_T0L      = 3'd2;
    localparam STATE2_SEND_T1H      = 3'd3;
    localparam STATE2_SEND_T1L      = 3'd4;
    localparam STATE2_OUT_STRM_RST  = 3'd5;

    // Internal signals
    wire            sig_edge;

    // Internal storage elements
    reg [1:0]       rstff = 2'b00;                  // to debounce rst

    // State Machine 1 storage - Executive
    reg [3:0]       state1 = STATE1_GET_FIFO_DAT;
    // reg [7:0]       fifo_dat_status = 8'b0;
    reg [7:0]       fifo_dat_red = 8'b0;        // holds red then other colors
    reg [7:0]       fifo_dat_green = 8'b0;
    reg [7:0]       fifo_dat_blue = 8'b0;
    reg [7:0]       calc_min_color = 8'b0;

    // State Machine 2 storage - Serial Out
    reg [3:0]       state2 = STATE2_WAIT_START;
    reg [WID_MSB:0] outserial_count = WIDTH'd0;
    reg [3:0]       outbit_count = 4'd0;

    // reg          debug = 0;
    

    always @ (posedge clk) begin // Logic for state machine 1 - executive
        // executive state machine removes metastability of rst; provide synchronous off
        if (rst == 1'b1) rstff <= 2'b11;
        else             rstff <= {rstff[0], 1'b0};

        if (rstff[1] == 1'b1) begin // Reset processing
            out_rd_fifo_en <= 1'b0;
            state1 <= state1_wait_fifo;
        end else begin
            case (state1)
                case state1_wait_fifo: begin
                    if (1'b0 == in_rd_fifo_empty) begin
                        out_rd_fifo_en <= 1'b1;
                        state1 <= STATE1_GET_FIFO_DAT;
                    end
                end // case state1_wait_fifo
                case STATE1_GET_FIFO_DAT: begin
                    out_rd_fifo_en <= 1'b0;
                    if (1'b1 == in_rd_fifo_data[bnum_stream_reset]) begin
                        outserial_count <= STREAM_RESET_CLKS;
                        outbit_count <= 4'd15; // code for stream_reset
                        state1 <= STATE1_OUT_LAST;
                    end else begin
                        fifo_dat_red   <= in_rd_fifo_data[bnum_R_first_data_bit:bnum_R_last_data_bit];
                        fifo_dat_green <= in_rd_fifo_data[bnum_G_first_data_bit:bnum_G_last_data_bit];
                        fifo_dat_blue  <= in_rd_fifo_data[bnum_B_first_data_bit:bnum_B_last_data_bit];
                        calc_min_color <= in_rd_fifo_data[bnum_B_first_data_bit:bnum_B_last_data_bit];
                        state1 <= STATE1_CNVRT_DAT_1;
                    end
                end // case state1_wait_fifo
                case STATE1_CNVRT_DAT_1: begin
                    if (calc_min_color > fifo_dat_red) calc_min_color <= fifo_dat_red;
                    state1 <= STATE1_CNVRT_DAT_2;
                end // case STATE1_CNVRT_DAT_1
                case STATE1_CNVRT_DAT_2: begin
                    if (calc_min_color > fifo_dat_green) calc_min_color <= fifo_dat_green;
                    state1 <= STATE1_CNVRT_DAT_3;
                end // case STATE1_CNVRT_DAT_2
                case STATE1_CNVRT_DAT_3: begin
                    fifo_dat_red   <= fifo_dat_red - calc_min_color; // use red storage for out
                    fifo_dat_green <= fifo_dat_green - calc_min_color;
                    fifo_dat_blue  <= fifo_dat_blue - calc_min_color;
                    outbit_count <= 4'd8;
                    state1 <= STATE1_OUT_RED;
                end // case STATE1_CNVRT_DAT_3
                case STATE1_OUT_RED: begin // wait for red to go then do green
                    if (4'd0 == outbit_count) begin
                        fifo_dat_red <= fifo_dat_green;
                        outbit_count <= 4'd8;
                        state1 <= STATE1_OUT_GREEN;
                    end
                end // case STATE1_OUT_RED
                case STATE1_OUT_GREEN: begin // wait for green to go then do blue
                    if (4'd0 == outbit_count) begin
                        fifo_dat_red <= fifo_dat_blue;
                        outbit_count <= 4'd8;
                        state1 <= STATE1_OUT_BLUE;
                    end
                end // case STATE1_OUT_GREEN
                case STATE1_OUT_BLUE: begin // wait for blue to go then do white
                    if (4'd0 == outbit_count) begin
                        fifo_dat_red <= calc_min_color;
                        outbit_count <= 4'd8;
                        state1 <= STATE1_OUT_LAST; // white is the last color
                    end
                end // case STATE1_OUT_BLUE
                case STATE1_OUT_LAST: begin // wait for blue to go then do white
                    if (4'd0 == outbit_count) begin
                        state1 <= STATE1_GET_FIFO_DAT;
                    end
                end // case STATE1_OUT_LAST
                default: state1 <= state1_wait_fifo; // Go to wait_fifo if in unknown state
			endcase // on state1
        end // non-reset processing for state machine 1
    end // always for state machine 1

    always @ (posedge clk) begin // Logic for state machine 2
        if (rstff[1] == 1'b1) begin // Reset processing - metastable done in state machine 1
            out_sig <= 1'b0;
            outserial_count <= WIDTH'd0;
            outbit_count <= 4'd0;
            state2 <= STATE2_WAIT_START;
        end else begin
            case (state2)
                case STATE2_WAIT_START: begin
                    if (4'd15 == outbit_count) begin // stream_reset
                        out_sig <= 1'b0;
                        outserial_count = STREAM_RESET_CLKS;
                    end else if (4'd0 != outbit_count) begin
                        out_sig <= 1'b1;
                        outbit_count = outbit_count - 5'd1;
                        if (0'b1 == fifo_dat_red[outbit_count-1]) begin
                            outserial_count = RGBW_T0H;
                            state2 <= STATE2_SEND_T0H;
                        end else begin
                            outserial_count = RGBW_T1H;
                            state2 <= STATE2_SEND_T1H;
                        end
                    end
                end // case STATE2_WAIT_START
                case STATE2_SEND_T0H: begin
                    if (5'd0 != outserial_count) outserial_count = outserial_count - 1;
                    else begin
                        outserial_count = RGBW_T0L;
                        state2 <= STATE2_SEND_T0L;
                    end
                end // case STATE2_SEND_T0H
                case STATE2_SEND_T0L: begin
                    if (5'd0 != outserial_count) outserial_count = outserial_count - 1;
                    else begin
                        if (4'd0 == outbit_count) state2 <= STATE1_GET_FIFO_DAT;
                        else
                            out_sig <= 1'b1;
                            outbit_count = outbit_count - 5'd1;
                            if (0'b1 == fifo_dat_red[outbit_count-1]) begin
                                outserial_count = RGBW_T0H;
                                state2 <= STATE2_SEND_T0H;
                            end else begin
                                outserial_count = RGBW_T1H;
                                state2 <= STATE2_SEND_T1H;
                            end
                        end
                    end // finished T0L
                end // case STATE2_SEND_T0L
                case STATE2_SEND_T1H: begin
                    if (5'd0 != outserial_count) outserial_count = outserial_count - 1;
                    else begin
                        outserial_count = RGBW_T1L;
                        state2 <= STATE2_SEND_T1L;
                    end
                end // case STATE2_SEND_T1H
                case STATE2_SEND_T1L: begin
                    if (5'd0 != outserial_count) outserial_count = outserial_count - 1;
                    else begin
                        if (4'd0 == outbit_count) state2 <= STATE1_GET_FIFO_DAT;
                        else
                            out_sig <= 1'b1;
                            outbit_count = outbit_count - 5'd1;
                            if (0'b1 == fifo_dat_red[outbit_count-1]) begin
                                outserial_count = RGBW_T1H;
                                state2 <= STATE2_SEND_T1H;
                            end else begin
                                outserial_count = RGBW_T1H;
                                state2 <= STATE2_SEND_T1H;
                            end
                        end
                    end // finished T1L
                end // case STATE2_SEND_T1L
                case STATE2_OUT_STRM_RST: begin // 80 microseconds of LOW
                    out_sig <= 1'b0;
                    if (5'd0 != outserial_count) outserial_count <= outserial_count - 5'd1;
                    else begin
                        outbit_count = 5'd0;
                        state2 <= STATE1_GET_FIFO_DAT;
                    end 
                end // case STATE2_OUT_STRM_RST
                default: state2 <= STATE2_WAIT_START; // Go to wait_start if in unknown state
			endcase // on state2
        end // non-reset processing for state machine 2
    end // always for state machine 2
    
endmodule