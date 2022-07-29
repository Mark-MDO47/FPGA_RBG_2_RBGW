// Testbench for rgb_sinp
// Mark Olson 2022-07-17
//
// based on Testbench for button debounce design
// Date: November 16, 2021
// Author: Shawn Hymel
// License: 0BSD

// Define timescale - approx 48 MHz but we will treat as if 96 MHz
`timescale 10 ns / 1 ps

// Define our testbench
module rgb_sinp_tb();

    // Internal signals
    wire            sbit_value;
    
    // Storage elements (buttons are active low!)
    reg             clk = 0;
    reg             rst = 0;
    reg             inp_sig = 1;
    // integer         i;              // Used in for loop
    // integer         j;              // Used in for loop
    // integer         inp_sig_prev;   // Previous input signal state
    // integer         nbounces;       // Holds random number
    // integer         rdelay;         // Holds random number
    
    
    // Simulation time: 25000 * 1 us = 25 ms
    localparam DURATION = 25000;
    localparam STREAM_RESET_CLKS = 4800;
    localparam COUNTER_MAX = STREAM_RESET_CLKS+200;
    localparam SAMPLE_TIME_CLKS = 57;

    localparam T0H_min = 48;
    localparam T0H_max = 105;
    localparam T1H_min = 124;
    localparam T1H_max = 182;
    localparam T1L_min = 57;
    localparam T1L_max = 115;
    localparam T0L_min = 134;
    localparam T0L_max = 192;
    localparam RGB_rst = 9600;


    // Generate clock signal (about 48 MHz)
    always begin
        #1
        clk = ~clk;
    end
    
    // Instantiate RGB Serial Input (and debouncer) module (uses some wait time)
    rgb_sinp #(
        .COUNTER_MAX(COUNTER_MAX),              // a little spare room in the counter
        .STREAM_RESET_CLKS(STREAM_RESET_CLKS),  // for "stream reset"
        .SAMPLE_TIME_CLKS(SAMPLE_TIME_CLKS)     // sample time for 1 or 0 bit
    ) uut (
        .clk(clk),
        .rst(rst),
        .sig(inp_sig),
        .strobe(strobe),
        .sbit_value(sbit_value),
        .stream_reset(stream_reset)
    );
    
    // Test control: pulse reset and create some RGB bits and timeouts
    initial begin
    
        // Pulse reset
        #10
        rst = 1;
        inp_sig = 0;
        #5
        rst = 0;
        
        // wait some time after reset then do min-min & max-min 1 bit
        #100
        // min-min 1 bit
        inp_sig = 1;
        #T1H_min
        inp_sig = 0;
        #T1L_min
        // max-min 1 bit
        inp_sig = 1;
        #T1H_max
        inp_sig = 0;
        #T1L_min

        // now do min-min & max-min 0 bit
        // min-min 0 bit
        inp_sig = 1;
        #T0H_min
        inp_sig = 0;
        #T0L_min
        // max-min 0 bit
        inp_sig = 1;
        #T0H_max
        inp_sig = 0;
        #T0L_min
        
        // now do a "stream reset" with LOW
        inp_sig = 0;
        #RGB_rst

        // min-min 1 bit
        inp_sig = 1;
        #T1H_min
        inp_sig = 0;
        #T1L_min
        // max-min 0 bit
        inp_sig = 1;
        #T0H_max
        inp_sig = 0;
        #T0L_min

        // now do a "stream reset" with HIGH
        inp_sig = 1;
        #RGB_rst
        inp_sig = 1;
        #T0L_min
        inp_sig = 0;

    end
    
    // Run simulation (output to .vcd file)
    initial begin
    
        // Create simulation output file 
        $dumpfile("rgb_sinp_tb.vcd");
        $dumpvars(0, rgb_sinp_tb);
        
        // Wait for given amount of time for simulation to complete
        #(DURATION)
        
        // Notify and end simulation
        $display("Finished!");
        $finish;
    end
    
endmodule