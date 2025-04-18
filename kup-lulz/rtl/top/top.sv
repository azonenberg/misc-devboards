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
	@brief Top level module for the design
 */
module top(

	//GPIO output on side SMPMs
	output wire			gpio_p,
	output wire			gpio_n,

	//System refclk
	input wire			clk_156m25_p,
	input wire			clk_156m25_n,

	//GTY refclk
	input wire			refclk_p,
	input wire			refclk_n,

	//SMPM ports are to left PHY on line card
	input wire			smpm_0_rx_p,
	input wire			smpm_0_rx_n,

	output wire			smpm_0_tx_p,
	output wire			smpm_0_tx_n,

	input wire			smpm_1_rx_p,
	input wire			smpm_1_rx_n,

	output wire			smpm_1_tx_p,
	output wire			smpm_1_tx_n,

	input wire			smpm_2_rx_p,
	input wire			smpm_2_rx_n,

	output wire			smpm_2_tx_p,
	output wire			smpm_2_tx_n,

	//SFP0 is 10Gbase-R management interface
	input wire			sfp_0_rx_p,
	input wire			sfp_0_rx_n,

	output wire			sfp_0_tx_p,
	output wire			sfp_0_tx_n,

	//SFP1 is SCCB link to lcbringup
	input wire			sfp_1_rx_p,
	input wire			sfp_1_rx_n,

	output wire			sfp_1_tx_p,
	output wire			sfp_1_tx_n,

	output wire[1:0]	sfp0_rs,
	output wire			sfp0_tx_disable
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// System clock inputs

	wire	clk_156m25;
	wire	refclk;

	TopLevelClocks clocks(
		.clk_156m25_p(clk_156m25_p),
		.clk_156m25_n(clk_156m25_n),

		.refclk_p(refclk_p),
		.refclk_n(refclk_n),

		.gpio_p(gpio_p),
		.gpio_n(gpio_n),

		.clk_156m25(clk_156m25),
		.refclk(refclk)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY quad for the SFP+ interfaces

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_req();

	SFP_Quad sfp_quad_225(
		.clk_156m25(clk_156m25),
		.refclk(refclk),

		.sfp_0_rx_p(sfp_0_rx_p),
		.sfp_0_rx_n(sfp_0_rx_n),

		.sfp_0_tx_p(sfp_0_tx_p),
		.sfp_0_tx_n(sfp_0_tx_n),

		.sfp_1_rx_p(sfp_1_rx_p),
		.sfp_1_rx_n(sfp_1_rx_n),

		.sfp_1_tx_p(sfp_1_tx_p),
		.sfp_1_tx_n(sfp_1_tx_n),

		.sfp0_rs(sfp0_rs),
		.sfp0_tx_disable(sfp0_tx_disable),

		.apb_req(apb_req)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY quad for the SMPM interfaces

	SMPM_Quad smpm_quad_224(
		.clk_156m25(clk_156m25),
		.refclk(refclk),

		.smpm_0_rx_p(smpm_0_rx_p),
		.smpm_0_rx_n(smpm_0_rx_n),

		.smpm_0_tx_p(smpm_0_tx_p),
		.smpm_0_tx_n(smpm_0_tx_n),

		.smpm_1_rx_p(smpm_1_rx_p),
		.smpm_1_rx_n(smpm_1_rx_n),

		.smpm_1_tx_p(smpm_1_tx_p),
		.smpm_1_tx_n(smpm_1_tx_n),

		.smpm_2_rx_p(smpm_2_rx_p),
		.smpm_2_rx_n(smpm_2_rx_n),

		.smpm_2_tx_p(smpm_2_tx_p),
		.smpm_2_tx_n(smpm_2_tx_n)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Root APB bridge (0xc010_0000)

	//TODO: this is temporary just to let us validate things

	localparam NUM_PERIPHERALS	= 4;
	localparam BLOCK_SIZE		= 32'h400;
	localparam ADDR_WIDTH		= $clog2(BLOCK_SIZE);
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(ADDR_WIDTH), .USER_WIDTH(0)) apb1[NUM_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(BLOCK_SIZE),
		.NUM_PORTS(NUM_PERIPHERALS)
	) bridge (
		.upstream(apb_req),
		.downstream(apb1)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Device information

	APB_DeviceInfo_UltraScale devinfo(
		.apb(apb1[0]),
		.clk_dna(apb1[0].pclk),
		.clk_icap(apb1[0].pclk)
	);

endmodule
