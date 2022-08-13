// Testbench combo2_tb
// Mark Olson 2022-08-12
//

// Define timescale - approx 48 MHz but we will treat as if 96 MHz
`timescale 10 ns / 1 ps

// Define our testbench
module combo2_tb();

    // Settings FIFO
    localparam  DATA_SIZE = 32;
    localparam  ADDR_SIZE = 8;

    // Settings sotp - timing is faster for quicker test bench and easier checking
    /* for high-speed testing
    localparam RGBW_T0H = 2;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T0L = 6;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1H = 4;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1L = 4;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_STR_RST = 20;   // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
    localparam COUNTER_MAX = 7800;  // use realistic size counter
    */
    
    // for realistic speed testing
    localparam RGBW_T0H = 16;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T0L = 74;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1H = 45;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1L = 45;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_STR_RST = 7681;  // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
    localparam COUNTER_MAX = 7800;   // a little extra room in the counter (makes no difference in bit width)


    // Internal signals
    wire                    r_en;
    wire    [DATA_SIZE-1:0] r_data;
    wire                    r_empty;
    wire                    w_full;
    wire                    w_en;
    wire    [DATA_SIZE-1:0] w_data;
    wire                    rgb_wr_fifo_overflow;

    // Internal storage elements sbit2wrd
    reg                     rgb_sbit_strobe = 1'b0;         // input rgb_sbit_strobe to rgb_sbit2wrd
    reg                     rgb_sbit_value = 1'b0;          // when rgb_sbit_strobe, and if (rgb_sbit_stream_reset == 0), bit value of 0 or 1
    reg                     rgb_sbit_stream_reset = 1'b0;   // when rgb_sbit_strobe, if 1 then "stream reset" (50 microsec stable value)
    reg                     sbit_rst = 1'b0;

    // Internal storage elements sotp
    reg                     rgb_rst = 1'b0;
    wire                    rgbw_out_serial;
    // reg                     r_clk = 0; use FIFO clock

    // Internal storage elements FIFO
    reg                     r_clk = 0;
    reg                     r_rst = 0;
    reg                     w_clk = 0;
    reg                     w_rst = 0;

    // testing/debugging
    reg                     bit_first  = 1'b1;
    reg  [5:0]              where_am_i = 6'd0;


    // Variables
    integer                 i = 0;
    integer                 j = 0;

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
    rgb_sbit2wrd /* #( ) */ uut (
        // inputs
        .clk(w_clk),
        .rst(sbit_rst),
        .in_strobe(rgb_sbit_strobe),
        .in_sbit_value(rgb_sbit_value),
        .in_stream_reset(rgb_sbit_stream_reset),
        .in_wr_fifo_full(w_full),
        // outputs
        .out_word(w_data),
        .out_strobe(w_en),
        .out_wr_fifo_overflow(rgb_wr_fifo_overflow)
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
        sbit_rst <= 1'b1;
        #50
        r_rst <= 1'b0;
        w_rst <= 1'b0;
        rgb_rst <= 1'b0;
        sbit_rst <= 1'b0;
        
        // wait some time after reset then do various inputs
        #100
        rgb_rst <= 1'b0;

        // pass some bits through the serial-to-parallel code - two clocks rgb_sbit_strobe
        for (j = 0; j < 4; j = j + 1) begin
            for (i = 0; i < 12; i = i + 1) begin  // 24 bits RGB data
                #2
                where_am_i = where_am_i + 6'd1;
                rgb_sbit_strobe = 1'b1;
                rgb_sbit_value = bit_first;
                rgb_sbit_stream_reset = 1'b0;
                #4
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_value = 1'b0;
                rgb_sbit_stream_reset = 1'b0;
                #2
                where_am_i = where_am_i + 6'd1;
                rgb_sbit_strobe = 1'b1;
                rgb_sbit_value = ~bit_first;
                rgb_sbit_stream_reset = 1'b0;
                #4
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_value = 1'b0;
                rgb_sbit_stream_reset = 1'b0;
            end
            #12
            bit_first = ~bit_first;
        end // j-loop
        
    end

        // Run simulation
    initial begin
    
        // Create simulation output file 
        $dumpfile("combo2_tb.vcd");
        $dumpvars(0, combo2_tb);
        
        // Wait for given amount of time for simulation to complete
        #(DURATION)
        
        // Notify and end simulation
        $display("Finished!");
        $finish;
    end

endmodule
        
