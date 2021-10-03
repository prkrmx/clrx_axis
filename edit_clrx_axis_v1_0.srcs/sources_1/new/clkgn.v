//////////////////////////////////////////////////////////////////////////////
//
// Purpose   :  Receiver clock generation, training and alignment
//
// Parameters:  CLKIN_PERIOD - Real - Default = 6.600
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
//              CLK_PATTERN - Binary - Default = 7'b1100011
//                 - Sets the clock pattern that is expected to be received
//                   and is used for aligning the data lines
//                 - Range = 0 to 2^7-1 typically 7'b1100011 or 7'b1100001
//
// Revision History:
//    Rev 1.0 - Initial Release
//////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module clkgn # (
    parameter real     CLKIN_PERIOD = 6.600, // Clock period (ns) of input clock on clkin_p
    parameter real     REF_FREQ     = 300.0, // Reference clock frequency for idelay control
    parameter          DIFF_TERM    = "FALSE", // Enable internal LVDS termination
    parameter          USE_PLL      = "FALSE", // Selects either PLL or MMCM for clocking
    parameter          CLK_PATTERN  = 7'b1100011 // Clock pattern for alignment
)(
    input              clkin_p, // Clock input LVDS P-side
    input              clkin_n, // Clock input LVDS N-side
    input              reset, // Asynchronous interface reset
    input              idly_rdy, // Asynchronous IDELAYCTRL ready
    //
    output             clkdv2, // RX clock div2 output
    output             clkdv8, // RX clock div8 output
    output             locked, // PLL/MMCM locked output
    output     [5-1:0] wr_addr, // RX write_address output
    output reg [5-1:0] cnt_vl, // RX input delay count value output
    output reg         cnt_ld, // RX input delay load output
    output             rx_rst, // RX reset output
    //
    output             px_clk, // Pixel clock output
    output     [5-1:0] rd_addr, // Pixel read address output
    output reg [3-1:0] rd_sqns, // Pixel read sequence output
    output reg         px_rdy // Pixel data ready output
);

    // VCO multiplier for PLL/MMCM 
    //  2  - if clock_period is greater than 600 MHz/7 
    //  1  - if clock period is <= 600 MHz/7  
    //
    localparam VCO_MULTIPLIER = (CLKIN_PERIOD >11.666) ? 2 : 1 ;
    // localparam DELAY_VALUE    = ((CLKIN_PERIOD*1000)/7 <= 1250.0) ? (CLKIN_PERIOD*1000)/7 : 1250.0;

    wire         clkin_p_i; // Buffer diff_p output
    wire         clkin_n_i; // Buffer diff_n output
    wire         clkin_d; // Delayed diff_n output
    wire         pllmmcm_px;
    wire         pllmmcm_dv2;

    wire         lckd_idlrdy; // locked and IDELAYCTRL ready
    reg  [4-1:0] rx_rst_sync;
    reg  [4-1:0] px_rst_sync;
    wire         px_rst;

    wire [8-1:0] dsrz_wr; // ISERDESE2 output data
    reg  [8-1:0] dsrz_rg; // ISERDESE2 registered data 
    reg  [8-1:0] dsrz_lst; // ISERDESE2 last byte

    reg  [5-1:0] wr_cntr; // Pixel write address counter
    reg  [5-1:0] rd_cntr; // Pixel read address counter

    wire [8-1:0] ram_out; // RAM output
    reg  [8-1:1] ram_lst; // RAM last byte

    reg  [4-1:0] px_rdy_sync;
    wire         px_ready;

    reg  [7-1:0] px_data;
    reg  [3-1:0] px_state;
    reg  [3-1:0] px_crct;
    reg          px_rden; // Enable read sequencer
    reg          px_ardy; // Assert pixel ready

    initial begin
        cnt_vl  <= 5'b0;
        cnt_ld  <= 1'b0;
    end


    // Clock input
    IBUFDS_DIFF_OUT # (
        .DIFF_TERM  (DIFF_TERM))
    IBUFDS_DIFF_OUT_inst (
        .I          (clkin_p),
        .IB         (clkin_n),
        .O          (clkin_p_i),
        .OB         (clkin_n_i)
    );

    generate
        if (USE_PLL == "FALSE") begin
            MMCME2_BASE # (
                .CLKIN1_PERIOD      (CLKIN_PERIOD), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
                .BANDWIDTH          ("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
                .CLKFBOUT_MULT_F    (7*VCO_MULTIPLIER), // Multiply value for all CLKOUT (2.000-64.000).
                .CLKFBOUT_PHASE     (0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
                .CLKOUT0_DIVIDE_F   (2*VCO_MULTIPLIER), // Divide amount for CLKOUT0 (1.000-128.000).
                .CLKOUT0_DUTY_CYCLE (0.5),
                .CLKOUT0_PHASE      (0.0),
                .DIVCLK_DIVIDE      (1), // Master division value (1-106)
                .REF_JITTER1        (0.100) // Reference input jitter in UI (0.000-0.999).
            )
            MMCME2_BASE_inst (
                .CLKFBOUT           (pllmmcm_px), // 1-bit output: Feedback clock
                .CLKOUT0            (pllmmcm_dv2), // 1-bit output: CLKOUT0
                .LOCKED             (locked), // 1-bit output: LOCK
                .CLKFBIN            (px_clk), // 1-bit input: Feedback clock
                .CLKIN1             (clkin_p_i), // 1-bit input: Clock
                .PWRDWN             (1'b0), // 1-bit input: Power-down
                .RST                (reset) // 1-bit input: Reset
            );
        end else begin
            PLLE2_BASE #(
                .CLKIN1_PERIOD      (CLKIN_PERIOD), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
                .CLKFBOUT_MULT      (7*VCO_MULTIPLIER), // Multiply value for all CLKOUT, (2-64)
                .CLKFBOUT_PHASE     (0.0), // Phase offset in degrees of CLKFB, (-360.000-360.000).
                .CLKOUT0_DIVIDE     (2*VCO_MULTIPLIER), // Divide amount for CLKOUT0 (1-128)
                .CLKOUT0_DUTY_CYCLE (0.5), // Duty cycle for CLKOUT0 (0.001-0.999)
                .REF_JITTER1        (0.100), // Reference input jitter in UI, (0.000-0.999)
                .DIVCLK_DIVIDE      (1) // Master division value, (1-56)
            )
            PLLE2_BASE_inst (
                .CLKIN1             (clkin_p_i), // 1-bit input: Input clock
                .CLKFBIN            (px_clk), // 1-bit input: Feedback clock
                .PWRDWN             (1'b0), // 1-bit input: Power-down
                .RST                (reset), // 1-bit input: Reset

                .CLKFBOUT           (pllmmcm_px), // 1-bit output: Feedback clock
                .CLKOUT0            (pllmmcm_dv2), // 1-bit output: CLKOUT0
                .LOCKED             (locked) // 1-bit output: LOCK
            );
        end
    endgenerate


    // IDELAYE2: Input Fixed or Variable Delay Element UG953 p.378
    IDELAYE2 #(
        .DELAY_SRC          ("IDATAIN"), // Delay input (IDATAIN, DATAIN)
        .IDELAY_TYPE        ("VARIABLE"), // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        .IDELAY_VALUE       (5), // Input delay tap setting (0-31)
        .REFCLK_FREQUENCY   (REF_FREQ), // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).

        .CINVCTRL_SEL       ("FALSE"), // Enable dynamic clock inversion (FALSE, TRUE)
        .PIPE_SEL           ("FALSE"), // Select pipelined mode, FALSE, TRUE
        .SIGNAL_PATTERN     ("DATA") // DATA, CLOCK input signal
    )
    idelay_cm (
        // TODO: this shit of clock makes antenna on synthesis
        .IDATAIN            (clkin_n_i), // 1-bit input: Data input from the I/O
        .DATAOUT            (clkin_d), // 1-bit output: Delayed data output
        .C                  (clkdv8), // 1-bit input: Clock input
        .CE                 (1'b0), // 1-bit input: Active high enable increment/decrement input
        .REGRST             (!locked), // 1-bit input: Active-high reset tap-delay input
        .INC                (1'b0), // 1-bit input: Increment / Decrement tap delay input
        .DATAIN             (1'b0), // 1-bit input: Internal delay data input
        .LD                 (cnt_ld), // 1-bit input: Load IDELAY_VALUE input
        .CNTVALUEIN         (cnt_vl), // 5-bit input: Counter value input
        .CNTVALUEOUT        () // 5-bit output: Counter value output
    );

    ISERDESE2 #(
        .DATA_RATE           ("DDR"), // DDR, SDR
        .DATA_WIDTH          (8), // Parallel data width (2-8,10,14)
        .DYN_CLKDIV_INV_EN   ("FALSE"), // Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
        .DYN_CLK_INV_EN      ("FALSE"), // Enable DYNCLKINVSEL inversion (FALSE, TRUE)
        .INTERFACE_TYPE      ("NETWORKING"), // MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
        .IOBDELAY            ("IFD"), // NONE, BOTH, IBUF, IFD
        .NUM_CE              (1), // Number of clock enables (1,2)
        .OFB_USED            ("FALSE"), // Select OFB path (FALSE, TRUE)
        .SERDES_MODE         ("MASTER") // MASTER, SLAVE
    )
    iserdes_mm (
        .DDLY               (clkin_d), // Serial data from IDELAYE2
        .RST                (rx_rst), // Active high asynchronous reset
        .CLK                ( clkdv2), // High-speed clock
        .CLKB               (~clkdv2), // Locally inverted High-speed clock
        .CLKDIV             ( clkdv8), // Divided clock

        .Q1                 (dsrz_wr[7]),
        .Q2                 (dsrz_wr[6]),
        .Q3                 (dsrz_wr[5]),
        .Q4                 (dsrz_wr[4]),
        .Q5                 (dsrz_wr[3]),
        .Q6                 (dsrz_wr[2]),
        .Q7                 (dsrz_wr[1]),
        .Q8                 (dsrz_wr[0]),

        .CE1                (1'b1), // 1-bit Clock enable input
        .CE2                (1'b0), // 1-bit Clock enable input

        // Used in Cascade connection
        .SHIFTIN1           (1'b0),
        .SHIFTIN2           (1'b0),
        .SHIFTOUT1          (),
        .SHIFTOUT2          (),
        // Unused stuff
        .CLKDIVP            (1'b0), // Not used here
        .BITSLIP            (1'b0), // Invoke Bitslip 
        .D                  (1'b0), // Data input
        .DYNCLKDIVSEL       (1'b0), // Dynamic CLKDIV inversion
        .DYNCLKSEL          (1'b0), // Dynamic CLK/CLKB inversion
        .OFB                (1'b0), // 1-bit input: Data feedback from OSERDESE2
        .OCLKB              (1'b0), // 1-bit input: High speed negative edge output clock
        .OCLK               (1'b0), // 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY" 
        .O                  () // Combinatorial output
    );


    // Global Clock Buffers
    BUFG  bg_px     (.I(pllmmcm_px),  .O(px_clk)) ;
    BUFG  bg_rxdiv2 (.I(pllmmcm_dv2), .O(clkdv2)) ;

    BUFR #(
        .BUFR_DIVIDE("4"), // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
        .SIM_DEVICE("7SERIES") // Must be set to "7SERIES" 
    )
    BUFR_inst (
        .O      (clkdv8), // 1-bit output: Clock output port
        .CE     (1'b1), // 1-bit input: Active high, clock enable (Divided modes only)
        .CLR    (!locked), // 1-bit input: Active high, asynchronous clear (Divided modes only)
        .I      (pllmmcm_dv2) // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
    );

    //-----------------------------------------------------------------------------
    // Synchronize locked to clkdv8
    assign lckd_idlrdy = locked & idly_rdy;
    always @ (posedge clkdv8 or negedge lckd_idlrdy) begin
        if (~lckd_idlrdy)
            rx_rst_sync <= 4'b1111;
        else
            rx_rst_sync <= {1'b0,rx_rst_sync[3:1]};
    end
    assign rx_rst = rx_rst_sync[0];

    // Synchronize rx_rst to px_clk
    always @ (posedge px_clk or posedge rx_rst) begin
        if (rx_rst)
            px_rst_sync <= 4'b1111;
        else
            px_rst_sync <= {1'b0,px_rst_sync[3:1]};
    end
    assign px_rst = px_rst_sync[0];


    // Pixel write address counter
    always @ (posedge clkdv8) begin
        if (rx_rst)
            wr_cntr <= 5'h5;
        else
            wr_cntr <= wr_cntr + 1'b1;
    end
    assign wr_addr = wr_cntr;

    // Pixel read address counter
    always @ (posedge px_clk) begin
        if (px_rst) begin
            rd_cntr <= 5'h0;
        end else if (rd_sqns != 3'h6) begin
            // Increment counter except when the read sequence is 6
            rd_cntr <= rd_cntr + 1'b1;
        end
    end
    assign rd_addr = rd_cntr;

    // Register data from ISERDESE
    // NOTE: we fucking invert the dsrz_rg because we connected the negative pin (clkin_n_i) to IDELAYE2
    always @ (posedge clkdv8) begin
        dsrz_lst    <= dsrz_wr;
        dsrz_rg     <= ~{dsrz_wr[4:0], dsrz_lst[7:5]};
    end
    //-----------------------------------------------------------------------------
    // Generate 8 Dual Port Distributed RAMS for FIFO
    genvar i;
    generate
        for (i = 0 ; i < 8 ; i = i+1) begin : bit
            RAM32X1D fifo (
                .D     (dsrz_rg[i]),
                .WCLK  (clkdv8),
                .WE    (1'b1),
                .A4    (wr_addr[4]),
                .A3    (wr_addr[3]),
                .A2    (wr_addr[2]),
                .A1    (wr_addr[1]),
                .A0    (wr_addr[0]),
                .SPO   (),
                .DPRA4 (rd_addr[4]),
                .DPRA3 (rd_addr[3]),
                .DPRA2 (rd_addr[2]),
                .DPRA1 (rd_addr[1]),
                .DPRA0 (rd_addr[0]),
                .DPO   (ram_out[i]));
        end
    endgenerate

    //-----------------------------------------------------------------------------
    // Store last read pixel data for one cycle, bit 0 is not required
    always @ (posedge px_clk) begin
        ram_lst[7:1] <= ram_out[7:1];
    end

    //-----------------------------------------------------------------------------
    // Pixel 8-to-7 gearbox
    always @ (posedge px_clk) begin
        if (px_rst) begin
            rd_sqns <= 3'b0;
        end else begin
            rd_sqns <= rd_sqns + px_rden;
            case (rd_sqns )
                3'h0 : px_data <= ram_out[6:0];
                3'h1 : px_data <= {ram_out[5:0], ram_lst[7]};
                3'h2 : px_data <= {ram_out[4:0], ram_lst[7:6]};
                3'h3 : px_data <= {ram_out[3:0], ram_lst[7:5]};
                3'h4 : px_data <= {ram_out[2:0], ram_lst[7:4]};
                3'h5 : px_data <= {ram_out[1:0], ram_lst[7:3]};
                3'h6 : px_data <= {ram_out[0],   ram_lst[7:2]};
                3'h7 : px_data <= {ram_lst[7:1]};
            endcase
        end
    end

    //-----------------------------------------------------------------------------
    // Synchronize px_ready to px_clk
    always @ (posedge px_clk or negedge px_rst) begin
        if (~px_rst) begin
            px_rdy_sync <= {1'b1, px_rdy_sync[3:1]};
        end else begin
            px_rdy_sync <= 4'b0;
        end
    end
    assign px_ready = px_rdy_sync[0];

    //-----------------------------------------------------------------------------
    // Pixel alignment state machine
    always @ (posedge px_clk) begin
        if (px_rst) begin
            px_state <= 3'h1;
            px_rden  <= 1'b0;
            px_ardy  <= 1'b0;
            px_crct  <= 3'h0;
        end else if (px_ready) begin
            // Pixel alignment state machine
            case (px_state)
                // 0x0 - Check alignment
                3'h0: begin
                    if (px_data == CLK_PATTERN) begin
                        px_rden <= 1'b1; // Enable read sequencer
                        px_crct <= px_crct + 1'b1;
                        if (px_crct == 3'h7) begin
                            px_state <= 3'h7; // 0x7 - End state
                        end
                    end else begin
                        px_crct  <= 3'h0;
                        px_rden  <= 1'b0; // Disable read sequencer to slip alignment
                        px_state <= px_state + 1'b1; // 0x1 - Re-enable and wait 6 cycles
                    end
                end
                // 0x1 - Re-enable read sequencer
                3'h1: begin
                    px_rden  <= 1'b1; // Enable read sequencer
                    px_state <= px_state + 1'b1; // Increment to next state
                end
                // 0x6 - Return to alignment check
                3'h6: begin
                    px_rden  <= 1'b1; // Enable ready sequencer
                    px_state <= 3'h0; // 0x0 - Check alignment
                end
                // 0x7 - End state
                3'h7 : begin
                    px_rden  <= 1'b1; // Enable ready sequencer
                    px_ardy  <= 1'b1; // Assert pixel ready
                end
                // Default state
                default: begin
                    px_rden  <= 1'b1; // Enable read sequencer
                    px_state <= px_state + 1'b1; // Increment to next state
                end
            endcase
        end
    end

    // Asynchronous reset for px_rdy output
    always @ (posedge px_clk or posedge px_rst) begin
        if (px_rst) begin
            px_rdy   <= 1'b0;
        end else begin
            px_rdy   <= px_ardy;
        end
    end

endmodule