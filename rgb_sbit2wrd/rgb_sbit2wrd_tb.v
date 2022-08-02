// Testbench for rgb_sinp
// Mark Olson 2022-07-29
//

// Define timescale - approx 48 MHz but we will treat as if 96 MHz
`timescale 10 ns / 1 ps

// Define our testbench
module rgb_sbit2wrd_tb();

    // Internal signals
    wire [31:0] out_word;
    wire out_strobe;
    wire need_a_manger;

    // Storage elements (buttons are active low!)
    reg             clk = 1'b0;
    reg             rst = 1'b0;
    reg             in_strobe = 1'b0;         // input in_strobe to rgb_sbit2wrd
    reg             in_sbit_value = 1'b0;     // when in_strobe, and if (in_stream_reset == 0), bit value of 0 or 1
    reg             in_stream_reset = 1'b0;   // when in_strobe, if 1 then "stream reset" (50 microsec stable value)
    reg             fifo_full = 1'b0;         // when 1, rgb_sbit2wrd cannot strobe a word

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
        .in_strobe(in_strobe),
        .in_sbit_value(in_sbit_value),
        .in_stream_reset(in_stream_reset),
        .no_room_at_the_fifo_inn(fifo_full),
        // outputs
        .out_word(out_word),
        .out_strobe(out_strobe),
        .need_a_manger(fifo_overflow)
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
        
        // see effects of different in_strobe lengths - one clock in_strobe
        in_strobe = 1'b1;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        #2
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        #2
        // see effects of different in_strobe lengths - two clocks in_strobe
        in_strobe = 1'b1;
        in_sbit_value = 1'b1;
        in_stream_reset = 1'b0;
        #4
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        #2
        // see effects of different in_strobe lengths - three clocks in_strobe
        in_strobe = 1'b1;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        #6
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        #2
        // see effects of different in_strobe lengths - four clocks in_strobe
        in_strobe = 1'b1;
        in_sbit_value = 1'b1;
        in_stream_reset = 1'b0;
        #8
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;

        // see effects of in_stream_reset - two clocks in_strobe
        #2
        in_strobe = 1'b1;
        in_sbit_value = 1'b1;
        in_stream_reset = 1'b1;
        #4
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;

        // pass some bits through the serial-to-parallel code - two clocks in_strobe
        for (j = 0; j < 4; j = j + 1) begin
            if (3 == j) fifo_full = 1'b1;
            for (i = 0; i < 12; i = i + 1) begin
                #2
                in_strobe = 1'b1;
                in_sbit_value = bit_first;
                in_stream_reset = 1'b0;
                #4
                in_strobe = 1'b0;
                in_sbit_value = 1'b0;
                in_stream_reset = 1'b0;
                #2
                in_strobe = 1'b1;
                in_sbit_value = bit_second;
                in_stream_reset = 1'b0;
                #4
                in_strobe = 1'b0;
                in_sbit_value = 1'b0;
                in_stream_reset = 1'b0;
                #2
                in_strobe = 1'b1;
                in_sbit_value = bit_first;
                in_stream_reset = 1'b0;
                #8
                in_strobe = 1'b0;
                in_sbit_value = 1'b0;
                in_stream_reset = 1'b0;
                #2
                in_strobe = 1'b1;
                in_sbit_value = bit_second;
                in_stream_reset = 1'b0;
                #8
                in_strobe = 1'b0;
                in_sbit_value = 1'b0;
                in_stream_reset = 1'b0;
            end // i-loop
            bit_first = ~bit_first;
            bit_second = ~bit_second;
            fifo_full = 1'b0;
        end // j-loop
        
        // put stream reset with no bits in counter - two clocks in_strobe
        #2
        in_strobe = 1'b1;
        in_sbit_value = bit_first;
        in_stream_reset = 1'b1;
        #4
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        
        // put stream reset with one bit in counter - two clocks in_strobe
        #2
        in_strobe = 1'b1;
        in_sbit_value = bit_second;
        in_stream_reset = 1'b0;
        #4
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        #2
        in_strobe = 1'b1;
        in_sbit_value = 1'b1;
        in_stream_reset = 1'b1;
        #4
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;

        // put stream reset with 23 bits in counter - two clocks in_strobe
        for (i = 0; i < 23; i = i + 1) begin
            #2
            in_strobe = 1'b1;
            in_sbit_value = bit_first;
            in_stream_reset = 1'b0;
            #4
            in_strobe = 1'b0;
            in_sbit_value = 1'b0;
            in_stream_reset = 1'b0;
            bit_first = ~bit_first;
        end // i-loop
        #2
        in_strobe = 1'b1;
        in_sbit_value = bit_first;
        in_stream_reset = 1'b1;
        #4
        in_strobe = 1'b0;
        in_sbit_value = 1'b0;
        in_stream_reset = 1'b0;
        
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