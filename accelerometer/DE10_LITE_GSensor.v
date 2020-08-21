// ============================================================================
// Copyright (c) 2016 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//  
//  
//                     web: http://www.terasic.com/  
//                     email: support@terasic.com
//
// ============================================================================
//Date:  Wed May 11 09:51:57 2016
// ============================================================================

module DE10_LITE_GSensor(

	//////////// LED //////////
	output 			  [15:0] 	data_z,
	output 			  [15:0] 	data_y,
	output 			  [15:0] 	data_x,
//	output		     [9:0]		LEDR,

	//////////// CLOCK //////////
	input 		          		MAX10_CLK1_50,

	//////////// KEY //////////
	input 		          		reset,

	//////////// Accelerometer //////////
	output		          		GSENSOR_CS_N,
	input 		     [2:1]		GSENSOR_INT,
	output		          		GSENSOR_SCLK,
	inout 		          		GSENSOR_SDI,
	inout 		          		GSENSOR_SDO

);

//=======================================================
//  REG/WIRE declarations
//=======================================================
wire	        dly_rst;
wire	        spi_clk, spi_clk_out;
//wire	[15:0]  data_x;

//=======================================================
//  Structural coding
//=======================================================

//	Reset
reset_delay	u_reset_delay	(	
            .iRSTN(!reset),
            .iCLK(MAX10_CLK1_50),
            .oRST(dly_rst));

//  PLL            
spi_pll     u_spi_pll	(
            .areset(dly_rst),
            .inclk0(MAX10_CLK1_50),
            .c0(spi_clk),      // 2MHz
            .c1(spi_clk_out)); // 2MHz phase shift 

//  Initial Setting and Data Read Back
spi_ee_config u_spi_ee_config (			
						.iRSTN(!dly_rst),															
						.iSPI_CLK(spi_clk),								
						.iSPI_CLK_OUT(spi_clk_out),								
						.iG_INT2(GSENSOR_INT[1]),            
						.data_x(data_x),
						.data_y(data_y),
						.data_z(data_z),
						.SPI_SDIO(GSENSOR_SDI),
						.oSPI_CSN(GSENSOR_CS_N),
						.oSPI_CLK(GSENSOR_SCLK));
			
//	LED
/*
led_driver u_led_driver	(	
						.iRSTN(!dly_rst),
						.iCLK(MAX10_CLK1_50),
						.iDIG(data_x[9:0]),
						.iG_INT2(GSENSOR_INT[1]),            
						.oLED(LEDR));
*/

endmodule
