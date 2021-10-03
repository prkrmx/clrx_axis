`timescale 1ps/1ps



module clrx_intf # (
    parameter DEBUG = "FALSE"   // Enable internal LVDS termination
)
(
    // System reference clock 200 MHz
    input           sclk,
    // Reset (active low)
    input           rstn,
    // HArdware reset
    input           hw_rst,
    // Receivers Channel 1 - BASE
    input           XCLK_p, XCLK_n,
    input  [3:0]    XCHN_p, XCHN_n,

    // // Receivers Channel 2 - MEDIUM
    // input           YCLK_p, YCLK_n,
    // input  [3:0]    YCHN_p, YCHN_n,


    // AXIS Video Stuff
    input               tready, // axis video ready
    output  [24-1:0] tdata,
    output           tvalid, // output data valid
    output           tuser, // start of frame
    output           tlast, // end of line

    output           lcd,       // LED PLL/MMCM locked 
    output           px_val     // Px ready/valid

    // // Outputs 
    // output          lval,   // Line Valid
    // output          fval,   // Frame Valid
    // output          dval,   // Data Valid
    // output          spare,  // A spare has been defined for future use
    // output [24-1:0] pixels  // Pixels data
); 

//--------------------------------------------------------------
// Parameters
//--------------------------------------------------------------

//--------------------------------------------------------------
// Wires and Registers
//--------------------------------------------------------------

    wire        rst;

    wire        idly_rst;   // IDELAYCTRL reset
    wire        idly_rdy;   // IDELAYCTRL control ready

    wire        locked;     // Receiver PLL/MMCM locked
    wire        px_clk;     // pixels clock
    wire        px_rdy;     // pixels data ready
    wire [27:0] px_data;    // pixels data

    wire            lval;   // Line Valid
    wire            fval;   // Frame Valid
    wire            dval;   // Data Valid
    wire            spare;  // A spare has been defined for future use
    wire [24-1:0]   pixels; // Pixels data



//--------------------------------------------------------------
// Initial 
//--------------------------------------------------------------

    // // Initial reset
    // // TODO: Remember to optimize this shit
    // reg  [24-1:0]   rst_cntr = 24'b0;
    // reg db_rst = 1'b1;
    
	// always @(posedge sclk or negedge rstn) begin : ADC_heartbeat
	// 	if(!rstn) begin
	// 		rst_cntr 	<= 24'b0;
    //         db_rst   	<= 1'b1;
	// 	end else begin
    //         if (rst_cntr == 24'hFFFFFF) begin
    //             db_rst   	<= 1'b0;
    //         end else begin
    //             rst_cntr 	<= rst_cntr + 1'b1;
    //         end
			
	// 	end
	// end  
                     
//--------------------------------------------------------------
// Continuous Assignments
//--------------------------------------------------------------
     // Receiver reset Logic
    assign rst = hw_rst | !rstn;
    assign idly_rst = rst | !locked;
    
    assign lcd = locked;
    assign px_val = px_rdy;



    // assign tdata = pixels;
    // assign tvalid = dval;
    // assign tuser = fval;
    // assign tlast = lval;


//--------------------------------------------------------------
// Logic Blocks
//--------------------------------------------------------------

// Testbench/Simulation stuff 
if (DEBUG == "TRUE") begin
    reg         match, match_lt;
    reg [7:0]   px_count;
    reg [27:0]  px_last; 


    // Data checking per pixel clock
    always @(posedge px_clk or negedge px_rdy) begin
        px_last <= px_data;
        if (!px_rdy) begin
            match <= 1'b0;
        end else if ((px_data[ 6:0 ]  == px_last[ 6:0 ] + 1'b1 )
                    && (px_data[13:7 ]  == px_last[13:7 ] + 1'b1 )
                    && (px_data[20:14]  == px_last[20:14] + 1'b1 )
                    && (px_data[27:21]  == px_last[27:21] + 1'b1 )) begin
            match <= 1'b1;
        end else begin 
            match <= 1'b0;
        end
    end

    // Long term monitor
    always @(posedge px_clk or negedge px_rdy) begin
        if (!px_rdy) begin
            px_count <= 8'b0;
            match_lt <= 1'b0;
        end else if (px_count != 8'hff) begin
            px_count <= px_count + 1'b1;
            match_lt <= match;
        end else begin
            if (!match) 
                match_lt <= 1'b0;
        end
    end
end


//--------------------------------------------------------------
// Instantiate processor platform
//--------------------------------------------------------------

    // IDELAYCTRL control block
    IDELAYCTRL #(
        .SIM_DEVICE ("7SERIES")
    ) IDELAYCTRL_inst (
        .REFCLK     (sclk),
        .RST        (idly_rst),
        .RDY        (idly_rdy)
    );

    // Base Receiver
    node #(
        .LINES          (4),            // Number of data lines
        .CLKIN_PERIOD   (13.332),       // Clock period (ns) of input clock on clkin_p
        .REF_FREQ       (200.0),        // Reference frequency used by idelay controller
        .DIFF_TERM      ("TRUE"),       // Enable internal differential termination
        .USE_PLL        ("FALSE"),      // Enable PLL use rather than MMCM
        .DATA_FORMAT    ("PER_LINE"),   // PER_CLOCK or PER_LINE data formatting
        .CLK_PATTERN    (7'b1100011),   // Clock bit pattern
        .RX_SWAP_MASK   (16'b0),        // Allows P/N inputs to be inverted to ease PCB routing
        .DEBUG          (DEBUG)) 
    node1_inst(
        .clkin_p    (XCLK_p),       // Input from LVDS clock receiver pin
        .clkin_n    (XCLK_n),       // Input from LVDS clock receiver pin
        .datain_p   (XCHN_p),       // Input from LVDS data pins
        .datain_n   (XCHN_n),       // Input from LVDS data pins
        .reset      (rst),          // Reset line

        .lval       (lval),
        .fval       (fval),
        .dval       (dval),
        .spare      (spare),
        .pixels     (pixels),


        .locked     (locked),       // PLL/MMCM locked
        .idly_rdy   (idly_rdy),     // Input delay control ready
        .px_clk     (px_clk),       // Pixel clock output
        .px_data    (px_data),      // Pixel data
        .px_ready   (px_rdy)        // Pixel data ready
    );

endmodule