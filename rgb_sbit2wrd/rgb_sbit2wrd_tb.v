// Testbench for rgb_sinp
// Mark Olson 2022-07-29
//

// Define timescale - approx 48 MHz but we will treat as if 96 MHz
`timescale 10 ns / 1 ps

// Define our testbench
module rgb_sbit2wrd_tb();

    // Internal signals

    // Storage elements (buttons are active low!)
    reg             clk = 0;
    reg             rst = 0;
    reg             strobe = 0;         // input strobe to rgb_sbit2wrd
    reg             sbit_value = 0;     // when strobe, and if (stream_reset == 0), bit value of 0 or 1
    reg             stream_reset = 0;   // when strobe, if 1 then "stream reset" (50 microsec stable value)

    // Variables
    integer                     i;

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
        .strobe(strobe),
        .sbit_value(sbit_value),
        .stream_reset(stream_reset),
        // outputs
        .out_word(out_word),
        .out_strobe(out_strobe)
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
        
        // see effects of different strobe lengths - one clock strobe
        strobe = 1'b1;
        sbit_value = 1'b0;
        stream_reset = 1'b0;
        #2
        strobe = 1'b0;
        sbit_value = 1'b0;
        stream_reset = 1'b0;
        #2
        // see effects of different strobe lengths - two clocks strobe
        strobe = 1'b1;
        sbit_value = 1'b1;
        stream_reset = 1'b0;
        #4
        strobe = 1'b0;
        sbit_value = 1'b0;
        stream_reset = 1'b0;
        #2
        // see effects of different strobe lengths - three clocks strobe
        strobe = 1'b1;
        sbit_value = 1'b0;
        stream_reset = 1'b0;
        #6
        strobe = 1'b0;
        sbit_value = 1'b0;
        stream_reset = 1'b0;
        #2
        // see effects of different strobe lengths - four clocks strobe
        strobe = 1'b1;
        sbit_value = 1'b1;
        stream_reset = 1'b0;
        #8
        strobe = 1'b0;
        sbit_value = 1'b0;
        stream_reset = 1'b0;

        // see effects of stream_reset - two clocks strobe
        #2
        strobe = 1'b1;
        sbit_value = 1'b1;
        stream_reset = 1'b1;
        #4
        strobe = 1'b0;
        sbit_value = 1'b0;
        stream_reset = 1'b0;

        // pass some bits through the serial-to-parallel code
        for (i = 0; i < 24; i = i + 1) begin
            #2
            strobe = 1'b1;
            sbit_value = 1'b1;
            stream_reset = 1'b0;
            #4
            strobe = 1'b0;
            sbit_value = 1'b0;
            stream_reset = 1'b0;
            #2
            strobe = 1'b1;
            sbit_value = 1'b0;
            stream_reset = 1'b0;
            #4
            strobe = 1'b0;
            sbit_value = 1'b0;
            stream_reset = 1'b0;
        end
        for (i = 0; i < 24; i = i + 1) begin
            #2
            strobe = 1'b1;
            sbit_value = 1'b0;
            stream_reset = 1'b0;
            #8
            strobe = 1'b0;
            sbit_value = 1'b0;
            stream_reset = 1'b0;
            #2
            strobe = 1'b1;
            sbit_value = 1'b1;
            stream_reset = 1'b0;
            #8
            strobe = 1'b0;
            sbit_value = 1'b0;
            stream_reset = 1'b0;
        end

    end
    
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