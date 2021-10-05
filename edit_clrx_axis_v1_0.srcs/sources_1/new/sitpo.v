//////////////////////////////////////////////////////////////////////////////
//
// Purpose   :  Serial input to parallel output with 1 to 7 conversion
//
// Parameters:  DIFF_TERM - String - Default = "FALSE"
//                 - Enable internal LVDS termination
//                 - Range = "FALSE" or "TRUE"
//              SWAP_MASK - Binary - Default = 1'b0
//                 - Binary value indicating if an input line is inverted
//
//
// Revision History:
//    Rev 1.0 - Initial Release
//////////////////////////////////////////////////////////////////////////////


`timescale 1ps/1ps

module sitpo # (
    parameter DIFF_TERM = "FALSE", // Enable internal LVDS termination
    parameter SWAP_MASK = 1'b0, // Invert input line
    parameter REF_FRQ = 200.0 // IDELAYCTRL clock input frequency in MHz
)(
    input clkdv2, // Clock running at 1/2 data rate
    input clkdv8, // Clock running at 1/8 data rate
    input px_clk, // Pixel clock running at 1/7 data rate
    input rst, // Reset

    input din_p, // Data input LVDS P-side
    input din_n, // Data input LVDS N-side

    input [5-1:0] wr_addr, // RAM write addr
    input [5-1:0] rd_addr, // RAM read address
    input [3-1:0] rd_sqns, // Pixel read sequence
    input [5-1:0] cnt_vl, // IDELAYE2 counter value
    input cnt_ld, // IDELAYE2 count value load

    output reg [7-1:0] px_data // Pixel 7-bit pixel data output
);

    wire            din_se; // Single ended data input
    wire            din_dd; // Delayed data input

    wire [8-1:0]    dsrz_wr; // ISERDESE2 output data
    reg  [8-1:0]    dsrz_rg; // ISERDESE2 registered data 
    reg  [8-1:0]    dsrz_lst; // ISERDESE2 last byte

    wire [8-1:0]    ram_out; // RAM output
    reg  [8-1:1]    ram_lst; // RAM last byte
    

    // Data Input LVDS Buffer
    IBUFDS # (
        .DIFF_TERM  (DIFF_TERM))
    IBUFDS_inst (
        .I          (din_p),
        .IB         (din_n),
        .O          (din_se)
    );

    // IDELAYE2: Input Fixed or Variable Delay Element UG953 p.378
    IDELAYE2 #(
        .DELAY_SRC          ("IDATAIN"), // Delay input (IDATAIN, DATAIN)
        .IDELAY_TYPE        ("VARIABLE"), // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        .IDELAY_VALUE       (5), // Input delay tap setting (0-31)
        .REFCLK_FREQUENCY   (REF_FRQ), // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).

        .CINVCTRL_SEL       ("FALSE"), // Enable dynamic clock inversion (FALSE, TRUE)
        .PIPE_SEL           ("FALSE"), // Select pipelined mode, FALSE, TRUE
        .SIGNAL_PATTERN     ("DATA") // DATA, CLOCK input signal
    )
    IDELAYE2_inst (
        .IDATAIN            (din_se), // 1-bit input: Data input from the I/O
        .DATAOUT            (din_dd), // 1-bit output: Delayed data output
        .C                  (clkdv8), // 1-bit input: Clock input
        .CE                 (1'b0), // 1-bit input: Active high enable increment/decrement input
        .REGRST             (rst), // 1-bit input: Active-high reset tap-delay input
        .INC                (1'b0), // 1-bit input: Increment / Decrement tap delay input
        .DATAIN             (1'b0), // 1-bit input: Internal delay data input
        .LD                 (cnt_ld), // 1-bit input: Load IDELAY_VALUE input
        .CNTVALUEIN         (cnt_vl), // 5-bit input: Counter value input
        .LDPIPEEN           (), // 1-bit input: Enable PIPELINE register to load data input
        .CNTVALUEOUT        (), // 5-bit output: Counter value output
        .CINVCTRL           () // 1-bit input: Dynamic clock inversion input
    );

    // ISERDESE2: Input SERial/DESerializer with Bitslip UG953 p.412
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
    ISERDESE2_inst (
        .DDLY               (din_dd), // Serial data from IDELAYE2
        .RST                (rst), // Active high asynchronous reset
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

    // Register data from ISERDESE
    always @ (posedge clkdv8) begin : reg_data
        // Fucking swap due to ISERDESE2 shit setup 
        // According of this crap, the data is 1 clock cycles behind.
        // TODO: with this something
        dsrz_lst   <= dsrz_wr;
        if (SWAP_MASK)
            dsrz_rg  <= ~{dsrz_wr[4:0], dsrz_lst[7:5]};
        else
            dsrz_rg  <=  {dsrz_wr[4:0], dsrz_lst[7:5]};
    end

    // Generate 8 Dual Port Distributed RAMS for FIFO
    genvar i;
    generate
        for (i = 0 ; i < 8 ; i = i+1) begin : bit
            RAM32X1D ram_inst (
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

    // Store last read data for one cycle
    always @ (posedge px_clk) begin
        ram_lst[7:1] <= ram_out[7:1];
    end

    // Read 8 to 7 gearbox
    always @ (posedge px_clk) begin
        case (rd_sqns)
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

endmodule