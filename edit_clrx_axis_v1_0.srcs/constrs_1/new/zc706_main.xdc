## LEDs
#set_property PACKAGE_PIN W21     [get_ports leds[0]]; ## GPIO_LED_RIGHT
#set_property IOSTANDARD LVCMOS25 [get_ports leds[0]]
#set_property PACKAGE_PIN G2      [get_ports leds[1]]; ## GPIO_LED_CENTER
#set_property IOSTANDARD LVCMOS15 [get_ports leds[1]]
#set_property PACKAGE_PIN Y21     [get_ports leds[2]]; ## GPIO_LED_LEFT
#set_property IOSTANDARD LVCMOS25 [get_ports leds[2]]
#set_property PACKAGE_PIN A17     [get_ports leds[3]]; ## GPIO_LED_0
#set_property IOSTANDARD LVCMOS15 [get_ports leds[3]]

## Buttons
#set_property PACKAGE_PIN R27     [get_ports btns[0]]; ## GPIO_SW_RIGHT
#set_property IOSTANDARD LVCMOS25 [get_ports btns[3]]
#set_property PACKAGE_PIN K15     [get_ports btns[1]]; ## GPIO_SW_CENTER
#set_property IOSTANDARD LVCMOS15 [get_ports btns[3]]
#set_property PACKAGE_PIN AK25    [get_ports btns[2]]; ## GPIO_SW_LEFT
#set_property IOSTANDARD LVCMOS25 [get_ports btns[3]]

## HDMI
#set_property PACKAGE_PIN AB22  [get_ports HDMI_SPDIF_OUT_LS];   ## HDMI_SPDIF_OUT_LS
#set_property PACKAGE_PIN AC23  [get_ports HDMI_INT];    ## HDMI_INT
#set_property PACKAGE_PIN AC21  [get_ports HDMI_SPDIF];  ## HDMI_R_SPDIF
#set_property PACKAGE_PIN U21   [get_ports HDMI_VSYNC];  ## HDMI_R_VSYNC
#set_property PACKAGE_PIN P28   [get_ports HDMI_CLK];    ## HDMI_R_CLK
#set_property PACKAGE_PIN R22   [get_ports HDMI_HSYNC];  ## HDMI_R_HSYNC
#set_property PACKAGE_PIN V24   [get_ports HDMI_DE];     ## HDMI_R_DE

#set_property PACKAGE_PIN U24   [get_ports HDMI_DB[0]];  ## HDMI_R_D4
#set_property PACKAGE_PIN T22   [get_ports HDMI_DB[1]];  ## HDMI_R_D5
#set_property PACKAGE_PIN R23   [get_ports HDMI_DB[2]];  ## HDMI_R_D6
#set_property PACKAGE_PIN AA25  [get_ports HDMI_DB[3]];  ## HDMI_R_D7
#set_property PACKAGE_PIN AE28  [get_ports HDMI_DB[4]];  ## HDMI_R_D8
#set_property PACKAGE_PIN T23   [get_ports HDMI_DB[5]];  ## HDMI_R_D9
#set_property PACKAGE_PIN AB25  [get_ports HDMI_DB[6]];  ## HDMI_R_D10
#set_property PACKAGE_PIN T27   [get_ports HDMI_DB[7]];  ## HDMI_R_D11
#set_property PACKAGE_PIN AD26  [get_ports HDMI_DG[0]];  ## HDMI_R_D16
#set_property PACKAGE_PIN AB26  [get_ports HDMI_DG[1]];  ## HDMI_R_D17
#set_property PACKAGE_PIN AA28  [get_ports HDMI_DG[2]];  ## HDMI_R_D18
#set_property PACKAGE_PIN AC26  [get_ports HDMI_DG[3]];  ## HDMI_R_D19
#set_property PACKAGE_PIN AE30  [get_ports HDMI_DG[4]];  ## HDMI_R_D20
#set_property PACKAGE_PIN Y25   [get_ports HDMI_DG[5]];  ## HDMI_R_D21
#set_property PACKAGE_PIN AA29  [get_ports HDMI_DG[6]];  ## HDMI_R_D22
#set_property PACKAGE_PIN AD30  [get_ports HDMI_DG[7]];  ## HDMI_R_D23
#set_property PACKAGE_PIN Y28   [get_ports HDMI_DR[0]];  ## HDMI_R_D28
#set_property PACKAGE_PIN AF28  [get_ports HDMI_DR[1]];  ## HDMI_R_D29
#set_property PACKAGE_PIN V22   [get_ports HDMI_DR[2]];  ## HDMI_R_D30
#set_property PACKAGE_PIN AA27  [get_ports HDMI_DR[3]];  ## HDMI_R_D31
#set_property PACKAGE_PIN U22   [get_ports HDMI_DR[4]];  ## HDMI_R_D32
#set_property PACKAGE_PIN N28   [get_ports HDMI_DR[5]];  ## HDMI_R_D33
#set_property PACKAGE_PIN V21   [get_ports HDMI_DR[6]];  ## HDMI_R_D34
#set_property PACKAGE_PIN AC22  [get_ports HDMI_DR[7]];  ## HDMI_R_D35
#set_property IOSTANDARD LVDS_25 [get_ports HDMI_*]


