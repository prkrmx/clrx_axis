//////////////////////////////////////////////////////////////////////////////
//
// Purpose   :  Receiver interface with 1-to-7 deserialization 
//
// Parameters:  LINES - Integer - Default = 5
//                 - # of input data lines
//                 - Range 1 to 24
//              CLKIN_PERIOD - Real - Default = 6.600
//                 - Period in nanoseconds of the input clock clkin_p
//                 - Range = 6.364 to 17.500
//              REF_FREQ - Real - Default = 300.00
//                 - Frequency of the reference clock provided to IDELAYCTRL
//                 - Range = 200.0 to 800.0
//              DIFF_TERM - String - Default = "FALSE"
//                 - Enable internal LVDS termination
//                 - Range = "FALSE" or "TRUE"
//              USE_PLL - String - Default = "FALSE"
//                 - Selects either PLL or MMCM for clocking
//                 - Range = "FALSE" or "TRUE"
//              DATA_FORMAT - String - Default = "PER_CLOCK"
//                 - Selects format of data bus to map sequential bits 
//                   either on a clock or line basis.  When PER_CLOCK is 
//                   used bits 0 to LINES-1 are the first bits received
//                   from each lane.  When PER_LINE is used bits 0 to 6
//                   are the 7 sequential bits received on line 0
//                 - Range = "PER_CLOCK" or "PER_LINE"
//              CLK_PATTERN - Binary - Default = 7'b1100011
//                 - Sets the clock pattern that is expected to be received
//                   and is used for aligning the data lines
//                 - Range = 0 to 2^7-1 typically 7'b1100011 or 7'b1100001
//              RX_SWAP_MASK - Binary - Default = 16'b0
//                 - Binary value indicating if an input line is inverted
//
// Revision History:
//    Rev 1.0 - Initial Release
//////////////////////////////////////////////////////////////////////////////


