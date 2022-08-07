// Testbench for rgb_sotp
// Mark Olson 2022-07-29
//

// Define timescale - approx 48 MHz but we will treat as if 96 MHz
`timescale 10 ns / 1 ps

// Define our testbench
module rgb_sotp_tb();

    // Settings - timing is faster for quicker test bench and easier checking
    localparam RGBW_T0H = 2;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T0L = 6;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1H = 4;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1L = 4;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_STR_RST = 20;   // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
    localparam COUNTER_MAX = 7800;  // use realistic size counter

    // Internal signals
    wire        rd_fifo_strobe;
    wire        rgbw_out_serial;

    // Storage elements (buttons are active low!)
    reg             clk = 1'b0;
    reg             rst = 1'b0;
    reg [31:0]      rgb_word = 32'd0;
    reg             rd_fifo_empty = 1'b1; // make sotp wait at the start

    // Variables
    integer                     i = 0;
    integer                     j = 0;

    // Simulation time: 25000 * 1 us = 25 ms
    localparam DURATION = 25000;

    // Generate clock signal (not really correlated with time; we are compressing time)
    always begin
        #1
        clk = ~clk;
    end
    
    // Instantiate RGB Serial Bits Input to LED Word module (uses some wait time)
    rgb_sotp #( 
        .RGBW_T0H(RGBW_T0H),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T0L(RGBW_T0L),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T1H(RGBW_T1H),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T1L(RGBW_T1L),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_STR_RST(RGBW_STR_RST),    // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
        .COUNTER_MAX(COUNTER_MAX)       // a little extra room in the counter (makes no difference in bit width)
    ) uut (
        // inputs
        .clk(clk),
        .rst(rst),
        .in_rd_fifo_empty(rd_fifo_empty),
        .in_rd_fifo_data(rgb_word),
        // outputs
        .out_rd_fifo_en(rd_fifo_strobe),
        .out_sig(rgbw_out_serial)
    );

    // Test control: pulse reset and pass in an RGB word
    initial begin

        rd_fifo_empty = 1'b1; // make sotp wait at start

        // Pulse reset
        #10
        rst = 1'b1;
        #5
        rst = 1'b0;
        
        // wait some time after reset then do various inputs
        #100

        rgb_word = 32'hC0112233;
        rd_fifo_empty = 1'b0;
        #2
        rd_fifo_empty = 1'b1;
        #2
        rgb_word = 32'd0;
        #48
        rgb_word = 32'h80112233;
        rd_fifo_empty = 1'b0;
        #2
        rd_fifo_empty = 1'b1;
        #2
        rgb_word = 32'd0;
        
/*
        for (i = 0; i < 3; i = i + 1) begin
            #2
            if (1'b1 == rd_fifo_strobe) begin
                rgb_word = 32'd0;
                rd_fifo_empty = 1'b1;
            end
        end
*/

    end

        // Run simulation
    initial begin
    
        // Create simulation output file 
        $dumpfile("rgb_sotp_tb.vcd");
        $dumpvars(0, rgb_sotp_tb);
        
        // Wait for given amount of time for simulation to complete
        #(DURATION)
        
        // Notify and end simulation
        $display("Finished!");
        $finish;
    end

endmodule
        