## FMC_HPC
## CameraLink Receiver FMC_HPC 
## J2 (Base)
#set_property PACKAGE_PIN AD23 [get_ports CLR_X_P[3]];   ## FMC_HPC_LA11_P
#set_property PACKAGE_PIN AE23 [get_ports CLR_X_N[3]];   ## FMC_HPC_LA11_N
#set_property PACKAGE_PIN AG24 [get_ports CLR_X_P[2]];   ## FMC_HPC_LA10_P
#set_property PACKAGE_PIN AG25 [get_ports CLR_X_N[2]];   ## FMC_HPC_LA10_N
#set_property PACKAGE_PIN AD21 [get_ports CLR_X_P[1]];   ## FMC_HPC_LA09_P
#set_property PACKAGE_PIN AE21 [get_ports CLR_X_N[1]];   ## FMC_HPC_LA09_N
#set_property PACKAGE_PIN AF19 [get_ports CLR_X_P[0]];   ## FMC_HPC_LA08_P
#set_property PACKAGE_PIN AG19 [get_ports CLR_X_N[0]];   ## FMC_HPC_LA08_N

#set_property PACKAGE_PIN AE22 [get_ports CLR_XCLK_P];   ## FMC_HPC_CLK0_M2C_P
#set_property PACKAGE_PIN AF22 [get_ports CLR_XCLK_N];   ## FMC_HPC_CLK0_M2C_N
#create_clock -period 11.764 [get_ports CLR_XCLK_P]

## Clock group constraint to ensure correct clock skew for ISERDESE
#set_property CLOCK_DELAY_GROUP ioclk_group_clkdv [get_nets main_dsn_i/clrx_top_0/inst/node_inst/clkgn_inst/BUFR_inst_0]

#set_false_path -to [get_pins main_dsn_i/clrx_top_0/inst/node_inst/clkgn_inst/iserdes_mm/DDLY]
#set_false_path -to [get_pins {main_dsn_i/clrx_top_0/inst/node_inst/rxd[*].sitpo_inst/px_data_reg[*]/D}]
#set_false_path -to [get_pins {main_dsn_i/clrx_top_0/inst/node_inst/clkgn_inst/ram_lst_reg[*]/D}]
#set_false_path -to [get_pins {main_dsn_i/clrx_top_0/inst/node_inst/rxd[*].sitpo_inst/ram_lst_reg[*]/D}]

#set_property PACKAGE_PIN AJ23 [get_ports CLR_SerTC_P];  ## FMC_HPC_LA07_P
#set_property PACKAGE_PIN AJ24 [get_ports CLR_SerTC_N];  ## FMC_HPC_LA07_N
#set_property PACKAGE_PIN AG22 [get_ports CLR_SerTFG_P]; ## FMC_HPC_LA06_P
#set_property PACKAGE_PIN AH22 [get_ports CLR_SerTFG_N]; ## FMC_HPC_LA06_N

