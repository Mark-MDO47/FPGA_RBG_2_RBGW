// Mark Olson 2022-07-16
// (heavily) Modified to capture serial bits using WS2812b protocol
//    see: https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf
//
// We expect to use a 96 MHz clock; derived from the PLL based on our 12 MHz internal clock
// For all min/max timing values, if serial is HIGH 53 to 62 clock ticks after going HIGH
//      then bit is 1; else 0
// Spec says if 50 microsec goes by while serial is LOW (4800 clock ticks) then that is the "stream reset"
//      (means that next bits are for first LED in string)
// We will treat that 50 microsec as a reset whether HIGH or LOW
//
// inputs:
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
// LIMITATIONS:
// There are some constant sig values through reset and beyond that will not produce a stream_reset;
//    however, the stream_reset implies a gap in communications on either input or output protocol so
//    the effect is close enough. ALso it is just a startup issue: if no data ever arrives the output
//    behaves the same as it would if we did pass a stream_reset; if data does arrive then the output
//    will start up just fine. There is a 30 microsecond window (difference between input and output
//    stream reset) that might give different results but the next "line" will flush it through.
//    Since this is just a hobby effort I am not going to pursue it any further.
//
// Based on: Digi-Key Introduction to FPGA #10 Metastability: Debounce signal logic without the use of a clock divider.
//           https://www.youtube.com/watch?v=dXU1py-Od1g
// Based on: https://forum.digikey.com/t/debounce-logic-circuit-vhdl/12573
// Date: December 16, 2021
// Author: Shawn Hymel
// License: 0BSD

// RGB Serial Input logic
module  rgb_sinp #(
    
    // Parameters
    parameter COUNTER_MAX = 5000,           // a little extra room in the counter (makes no difference in bit width)
    parameter STREAM_RESET_CLKS = 4800,     // ~= 50 microsec with 96 MHz clock (PLL from 12 MHz)
    parameter SAMPLE_TIME_CLKS   = 57       // place to sample to see if zero bit or one bit
) (

    // Inputs
    input           clk,            // clock, expected to be 96 MHz
    input           rst,            // reset command: reset this block
    input           sig,            // signal value; we will do metastability mitigation and some debounce here
    
    // Outputs
    output  reg     strobe,         // strobes either "sbit_value" or "stream_reset"
    output  reg     sbit_value,      // when strobe, and if (stream_reset == 0), bit value of 0 or 1
    output  reg     stream_reset    // when strobe, if 1 then "stream reset" (50 microsec stable value)
);

    // Calculate number of bits needed for the counter
    localparam WIDTH = $clog2(COUNTER_MAX + 1);
    
    // Internal signals
    wire            sig_edge;

    // Internal storage elements
    reg             ff_1;
    reg             ff_2;
    reg             strobe_stretch;
    reg             rstff_1;
    reg             rstff_2;
    reg [WIDTH-1:0] count = 0;
    // reg             debug = 0;
    
    // Counter starts when outputs of the two flip-flops are different and ff_2 is HIGH
    assign sig_edge = ff_1 ^ ff_2;

    // Logic
    always @ (posedge clk) begin
        // remove metastability of rst; provide synchronous off
        if (rst == 1'b1) begin
            rstff_2 <= 1'b1;
            rstff_1 <= 1'b1;
        end else begin
            rstff_2 <= rstff_1;
            rstff_1 <= 1'b0;
        end

        // Reset flip-flops
        if (rstff_2 == 1'b1) begin
            ff_1 <= ~sig; // do an edge when come out of reset
            ff_2 <= 1'b0;
            sbit_value <= 1'b0;
            strobe <= 1'b0;
            strobe_stretch <= 1'b0;
            stream_reset <= 1'b0;
            count <= 0;
        
        // If rising edge on signal, run counter and sample again
        end else begin
            ff_1 <= sig;
            ff_2 <= ff_1;
            if (sig_edge) begin
                if (ff_1 == 1'b1) begin // rising edge; restart count
                    count <= 1'b1;
                    strobe <= 1'b0;
                    strobe_stretch <= 1'b0;
                    sbit_value <= 1'b0;
                    stream_reset <= 1'b0;
                end
            end else begin // sig_edge == 1'b0
                // debug = ~debug; // this would be to tell we are here
                if (strobe == 1'b1) begin
                    if (strobe_stretch == 1'b1) begin
                        strobe_stretch <= 1'b0;
                    end else begin
                        strobe <= 1'b0;
                        sbit_value <= 1'b0;
                        stream_reset <= 1'b0;
                    end
                end
                // the strobe == 1 event is far away from any of the following
                if (count < SAMPLE_TIME_CLKS) begin
                    count <= count + 1;
                end else if (count == SAMPLE_TIME_CLKS) begin
                    count <= count + 1;
                    strobe <= 1'b1;
                    strobe_stretch <= 1'b1;
                    sbit_value <= ff_2;
                end else if (count < STREAM_RESET_CLKS) begin
                    count <= count + 1;
                end else if (count == STREAM_RESET_CLKS) begin
                    count <= count + 1; // only do this code once
                    strobe <= 1'b1;
                    strobe_stretch <= 1'b1;
                    stream_reset <= 1'b1;
                end
            end
        end
    end
    
endmodule