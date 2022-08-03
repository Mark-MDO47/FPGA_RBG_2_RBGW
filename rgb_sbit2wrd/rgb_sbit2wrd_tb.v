// Testbench for rgb_sinp
// Mark Olson 2022-07-29
//

// Define timescale - approx 48 MHz but we will treat as if 96 MHz
`timescale 10 ns / 1 ps

// Define our testbench
module rgb_sbit2wrd_tb();

    // Internal signals
    wire [31:0] rgb_wr_word;
    wire        rgb_wr_strobe;
    wire        rgb_wr_fifo_overflow;

    // Storage elements (buttons are active low!)
    reg             clk = 1'b0;
    reg             rst = 1'b0;
    reg             rgb_sbit_strobe = 1'b0;         // input rgb_sbit_strobe to rgb_sbit2wrd
    reg             rgb_sbit_value = 1'b0;          // when rgb_sbit_strobe, and if (rgb_sbit_stream_reset == 0), bit value of 0 or 1
    reg             rgb_sbit_stream_reset = 1'b0;   // when rgb_sbit_strobe, if 1 then "stream reset" (50 microsec stable value)
    reg             rgb_wr_fifo_full = 1'b0;               // when 1, rgb_sbit2wrd cannot strobe a word

    reg             bit_first  = 1'b1;
    reg             bit_second = 1'b0;

    // Variables
    integer                     i = 0;
    integer                     j = 0;

    // Simulation time: 25000 * 1 us = 25 ms
    localparam DURATION = 25000;
    localparam STREAM_RESET_CLKS = 4800;
    localparam COUNTER_MAX = STREAM_RESET_CLKS+200;
    localparam SAMPLE_TIME_CLKS = 57;

    // Generate clock signal (not really correlated with time; we are compressing time)
    always begin
        #1
        clk = ~clk;
    end
    
    // Instantiate RGB Serial Bits Input to LED Word module (uses some wait time)
    rgb_sbit2wrd /* #( ) */ uut (
        // inputs
        .clk(clk),
        .rst(rst),
        .in_strobe(rgb_sbit_strobe),
        .in_sbit_value(rgb_sbit_value),
        .in_stream_reset(rgb_sbit_stream_reset),
        .in_wr_fifo_full(rgb_wr_fifo_full),
        // outputs
        .out_word(rgb_wr_word),
        .out_strobe(rgb_wr_strobe),
        .out_wr_fifo_overflow(rgb_wr_fifo_overflow)
    );

    // Test control: pulse reset and create some RGB bits and timeouts
    initial begin
    
        // Pulse reset
        #10
        rst = 1'b1;
        #5
        rst = 1'b0;
        
        // wait some time after reset then do various inputs
        #100
        
        // see effects of different rgb_sbit_strobe lengths - one clock rgb_sbit_strobe
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_value = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        #2
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_value = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        #2
        // see effects of different rgb_sbit_strobe lengths - two clocks rgb_sbit_strobe
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_value = 1'b1;
        rgb_sbit_stream_reset = 1'b0;
        #4
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_value = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        #2
        // see effects of different rgb_sbit_strobe lengths - three clocks rgb_sbit_strobe
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_value = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        #6
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_value = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        #2
        // see effects of different rgb_sbit_strobe lengths - four clocks rgb_sbit_strobe
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_value = 1'b1;
        rgb_sbit_stream_reset = 1'b0;
        #8
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_value = 1'b0;
        rgb_sbit_stream_reset = 1'b0;

        // see effects of rgb_sbit_stream_reset - two clocks rgb_sbit_strobe
        #2
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_value = 1'b1;
        rgb_sbit_stream_reset = 1'b1;
        #4
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_value = 1'b0;
        rgb_sbit_stream_reset = 1'b0;

        // pass some bits through the serial-to-parallel code - two clocks rgb_sbit_strobe
        for (j = 0; j < 4; j = j + 1) begin
            if (3 == j) rgb_wr_fifo_full = 1'b1;
            for (i = 0; i < 12; i = i + 1) begin
                #2
                rgb_sbit_strobe = 1'b1;
                rgb_sbit_strobe = bit_first;
                rgb_sbit_stream_reset = 1'b0;
                #4
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_stream_reset = 1'b0;
                #2
                rgb_sbit_strobe = 1'b1;
                rgb_sbit_strobe = bit_second;
                rgb_sbit_stream_reset = 1'b0;
                #4
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_stream_reset = 1'b0;
                #2
                rgb_sbit_strobe = 1'b1;
                rgb_sbit_strobe = bit_first;
                rgb_sbit_stream_reset = 1'b0;
                #8
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_stream_reset = 1'b0;
                #2
                rgb_sbit_strobe = 1'b1;
                rgb_sbit_strobe = bit_second;
                rgb_sbit_stream_reset = 1'b0;
                #8
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_strobe = 1'b0;
                rgb_sbit_stream_reset = 1'b0;
            end // i-loop
            bit_first = ~bit_first;
            bit_second = ~bit_second;
            rgb_wr_fifo_full = 1'b0;
        end // j-loop
        
        // put stream reset with no bits in counter - two clocks rgb_sbit_strobe
        #2
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_strobe = bit_first;
        rgb_sbit_stream_reset = 1'b1;
        #4
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        
        // put stream reset with one bit in counter - two clocks rgb_sbit_strobe
        #2
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_strobe = bit_second;
        rgb_sbit_stream_reset = 1'b0;
        #4
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        #2
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_stream_reset = 1'b1;
        #4
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_stream_reset = 1'b0;

        // put stream reset with 23 bits in counter - two clocks rgb_sbit_strobe
        for (i = 0; i < 23; i = i + 1) begin
            #2
            rgb_sbit_strobe = 1'b1;
            rgb_sbit_strobe = bit_first;
            rgb_sbit_stream_reset = 1'b0;
            #4
            rgb_sbit_strobe = 1'b0;
            rgb_sbit_strobe = 1'b0;
            rgb_sbit_stream_reset = 1'b0;
            bit_first = ~bit_first;
        end // i-loop
        #2
        rgb_sbit_strobe = 1'b1;
        rgb_sbit_strobe = bit_first;
        rgb_sbit_stream_reset = 1'b1;
        #4
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_strobe = 1'b0;
        rgb_sbit_stream_reset = 1'b0;
        
        #100
        bit_first = ~bit_first;
        


    end // initial
    
    // Run simulation (output to .vcd file)
    initial begin
    
        // Create simulation output file 
        $dumpfile("rgb_sbit2wrd_tb.vcd");
        $dumpvars(0, rgb_sbit2wrd_tb);
        
        // Wait for given amount of time for simulation to complete
        #(DURATION)
        
        // Notify and end simulation
        $display("Finished!");
        $finish;
    end
    
endmodule