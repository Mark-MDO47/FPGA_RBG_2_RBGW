# real_deal - a build to do the job

To perform a build using the iCEstorm toolset (as in the DigiKey tutorials), copy all the other *.v files (except the testbenches *_tb.v) to this directory and do:
* $ apio build

To perform a critical timing analysis using the iCEstorm toolset do:
* apio raw "icetime -mit -d hx1k hardware.asc" > timing_analysis.txt

Result summary at this time:
* Total number of logic levels: 15
* Total path delay: 9.32 ns (107.35 MHz)

This indicates that the critical path could be clocked at 107.35 MHz. We are using 96 MHz, so this is a good indication.
