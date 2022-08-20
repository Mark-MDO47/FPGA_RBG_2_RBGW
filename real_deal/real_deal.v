// real_deal https://github.com/Mark-MDO47/FPGA_RBG_2_RBGW
// Mark Olson 2022-08-17
//

// Define our "main"
module real_deal(
    // Inputs              
    input               ref_clk,       
    input               pmod_01_rst_h,
    input               pmod_02_inprgb,
                           
    // outputs       
    output  reg         pmod_03_otprgbw,
    output  reg         pmod_04_ffovflw,
    output  reg         pmod_07_clk_96,           
    output  reg         pmod_08_locked,
    output  reg [3:0]   led_red,
    output  reg         led_green
);

    // Settings for sinp - RGB serial input
    localparam SINP_COUNTER_MAX = 5000;     // a little extra room in the counter (makes no difference in bit width)
    localparam STREAM_RESET_CLKS = 4800;    // ~= 50 microsec with 96 MHz clock (PLL from 12 MHz)
    localparam SAMPLE_TIME_CLKS   = 57;     // place to sample to see if zero bit or one bit
    // rgb_sinp will need inputs that use this many half-clocks
    // localparam T0H_min = 48;
    // localparam T0H_max = 105;
    // localparam T1H_min = 124;
    // localparam T1H_max = 182;
    // localparam T1L_min = 57;
    // localparam T1L_max = 115;
    // localparam T0L_min = 134;
    // localparam T0L_max = 192;
    // localparam RGB_rst = (2*STREAM_RESET_CLKS);

    // Settings for FIFO
    localparam  DATA_SIZE = 32;
    localparam  ADDR_SIZE = 8; // 2^8 or 256
    
    // Settings for sotp - RGBW serial output
    localparam RGBW_T0H = 16;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T0L = 74;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1H = 45;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_T1L = 45;        // num of clocks to use output - see SK6812RGBW spec
    localparam RGBW_STR_RST = 7681;  // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
    localparam SOTP_COUNTER_MAX = 7800; // a little extra room in the counter (makes no difference in bit width)


    // Internal signals
    wire                    r_en;
    wire    [DATA_SIZE-1:0] r_data;
    wire                    r_empty;
    wire                    w_full;
    wire                    w_en;
    wire    [DATA_SIZE-1:0] w_data;
    wire                    s2wd_wr_fifo_overflow;
    wire                    so_out_serial;
    wire                    pll_clk_96;
    wire                    pll_locked;

    // Internal storage elements sinp
    reg [1:0]               rstff = 2'b00;          // to debounce pmod_01_rst_h
    reg                     si_rst = 1'b0;
    wire                    si_2_s2wd_strobe;       // output to rgb_sbit2wrd
    wire                    si_2_s2wd_stream_reset; // when si_2_s2wd_strobe, if 1 then "stream reset" (50 microsec stable value)
    wire                    si_2_s2wd_value;        // when si_2_s2wd_strobe, and if (si_2_s2wd_value == 0), bit value of 0 or 1
    
    // Internal storage elements sbit2wrd
    reg                     s2wd_rst = 1'b0;

    // Internal storage elements FIFO
    reg                     r_rst = 1'b0;
    reg                     w_clk = 1'b0;
    reg                     w_rst = 1'b0;

    // Internal storage elements sotp
    reg                     so_rst = 1'b0;

    always @ (posedge pll_clk_96) begin
        pmod_03_otprgbw <= so_out_serial;
    end


    // Instantiate RGB PLL module
    rgb_pll pll (
        .ref_clk(ref_clk),
        .clk_96(pll_clk_96),
        .locked(pll_locked)
    );
    
    // Instantiate RGB Serial Input module
    rgb_sinp #(
        .COUNTER_MAX(SINP_COUNTER_MAX),         // a little spare room in the counter
        .STREAM_RESET_CLKS(STREAM_RESET_CLKS),  // for "stream reset"
        .SAMPLE_TIME_CLKS(SAMPLE_TIME_CLKS)     // sample time for 1 or 0 bit
    ) sinp (
        .clk(pll_clk_96),
        .rst(si_rst),
        .sig(pmod_02_inprgb),
        .strobe(si_2_s2wd_strobe),
        .sbit_value(si_2_s2wd_value),
        .stream_reset(si_2_s2wd_stream_reset)
    );

    // Instantiate RGB Serial Bits Input to LED Word module
    rgb_sbit2wrd /* #( ) */ sbit2wrd (
        // inputs
        .clk(pll_clk_96),
        .rst(s2wd_rst),
        .in_strobe(si_2_s2wd_strobe),
        .in_sbit_value(si_2_s2wd_value),
        .in_stream_reset(si_2_s2wd_stream_reset),
        .in_wr_fifo_full(w_full),
        // outputs
        .out_word(w_data),
        .out_strobe(w_en),
        .out_wr_fifo_overflow(s2wd_wr_fifo_overflow)
    );

    // Instantiate FIFO
    async_fifo #(
        .DATA_SIZE(DATA_SIZE),
        .ADDR_SIZE(ADDR_SIZE)
    ) fifo (
        .w_data(w_data),
        .w_en(w_en),
        .w_clk(pll_clk_96),
        .w_rst(w_rst),
        .r_en(r_en),
        .r_clk(pll_clk_96),
        .r_rst(r_rst),
        .w_full(w_full),
        .r_data(r_data),
        .r_empty(r_empty)
    );

    // Instantiate Serial Bits Output to RGBW LED Word module
    rgb_sotp #( 
        .RGBW_T0H(RGBW_T0H),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T0L(RGBW_T0L),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T1H(RGBW_T1H),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_T1L(RGBW_T1L),            // num of clocks to use output - see SK6812RGBW spec
        .RGBW_STR_RST(RGBW_STR_RST),    // ~= 80 microsec with 96 MHz clock (PLL from 12 MHz)
        .COUNTER_MAX(SOTP_COUNTER_MAX)  // a little extra room in the counter (makes no difference in bit width)
    ) sotp (
        // inputs
        .clk(pll_clk_96),           // sotp input
        .rst(so_rst),               // sotp input
        .in_rd_fifo_empty(r_empty), // sotp input
        .in_rd_fifo_data(r_data),   // sotp input
        // outputs
        .out_rd_fifo_en(r_en),      // sotp output
        .out_sig(so_out_serial)     // sotp output
    );
    

endmodule
