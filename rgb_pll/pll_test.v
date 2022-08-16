// This is based on tutorial 09 design 01 (PLL test) Digi-Key tutorial on FPGAs #9 https://www.youtube.com/watch?v=gmaSjyUij9E
/*
   $ apio raw "icepll -i 12 -o 96"

   F_PLLIN:    12.000 MHz (given)
   F_PLLOUT:   96.000 MHz (requested)
   F_PLLOUT:   96.000 MHz (achieved)

   FEEDBACK: SIMPLE
   F_PFD:   12.000 MHz
   F_VCO:  768.000 MHz

   DIVR:  0 (4'b0000)
   DIVF: 63 (7'b0111111)
   DIVQ:  3 (3'b011)

   FILTER_RANGE: 1 (3'b001)   
*/                         
module pll_test (          
                           
    // Inputs              
    input   ref_clk,       
                           
    // outputs             
    output  clk,           
    output  locked         
);                         
                           
    // Instantiate PLL (   12 MHz in, 96 MHz out) for iCE_STICK
    SB_PLL40_CORE #(       
        .FEEDBACK_PATH("   SIMPLE"),// don't use fine delay adjustment
        .PLLOUT_SELECT("   GENCLK"),// no phase shift on output
        .DIVR(4'B0000),             // reference clock divider (from icepll tool)
        .DIVF(7'b0111111),          // feedback clock divider (ditto)
        .DIVQ(3'B011),              // VCO clock divider (ditto)
        .FILTER_RANGE(3'B001)       // filter range (ditto)
    ) pll (                
        .REFERENCECLK(ref_clk),     // input clock
        .PLLOUTCORE(clk),           // output clock
        .LOCK(locked),              // locked signal
        .RESETB(1'b1),              // active low reset; set to run always
        .BYPASS(1'b0)               // no bypass, use PLL signal as output
    );                     
                           
endmodule                  