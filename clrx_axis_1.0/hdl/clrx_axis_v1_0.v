
`timescale 1 ns / 1 ps

	module clrx_axis_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input 		 hw_rst, // Hardware reset active low 

		// Receivers Channel 1 - BASE
		input		 XCLK_p, XCLK_n, //CH1 clk
		input [3:0]	 XCHN_p, XCHN_n, //CH1 data

		// Receivers Channel 2 - MEDIUM
		input		 YCLK_p, YCLK_n, //CH2 clk
		input [3:0]	 YCHN_p, YCHN_n, //CH2 data

		input		 STFG_p, STFG_n, // Serial to frame grabber
		output		 STC_p, STC_n, // Serial to camera

		output [3:0] CC_p, CC_n, // Camera control
		output		 locked, // PLL/MMCM locked
		output		 valid, // Pixels output valid

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready
	);


//--------------------------------------------------------------
// Wires and Registers
//--------------------------------------------------------------
	wire [4-1:0] cc; // Camera Control signals
	wire s2fg; // Serial to frame grabber / RX
	wire s2c; // Serial to camera / TX



// Instantiation of Axi Bus Interface S00_AXI
	clrx_axis_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) clrx_axis_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

// Instantiation of Axi Bus Interface M00_AXIS
	clrx_axis_v1_0_M00_AXIS # ( 
		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
	) clrx_axis_v1_0_M00_AXIS_inst (
		.M_AXIS_ACLK(m00_axis_aclk),
		.M_AXIS_ARESETN(m00_axis_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready)
	);


// Instantiation of Axi Bus Interface M00_AXIS
    clrx_intf # (
        .DEBUG ("FALSE")
	) clrx_inst (
        .sclk   (m00_axis_aclk),
        .rstn   (m00_axis_aresetn),
        .hw_rst	(hw_rst),	

        .XCLK_p	(XCLK_p),
        .XCLK_n	(XCLK_n), 
        .XCHN_p	(XCHN_p),
        .XCHN_n	(XCHN_n),

		.YCLK_p	(YCLK_p),
        .YCLK_n	(YCLK_n), 
        .YCHN_p	(YCHN_p),
        .YCHN_n	(YCHN_n),

		.px_val	(valid),
		.lckd	(locked)
    );


	// Add user logic here

    IBUFDS # (.DIFF_TERM("TRUE")) s2fg_inst (.O(s2fg), .I(STFG_p), .IB(STFG_n));
    OBUFDS s2c_inst	 (.I(s2c),  .O(STC_p),  .OB(STC_n));

	genvar	i;
	generate
		for (i = 0; i < 4; i = i + 1) begin
			OBUFDS cc_inst  (.I(cc[i]),  .O(CC_p[i]),  .OB(CC_n[i]));
		end
	endgenerate

	// User logic ends

	endmodule
