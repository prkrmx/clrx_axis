`timescale 1ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/03/2021 10:11:14 AM
// Design Name: 
// Module Name: clrx_top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clrx_top_tb();
    reg       sclk;     // System clock 200 MHz
    reg       rst;      // System reset

    reg        rx_clk;
    reg [27:0] rx_data;
    reg        rx_clkin;
    reg  [3:0] rx_datain;
    reg  [3:0] rx_count;
    reg  [6:0] clk_pattern;


    initial begin
        sclk = 1'b0;
        rst  = 1'b1;

        rx_clk = 1'b0;
        rx_count  = 3'b0;
        clk_pattern  = 7'b1100011;
        rx_data[ 6:0 ] = 7'h1;
        rx_data[13:7 ] = 7'h2;
        rx_data[20:14] = 7'h3;
        rx_data[27:21] = 7'h4;

        #100000
        rst = 1'b0;
    end

    // 200 MHz system clock
    always begin
    #2500 sclk = ~sclk;
    end

    clrx_intf # (
        .DEBUG ("TRUE")
    ) clrx_inst (
        .sclk   (sclk),     // Reference clock for input delay control
        .rstn   (~rst),     // Receiver Reset (active high)
        .hw_rst (rst),

        .XCLK_p     (rx_clkin),
        .XCLK_n     (~rx_clkin), 
        .XCHN_p     (rx_datain),
        .XCHN_n     (~rx_datain)
    );


    // Independent RX data generation
    always begin
        #952 rx_clk <= ~rx_clk;
    end

    always @ (posedge rx_clk) begin
        if (rx_count == 6) begin
            rx_count <= 0;
            rx_data[ 6:0 ] <= rx_data[ 6:0 ] + 1'b1;
            rx_data[13:7 ] <= rx_data[13:7 ] + 1'b1;
            rx_data[20:14] <= rx_data[20:14] + 1'b1;
            rx_data[27:21] <= rx_data[27:21] + 1'b1;
        end else begin
            rx_count <= rx_count + 1'b1;
        end

        rx_clkin     <= clk_pattern[rx_count];
        rx_datain[0] <= rx_data[rx_count+7*0];
        rx_datain[1] <= rx_data[rx_count+7*1];
        rx_datain[2] <= rx_data[rx_count+7*2];
        rx_datain[3] <= rx_data[rx_count+7*3];
    end
endmodule
