// Testbench for rgb_sbit2wrd
// Mark Olson 2022-08-09
//

// Define timescale - approx 48 MHz but we will treat as if 96 MHz
`timescale 10 ns / 1 ps

// Define our testbench
module combo_fifo_sotp_tb();

    // Settings FIFO
    localparam  DATA_SIZE = 32;
    localparam  ADDR_SIZE = 8;

    // Settings sotp - timing is faster for quicker test bench and easier checking
    localparam RGBW_T0H = 2;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T0L = 6;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1H = 4;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1L = 4;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_STR_RST = 20;   // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
    localparam COUNTER_MAX = 7800;  // use realistic size counter

    // Internal signals
    wire                        r_en;
    wire    [DATA_SIZE-1:0]     r_data;
    wire                        r_empty;
    wire                        w_full;

    // Internal storage elements sotp
    reg                         rgb_rst = 1'b0;
    wire                        rgbw_out_serial;
    // reg                         r_clk = 0; use FIFO clock

    // Internal storage elements FIFO
    reg                         r_clk = 0;
    reg                         r_rst = 0;
    reg     [DATA_SIZE-1:0]     w_data = 32'd0;
    reg                         w_en = 0;
    reg                         w_clk = 0;
    reg                         w_rst = 0;
    

    // Variables
    integer                     i = 0;
    integer                     j = 0;

    // Simulation time: 25000 * 1 us = 25 ms
    localparam DURATION = 25000;

    // Generate clock signal (not really correlated with time; we are compressing time)
    always begin
        #1
        r_clk <= ~r_clk;
        w_clk <= ~w_clk;
    end

    // Instantiate FIFO
    async_fifo #(
        .DATA_SIZE(DATA_SIZE),
        .ADDR_SIZE(ADDR_SIZE)
    ) fifo (
        .w_data(w_data),    //fifo in/out
        .w_en(w_en),        //fifo in/out
        .w_clk(w_clk),      //fifo in/out
        .w_rst(w_rst),      //fifo in/out
        .r_en(r_en),        //fifo in/out
        .r_clk(r_clk),      //fifo in/out
        .r_rst(r_rst),      //fifo in/out
        .w_full(w_full),    //fifo in/out
        .r_data(r_data),    //fifo in/out
        .r_empty(r_empty)   //fifo in/out
    );

    // Instantiate RGB Serial Bits Input to LED Word module (uses some wait time)
    rgb_sotp #( 
        .RGBW_T0H(RGBW_T0H),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T0L(RGBW_T0L),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T1H(RGBW_T1H),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T1L(RGBW_T1L),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_STR_RST(RGBW_STR_RST),    // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
        .COUNTER_MAX(COUNTER_MAX)       // a little extra room in the counter (makes no difference in bit width)
    ) sotp (
        // inputs
        .clk(r_clk),                // sotp input
        .rst(rgb_rst),              // sotp input
        .in_rd_fifo_empty(r_empty), // sotp input
        .in_rd_fifo_data(r_data),   // sotp input
        // outputs
        .out_rd_fifo_en(r_en),      // sotp output
        .out_sig(rgbw_out_serial)   // sotp output
    );
    
    // Test control: pulse reset and create some RGB bits and timeouts
    initial begin
    

        // Pulse reset
        #10
        r_rst <= 1'b1;
        w_rst <= 1'b1;
        rgb_rst <= 1'b1;
        #50
        r_rst <= 1'b0;
        w_rst <= 1'b0;
        rgb_rst <= 1'b0;
        
        // wait some time after reset then do various inputs
        #100
        rgb_rst <= 1'b0;

    end

        // Run simulation
    initial begin
    
        // Create simulation output file 
        $dumpfile("combo_fifo_sotp_tb.vcd");
        $dumpvars(0, combo_fifo_sotp_tb);
        
        // Wait for given amount of time for simulation to complete
        #(DURATION)
        
        // Notify and end simulation
        $display("Finished!");
        $finish;
    end

endmodule
        
