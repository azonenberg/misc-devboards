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

	//GTY refclk
	input wire			refclk_p,
	input wire			refclk_n,

	//GPIO output on side SMPMs
	output wire			gpio_p,
	output wire			gpio_n,

	//Clocks out to rest of the system
	output wire			clk_156m25,
	output wire			refclk
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// System clock input

	wire	clk_156m25_raw;
	IBUFDS ibuf(
		.I(clk_156m25_p),
		.IB(clk_156m25_n),
		.O(clk_156m25_raw)
		);

	BUFG bufg(
		.I(clk_156m25_raw),
		.O(clk_156m25));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SERDES reference clock input

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

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Echo clock output

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
