// rgb_sbit2wrd
// Mark Olson 2022-07-29
//
// use rgb_sinp.v to capture serial bits using WS2812b protocol
// convert to Red/Green/Blue/Status 32-bit word and place in FIFO
//    see: https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf
//
// We expect to use a 96 MHz clock; derived from the PLL based on our 12 MHz internal clock
// inputs:
//      clk         expected to be 96 MHz clock
//      rst         if high on 2-3 (or more) consecutive clock posedge: reset our circuitry
//      strobe      high for two clocks when stream_reset and sbit_value have meaning
//                  stream_reset    sbit_value       what it means
//                      1               anything    50 microseconds at same level detected
//                      0               0           bit with value "0" detected
//                      0               1           bit with value "1" detected
//
// outputs:
//     Red/Green/Blue/Status 32-bit word and place in FIFO
//          Status: bit7            bit6            bit5
//                  valid           stream_reset
//
// LIMITATIONS:
//    none known at this time.
//

// RGB Serial Input logic
module  rgb_sbit2wrd /* #( // Parameters ) */
(

    // Inputs
    input           clk,            // clock, expected to be 96 MHz
    input           rst,            // reset command: reset this block
    input           strobe,         // strobes either "sbit_value" or "stream_reset"
    input           sbit_value,     // when strobe, and if (stream_reset == 0), bit value of 0 or 1
    input           stream_reset,   // when strobe, if 1 then "stream reset" (50 microsec stable value)

    
    // Outputs
    output reg [31:0]   out_word,   // 8-bits each R/G/B & 8-bits status
    output reg          out_strobe  // high for 2 clocks when read out_word
);

    localparam bnum_last_data_bit   = 5'd23;
    localparam bnum_stream_reset    = 5'd30;
    localparam bnum_valid           = 5'd31;

    reg [1:0]       rstff = 2'b00;      // to debounce rst
    reg [4:0]       bcount = 5'd0;      // which bit is next: 0 thru 23 (bnum_last_data_bit)
    reg             saw_strobe = 1'b0;  // set to one when detect strobe high; zero when low again
    reg             strobe_stretch = 1'b0; // stretch my output strobe

    // Logic
    always @ (posedge clk) begin
        // remove metastability of rst; provide synchronous off
        if (rst == 1'b1) rstff <= 2'b11;
        else             rstff <= {rstff[0], 1'b0};

        if (rstff[1] == 1'b1) begin // Reset processing
            out_word    <= 32'd0;
            out_strobe  <= 1'b0;
            strobe_stretch <= 1'b0;
            saw_strobe  <= 1'b0;
            bcount      <= 5'd0;
        end else begin // else non-reset processing
            if (strobe == 1'b1) begin
                if (strobe_stretch == 1'b1) begin
                    strobe_stretch <= 1'b0;
                end else begin
                    out_strobe <= 1'b0;
                end
            end

            if (strobe == 1'b0) begin // end of strobe 
                saw_strobe <= 1'b1;
            end else if ((saw_strobe == 1'b0) && (strobe == 1'b1)) begin // rcvd data to process
                saw_strobe  <= 1'b1;
                out_word[bnum_stream_reset] <= stream_reset;
                out_word[bcount] <= sbit_value;
                
                if ((stream_reset == 1'b1) || (bcount == bnum_last_data_bit)) begin // time to strobe output
                    strobe_stretch <= 1'b1;
                    out_strobe <= 1'b1;
                    out_word[bnum_valid] <= 1'b1;
                    bcount <= 5'd0;
                end else begin // we got another bit but not the last bit
                    bcount <= bcount+5'd1;
                end // got another bit or had data to strobe out
            end // all strobe conditions we process
        end // non-reset processing
    end // always posedge clk
endmodule


