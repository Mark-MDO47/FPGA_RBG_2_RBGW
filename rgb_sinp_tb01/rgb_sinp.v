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
    output  reg     out,            // when strobe, and if (stream_reset == 0), bit value of 0 or 1
    output  reg     strobe,         // strobes either "out" or "stream_reset"
    output  reg     stream_reset    // when strobe, if 1 then "stream reset" (50 microsec stable value)
);

    // Calculate number of bits needed for the counter
    localparam WIDTH = $clog2(COUNTER_MAX + 1);
    
    // Internal signals
    wire            sig_edge;

    // Internal storage elements
    reg             ff_1;
    reg             ff_2;
    reg             rstff_1;
    reg             rstff_2;
    reg [WIDTH-1:0] count = 0;

    // reg             debug = 0;
    
    // Counter starts when outputs of the two flip-flops are different
    assign sig_edge = ff_1 ^ ff_2;

    // Logic to sample signal after a period of time
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
            ff_2 <= 0;
            out <= 0;
            strobe <= 0;
            stream_reset <= 0;
            count <= 0;
        
        // If rising edge on signal, run counter and sample again
        end else begin
            if (sig != ff_1) begin
                ff_1 <= sig;
                ff_2 <= ff_1;
                if (sig == 1'b1) begin // rising edge; restart count
                    count <= 1;
                    strobe <= 0;
                    out <= 0;
                    stream_reset <= 0;
                end
            end else begin // sig == ff_1
                // debug = ~debug; // this would be to tell we are here
                ff_1 <= sig;
                ff_2 <= ff_1;
                if (strobe == 1'b1) begin
                    strobe <= 1'b0;
                end
                if (stream_reset == 1'b1) begin
                    stream_reset <= 1'b0;
                end
                if (count < SAMPLE_TIME_CLKS) begin
                    count <= count + 1;
                end else if (count == SAMPLE_TIME_CLKS) begin
                    count <= count + 1;
                    out <= ff_2;
                    strobe <= 1'b1;
                end else if (count < STREAM_RESET_CLKS) begin
                    count <= count + 1;
                end else if (count == STREAM_RESET_CLKS) begin
                    count <= count + 1; // only do this code once
                    strobe <= 1;
                    stream_reset <= 1;
                end
            end
        end
    end
    
endmodule