#set_property PACKAGE_PIN AH23 [get_ports CLR_CC_P[0]];    ## FMC_HPC_LA05_P
#set_property PACKAGE_PIN AH24 [get_ports CLR_CC_N[0]];    ## FMC_HPC_LA05_N
#set_property PACKAGE_PIN AJ20 [get_ports CLR_CC_P[1]];    ## FMC_HPC_LA04_P
#set_property PACKAGE_PIN AK20 [get_ports CLR_CC_N[1]];    ## FMC_HPC_LA04_N
#set_property PACKAGE_PIN AH19 [get_ports CLR_CC_P[2]];    ## FMC_HPC_LA03_P
#set_property PACKAGE_PIN AJ19 [get_ports CLR_CC_N[2]];    ## FMC_HPC_LA03_N
#set_property PACKAGE_PIN AK17 [get_ports CLR_CC_P[3]];    ## FMC_HPC_LA02_P
#set_property PACKAGE_PIN AK18 [get_ports CLR_CC_N[3]];    ## FMC_HPC_LA02_N

## J3 (Medium/Full)
#set_property PACKAGE_PIN V27 [get_ports CLR_Y_P[3]];    ## FMC_HPC_LA22_P
#set_property PACKAGE_PIN W30 [get_ports CLR_Y_N[3]];    ## FMC_HPC_LA22_N
#set_property PACKAGE_PIN W29 [get_ports CLR_Y_P[2]];    ## FMC_HPC_LA21_P
#set_property PACKAGE_PIN W30 [get_ports CLR_Y_N[2]];    ## FMC_HPC_LA21_N
#set_property PACKAGE_PIN U25 [get_ports CLR_Y_P[1]];    ## FMC_HPC_LA20_P
#set_property PACKAGE_PIN V26 [get_ports CLR_Y_N[1]];    ## FMC_HPC_LA20_N
#set_property PACKAGE_PIN T24 [get_ports CLR_Y_P[0]];    ## FMC_HPC_LA19_P
#set_property PACKAGE_PIN T25 [get_ports CLR_Y_N[0]];    ## FMC_HPC_LA19_N

#set_property PACKAGE_PIN AF20 [get_ports CLR_YCLK_P];   ## FMC_HPC_LA00_CC_P
#set_property PACKAGE_PIN AG20 [get_ports CLR_YCLK_N];   ## FMC_HPC_LA00_CC_N
#create_clock -period 11.764 [get_ports CLR_YCLK_P]

#set_property PACKAGE_PIN Y22 [get_ports CLR_Y_P[3]];    ## FMC_HPC_LA15_P
#set_property PACKAGE_PIN Y23 [get_ports CLR_Y_N[3]];    ## FMC_HPC_LA15_N
#set_property PACKAGE_PIN AC24 [get_ports CLR_Y_P[2]];   ## FMC_HPC_LA14_P
#set_property PACKAGE_PIN AD24 [get_ports CLR_Y_N[2]];   ## FMC_HPC_LA14_N
#set_property PACKAGE_PIN AA22 [get_ports CLR_Y_P[1]];   ## FMC_HPC_LA13_P
#set_property PACKAGE_PIN AA23 [get_ports CLR_Y_N[1]];   ## FMC_HPC_LA13_N
#set_property PACKAGE_PIN AF23 [get_ports CLR_Y_P[0]];   ## FMC_HPC_LA12_P
#set_property PACKAGE_PIN AF24 [get_ports CLR_Y_N[0]];   ## FMC_HPC_LA12_N

#set_property PACKAGE_PIN AG21 [get_ports CLR_ZCLK_P];   ## FMC_HPC_LA01_CC_P
#set_property PACKAGE_PIN AH21 [get_ports CLR_ZCLK_N];   ## FMC_HPC_LA01_CC_N
#create_clock -period 11.764 [get_ports CLR_ZCLK_P]

#set_property IOSTANDARD LVDS_25 [get_ports CLR_*]
#set_property DIFF_TERM true [get_ports { CLR_X* CLR_Y* CLR_Z* CLR_SerTFG* }]
