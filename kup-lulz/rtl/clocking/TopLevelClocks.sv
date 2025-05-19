`timescale 1ns / 1ps
`default_nettype none
/***********************************************************************************************************************
*                                                                                                                      *
* misc-devboards                                                                                                       *
*                                                                                                                      *
* Copyright (c) 2012-2025 Andrew D. Zonenberg                                                                          *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/

/**
	@brief Top level clock input buffers etc
 */
module TopLevelClocks(

	//System refclk
	input wire			clk_156m25_p,
	input wire			clk_156m25_n,

	//GTY refclks
	input wire			refclk_p,
	input wire			refclk_n,

	input wire			refclk2_p,
	input wire			refclk2_n,

	//GPIO output on side SMPMs
	output wire			gpio_p,
	output wire			gpio_n,

	//Clocks out to rest of the system
	output wire			clk_156m25,
	output wire			clk_fabric,
	output wire			refclk,
	output wire			refclk2
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// System clock input

	wire	clk_156m25_raw;
	IBUFDS ibuf(
		.I(clk_156m25_p),
		.IB(clk_156m25_n),
		.O(clk_156m25_raw)
		);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SERDES reference clock inputs

	IBUFDS_GTE4 #(
		.REFCLK_EN_TX_PATH(1'b0),
		.REFCLK_HROW_CK_SEL(2'b10)
	) refclk_ibuf(
		.CEB(1'b0),
		.I(refclk_p),
		.IB(refclk_n),
		.O(refclk),
		.ODIV2()
	);

	IBUFDS_GTE4 #(
		.REFCLK_EN_TX_PATH(1'b0),
		.REFCLK_HROW_CK_SEL(2'b10)
	) refclk2_ibuf(
		.CEB(1'b0),
		.I(refclk2_p),
		.IB(refclk2_n),
		.O(refclk2),
		.ODIV2()
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Output clock buffers

	wire	pll_lock;

	wire	clk_fabric_raw;
	BUFGCE obuf_fabric(
		.I(clk_fabric_raw),
		.O(clk_fabric),
		.CE(pll_lock)
	);

	wire	clk_156m25_out_raw;
	BUFGCE obuf_156m25(
		.I(clk_156m25_out_raw),
		.O(clk_156m25),
		.CE(pll_lock)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Main system PLL

	/*
		156.25 MHz in
		need 156.25 and ~400 out to start (minimum is 390.625 to work... this is actually a nice even multiple of 2.5)

		VCO 1562.5

		VCO 800 - 1600
		PFD 10 - 500
	 */
	wire	clk_fb;
	MMCME4_BASE #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKOUT0_DIVIDE_F(4),		//1562.5 / 4 = 390.625 MHz
		.CLKOUT1_DIVIDE(10),		//1562.5 / 10 = 156.25 MHz
		.CLKOUT2_DIVIDE(10),
		.CLKOUT3_DIVIDE(10),
		.CLKOUT4_DIVIDE(10),
		.CLKOUT5_DIVIDE(10),
		.CLKOUT6_DIVIDE(10),

		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.CLKOUT6_PHASE(0.0),

		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT6_DUTY_CYCLE(0.5),

		.CLKFBOUT_PHASE(0.0),
		.CLKFBOUT_MULT_F(10),		//156.25 * 10 = 1562.5 MHz VCO
		.DIVCLK_DIVIDE(1),

		.CLKIN1_PERIOD(6.4),		//156.25 MHz in

		.STARTUP_WAIT("FALSE")
	) pll (
		.CLKIN1(clk_156m25_raw),
		.RST(1'b0),

		.CLKOUT0(clk_fabric_raw),
		.CLKOUT0B(),
		.CLKOUT1(clk_156m25_out_raw),
		.CLKOUT1B(),
		.CLKOUT2(),
		.CLKOUT2B(),
		.CLKOUT3(),
		.CLKOUT3B(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKOUT6(),

		.CLKFBOUT(clk_fb),
		.CLKFBOUTB(),
		.CLKFBIN(clk_fb),

		.LOCKED(pll_lock),

		.PWRDWN(1'b0)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Echo clock output (not used for anything right now, remove?)

	wire	clk_echo;

	wire	clk_echo_raw;
	assign	clk_echo_raw = clk_156m25;

	ODDRE1 #
	(
		.SRVAL(0),
		.IS_C_INVERTED(0),
		.IS_D1_INVERTED(0),
		.IS_D2_INVERTED(0),
		.SIM_DEVICE("ULTRASCALE_PLUS")
	) ddr_obuf
	(
		.C(clk_echo_raw),
		.D1(0),
		.D2(1),
		.SR(1'b0),
		.Q(clk_echo)
	);

	OBUFDS #(
		.IOSTANDARD("LVDS"),
		.SLEW("FAST")
	) obuf (
		.O(gpio_p),
		.OB(gpio_n),
		.I(clk_echo)
	);

endmodule