`timescale 1ps/1ps

module node # (
    parameter integer LINES        = 5,          // Number of data lines 
    parameter real    CLKIN_PERIOD = 6.600,      // Clock period (ns) of input clock on clkin_p
    parameter real    REF_FREQ     = 300.0,      // Reference clock frequency for idelay control
    parameter         DIFF_TERM    = "FALSE",    // Enable internal differential termination
    parameter         USE_PLL      = "FALSE",    // Enable PLL use rather than MMCM use
    parameter         DATA_FORMAT  = "PER_CLOCK",// Mapping input lines to output bus
    parameter         CLK_PATTERN  = 7'b1100011, // Clock pattern for alignment
    parameter         RX_SWAP_MASK = 16'b0,      // Allows P/N inputs to be invered to ease PCB routing
    parameter         DEBUG        = "FALSE"
    )(
    input                clkin_p,              // Clock input LVDS P-side
    input                clkin_n,              // Clock input LVDS N-side
    input  [LINES-1:0]   datain_p,             // Data input LVDS P-side
    input  [LINES-1:0]   datain_n,             // Data input LVDS N-side
    input                reset,                // Asynchronous interface reset
    input                idly_rdy,           // Asynchronous IDELAYCTRL ready 
    output               locked,           // PLL/MMCM locked output
    //
    //

    (* mark_debug = "true" *)  output reg           lval,
    (* mark_debug = "true" *)  output reg           fval,
    (* mark_debug = "true" *)  output reg           dval,
    (* mark_debug = "true" *)  output reg           spare,
    (* mark_debug = "true" *)  output reg [24-1:0]  pixels,
    //

    output               px_clk,               // Pixel clock output
    output [LINES*7-1:0] px_data,              // Pixel data bus output
    output               px_ready              // Pixel data ready
);


    wire clkdv2;
    wire clkdv8;
    wire rx_rst;
    wire cnt_ld;
    
    wire [5-1:0] cnt_vl;
    wire [5-1:0] rd_addr;
    wire [3-1:0] rd_sqns;
    wire [5-1:0] wr_addr;
    // (* mark_debug = "true" *) wire [LINES*7-1:0] px_raw;
    wire [LINES*7-1:0] px_raw;

    genvar  i;
    genvar  j;

    // Clock Input and Generation
    clkgn # (
        .CLKIN_PERIOD (CLKIN_PERIOD), // Clock period (ns) of input clock on clkin_p
        .REF_FREQ     (REF_FREQ),     // Reference clock frequency for idelay control
        .DIFF_TERM    (DIFF_TERM),    // Enable internal differential termination
        .CLK_PATTERN  (CLK_PATTERN),  // Expected clock pattern
        .USE_PLL      (USE_PLL)       // Enable PLL use rather than MMCM
    )
    clkgn_inst(
        .clkin_p   (clkin_p),     // Input from LVDS clock receiver pin
        .clkin_n   (clkin_n),     // Input from LVDS clock receiver pin
        .reset     (reset),       // Reset 
        .idly_rdy  (idly_rdy),    // Idelay control ready
        .locked    (locked),      // PLL/MMCM locked
        //
        .clkdv2    (clkdv2),   // RX clock div2 output
        .clkdv8    (clkdv8),   // RX clock div8 output
        .rx_rst    (rx_rst),     // RX reset
        .wr_addr   (wr_addr),   // RX write address
        .cnt_vl    (cnt_vl),    // RX input delay count value
        .cnt_ld    (cnt_ld),   // RX input delay load
        //
        .px_clk    (px_clk),       // Pixel clock output
        .rd_addr   (rd_addr),   // Pixel read address
        .rd_sqns   (rd_sqns),    // Pixel read sequence
        .px_rdy    (px_ready)      // Pixel data ready data
    );

    // Data Input 1:7 DESerialization
    generate
        for (i = 0 ; i < LINES ; i = i+1) begin : rxd
            sitpo # (
                .DIFF_TERM  (DIFF_TERM), // Enable internal differential termination
                .REF_FRQ    (REF_FREQ), // Reference clock frequency for idelay control
                .SWAP_MASK  (RX_SWAP_MASK[i]))
            sitpo_inst (
                .clkdv2     (clkdv2), // Clock running at 1/2 data rate
                .clkdv8     (clkdv8), // Clock running at 1/8 data rate
                .px_clk     (px_clk), // Pixel clock running at 1/7 data rate
                .rst        (rx_rst), // Reset

                .din_p      (datain_p[i]),  // Data input LVDS P-side
                .din_n      (datain_n[i]), // Data input LVDS N-side

                .wr_addr    (wr_addr), // RAM write addr
                .rd_addr    (rd_addr), // RAM read address
                .rd_sqns    (rd_sqns), // Pixel read sequence
                .cnt_vl     (cnt_vl), // IDELAYE2 counter value
                .cnt_ld     (cnt_ld), // IDELAYE2 count value load

                .px_data    (px_raw[(i+1)*7-1 -:7]) // Pixel 7-bit pixel data output
            );
        end

        if (DEBUG == "TRUE") begin
            // Data formatting based on the following
            // PER_CLOCK - 5 Lines Example
            //    - [ 4:0 ] - Received on 1st clock edge
            //    - [ 9:5 ] - Received on 2nd clock edge
            //    - [14:10] - Received on 3rd clock edge
            //    - [19:15] - Received on 4th clock edge
            //    - [24:20] - Received on 5th clock edge
            //    - [29:25] - Received on 6th clock edge
            //    - [34:30] - Received on 7th clock edge
            //
            // PER_LINE - 5 Lines Example
            //    - [ 6:0 ] - Received on 1st line ( 0,  1,  2,  3,  4,  5,  6)
            //    - [13:7 ] - Received on 2nd line ( 7,  8,  9, 10, 11, 12, 13)
            //    - [20:14] - Received on 3rd line (14, 15, 16, 17, 18, 18, 20)
            //    - [27:21] - Received on 4th line (21, 22, 23, 24, 25, 26, 27)
            //    - [34:28] - Received on 5th line (28, 29, 30, 31, 32, 33, 34)
            for (i=0; i<LINES; i=i+1) begin :loop1
                for (j=0; j<7   ; j=j+1) begin : loop2
                    if (DATA_FORMAT == "PER_CLOCK")
                        assign px_data[LINES*j+i] = px_raw[7*i+j];
                    else
                        assign px_data[7*i+j]     = px_raw[7*i+j];
                end
            end
        end
    endgenerate



// Camera link pixels mapping per line: 
//    POINTERS
//    - [ 6:0 ] - Received on 1st line ( 0,  1,  2,  3,  4,  5,  6)
//    - [13:7 ] - Received on 2nd line ( 7,  8,  9, 10, 11, 12, 13)
//    - [20:14] - Received on 3rd line (14, 15, 16, 17, 18, 18, 20)
//    - [27:21] - Received on 4th line (21, 22, 23, 24, 25, 26, 27)
//    VALUES
//    - [ 6:0 ] - Received on 1st line (SPARE,   C7,   C6, B7, B6, A7, A6)
//    - [13:7 ] - Received on 2nd line ( DVAL, FVAL, LVAL, C5, C4, C3, C2)
//    - [20:14] - Received on 3rd line (   C1,   C0,   B5, B4, B3, B2, B1)
//    - [27:21] - Received on 4th line (   B0,   A5,   A4, A3, A2, A1, A0)
    always @(posedge px_clk or negedge px_ready) begin
        if (!px_ready) begin
            lval    <= 1'b0;
            fval    <= 1'b0;
            dval    <= 1'b0;
            spare   <= 1'b0;
            pixels  <= 24'b0;
        end else begin
            lval    <= px_raw[9];
            fval    <= px_raw[8];
            dval    <= px_raw[7];
            spare   <= px_raw[0];
            pixels[23:0]  <= {px_raw[1], px_raw[2], px_raw[10], px_raw[11], px_raw[12], px_raw[13], px_raw[14], px_raw[15],
                              px_raw[3], px_raw[4], px_raw[16], px_raw[17], px_raw[18], px_raw[19], px_raw[20], px_raw[21],
                              px_raw[5], px_raw[6], px_raw[22], px_raw[23], px_raw[24], px_raw[25], px_raw[26], px_raw[27]};
        end
    end

endmodule