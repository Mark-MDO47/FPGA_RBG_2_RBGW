// Mark Olson's mod of Shawn Hymel's take on Clifford Cummings's asynchronous FIFO design
//    change params to default 32 bits data word and 8 bits address (256 x 32 FIFO)
//    use same clock for read and write
//    spread out FIFO access; in my app only one write or read at a time widely separated
//
// Simulation of Clifford Cummings's asynchronous FIFO design from the paper
// at http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
//
// Testbench to verify RTL design of the asynchronous FIFO design. Note that
// this does not check for things like metastability and glitches! You would
// likely need to use a gate-level simulation tool for that.
//
// Notes:
//  - w_* means something is in the "write clock domain"
//  - r_* means something is in the "read clock domain"
//  - Single memory element is DATA_SIZE bits wide
//  - Memory is 2^ADDR_SIZE elements deep
//
// Date: December 11, 2021
// Author: Shawn Hymel
// License: 0BSD

// Define timescale
`timescale 1 us / 10 ps

// Define our testbench
module async_fifo_tb();

    // Settings
    localparam  DATA_SIZE = 32;
    localparam  ADDR_SIZE = 8;
    
    // Internal signals
    wire    [DATA_SIZE-1:0]     r_data;
    wire                        r_empty;
    wire                        r_full;
    
    // Internal storage elements
    reg                         r_en = 0;
    reg                         r_clk = 0;
    reg                         r_rst = 0;
    reg     [DATA_SIZE-1:0]     w_data;
    reg                         w_en = 0;
    reg                         w_clk = 0;
    reg                         w_rst = 0;
    
    // Variables
    integer                     i;
    
    // Simulation time: 10000 * 1 us = 10 ms
    localparam DURATION = 10000;
    
    // Generate read and write clock signal (about 96 MHz)
    always begin
        #0.005 // 0.04167 for 12 MHz
        r_clk = ~r_clk;
        w_clk = ~w_clk;
    end
    
    // Instantiate FIFO
    async_fifo #(
        .DATA_SIZE(DATA_SIZE),
        .ADDR_SIZE(ADDR_SIZE)
    ) uut (
        .w_data(w_data),
        .w_en(w_en),
        .w_clk(w_clk),
        .w_rst(w_rst),
        .r_en(r_en),
        .r_clk(r_clk),
        .r_rst(r_rst),
        .w_full(w_full),
        .r_data(r_data),
        .r_empty(r_empty)
    );
    
    // Test control: write and read data to/from FIFO
    initial begin
    
        // Pulse resets high to initialize memory and counters
        #0.1
        w_rst = 1;
        r_rst = 1;
        #0.01
        w_rst = 0;
        r_rst = 0;
        #0.005 // line things up
        r_rst = 0;
        
        // Write some data to the FIFO
        for (i = 0; i < 4; i = i + 1) begin
            #0.05
            w_data = i;
            w_en = 1'b1;
            #0.01
            w_en = 1'b0;
        end
        
        // Try to read more than what's in the FIFO
        for (i = 0; i < 6; i = i + 1) begin
            #0.05
            r_en = 1'b1;
            #0.01
            r_en = 1'b0;
        end
        
        // Fill up FIFO (and then some)
        for (i = 0; i < 18; i = i + 1) begin
            #0.05
            w_en = 1'b1;
            w_data = i;
            #0.01
            w_en = 1'b0;
        end
        
        // Read everything in the FIFO (and then some)
        for (i = 0; i < 20; i = i + 1) begin
            #0.05
            r_en = 1'b1;
            #0.01
            r_en = 1'b0;
        end

        // simultaneous read/write
        for (i = 0; i < 3; i = i + 1) begin
            #0.1
            w_en = 1'b1;
            w_data = i;
            #0.01
            w_en = 1'b0;
        end

        for (i = 3; i < 15; i = i + 1) begin
            #0.1
            r_en = 1'b1;
            w_en = 1'b1;
            w_data = i;
            #0.01
            w_en = 1'b0;
            r_en = 1'b0;
        end
        for (i = 15; i < 20; i = i + 1) begin
            #0.1
            r_en = 1'b1;
            #0.01
            r_en = 1'b0;
        end


    end
    
        // Run simulation
    initial begin
    
        // Create simulation output file 
        $dumpfile("async-fifo_tb.vcd");
        $dumpvars(0, async_fifo_tb);
        
        // Wait for given amount of time for simulation to complete
        #(DURATION)
        
        // Notify and end simulation
        $display("Finished!");
        $finish;
    end

endmodule