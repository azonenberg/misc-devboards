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
	@brief Stuff related to the GTY quad (225) running the four SFP28 interfaces

	This includes the single 10G uplink in the testbed as well as the 5G SCCB link.
 */
module SFP_Quad(

	//System clock input
	input wire				clk_156m25,

	//SERDES reference clock
	input wire				refclk,

	//SFP0 10Gbase-R management interface
	input wire				sfp_0_rx_p,
	input wire				sfp_0_rx_n,

	output wire				sfp_0_tx_p,
	output wire				sfp_0_tx_n,

	//SFP1 is SCCB link to lcbringup
	input wire				sfp_1_rx_p,
	input wire				sfp_1_rx_n,

	output wire				sfp_1_tx_p,
	output wire				sfp_1_tx_n,

	input wire				sfp0_rx_los,
	output wire[1:0]		sfp0_rs,
	output wire				sfp0_tx_disable,

	//SCCB root APB out
	APB.requester			apb_req,

	//AXI interfaces
	AXIStream.transmitter	mgmt0_rx_data,
	AXIStream.receiver		mgmt0_tx_data,
	output wire				mgmt0_tx_clk,

	//Status GPIOs
	output wire				mgmt0_link_up
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Tie off SFP control signals

	assign sfp0_tx_disable = 0;
	assign sfp0_rs = 2'b11;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Quad PLL

	wire[1:0]	sdm_reset = 2'b0;
	wire[1:0]	fbclk_lost;
	wire[1:0]	qpll_lock;
	wire[1:0]	refclk_lost;

	wire[1:0]	qpll_clkout;
	wire[1:0]	qpll_refout;
	wire[1:0]	sdm_toggle = 2'b0;

	//TODO: make the apb do something
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) qpll_apb();
	assign qpll_apb.pclk = clk_156m25;
	assign qpll_apb.preset_n = 1'b0;

	QuadPLL_UltraScale #(
		.QPLL0_MULT(66),	//156.25 MHz * 66 = 10.3125 GHz
							//note that output is DDR so we have to do sub-rate to get 10GbE
		.QPLL1_MULT(64)		//156.25 MHz * 64 = 10.000 GHz
	) qpll_225 (
		.clk_lockdet(clk_156m25),
		.clk_ref_north(2'b0),
		.clk_ref_south(2'b0),
		.clk_ref({1'b0, refclk}),

		.apb(qpll_apb),

		.qpll_powerdown(2'b00),		//using both QPLLs for now

		.qpll0_refclk_sel(3'd1),	//GTREFCLK00
		.qpll1_refclk_sel(3'd1),	//GTREFCLK01

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),

		.qpll_reset(2'h0),			//No runtime resets used
		.sdm_reset(sdm_reset),
		.sdm_toggle(sdm_toggle),

		.fbclk_lost(fbclk_lost),
		.qpll_lock(qpll_lock),
		.refclk_lost(refclk_lost)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// 10Gbase-R management link on SFP+ 0 going to core switch

	AXIS_XGEthernetMACWrapper #(
		.SERDES_TYPE("GTY")
	) xg_mgmt (
		.sfp_rx_p(sfp_0_rx_p),
		.sfp_rx_n(sfp_0_rx_n),

		.sfp_tx_p(sfp_0_tx_p),
		.sfp_tx_n(sfp_0_tx_n),

		.sfp_rx_los(sfp0_rx_los),

		.clk_sys(clk_156m25),

		.clk_ref_north(2'b0),
		.clk_ref_south(2'b0),
		.clk_lockdet(clk_156m25),
		.clk_ref({1'b0, refclk}),

		.qpll_clk(qpll_clkout),
		.qpll_refclk(qpll_refout),
		.qpll_lock(qpll_lock),

		.rxpllclksel(2'b11),		//QPLL0
		.txpllclksel(2'b11),		//QPLL0

		.eth_rx_data(mgmt0_rx_data),
		.eth_tx_data(mgmt0_tx_data),
		.eth_tx_clk(mgmt0_tx_clk),

		.link_up(mgmt0_link_up)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY APB bridge on SFP+ 1 going to Artix board

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_comp();

	//For initial testing, ignore the requester since the Artix board doesn't send anything ot us
	wire	artix_tx_clk;

	GTY_APBBridge #(
		.TX_INVERT(0),
		.RX_INVERT(1),
		.TX_ILA(0),
		.RX_ILA(0)
	) artix_bridge (
		.sysclk(clk_156m25),
		.clk_ref({1'b0, refclk}),

		.rx_p(sfp_1_rx_p),
		.rx_n(sfp_1_rx_n),

		.tx_p(sfp_1_tx_p),
		.tx_n(sfp_1_tx_n),

		.rxoutclk(),
		.txoutclk(artix_tx_clk),

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),
		.qpll_lock(qpll_lock),

		.apb_req(apb_req),
		.apb_comp(apb_comp)
	);

	//Ignore APB completer interface
	assign apb_comp.pclk 		= artix_tx_clk;
	assign apb_comp.preset_n	= 1;
	assign apb_comp.penable		= 0;
	assign apb_comp.psel		= 0;
	assign apb_comp.paddr		= 0;
	assign apb_comp.pwrite		= 0;
	assign apb_comp.pwdata		= 0;
	assign apb_comp.pstrb		= 0;

endmodule
