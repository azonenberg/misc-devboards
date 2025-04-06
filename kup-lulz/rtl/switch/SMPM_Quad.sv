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
	@brief Stuff related to the GTY quad (224) running the four SMPM interfaces (only 3 of 4 provisioned for now)
 */
module SMPM_Quad(

	//System clock input
	input wire			clk_156m25,

	//SERDES reference clock
	input wire			refclk,

	//The actual SERDES interfaces
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
	output wire			smpm_2_tx_n
);

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
	) qpll_224 (
		.clk_lockdet(clk_156m25),
		.clk_ref_north(2'b0),
		.clk_ref_south({1'b0, refclk}),
		.clk_ref(2'b0),

		.apb(qpll_apb),

		.qpll_powerdown(2'b01),		//using QPLL1 for everything so shut down QPLL0

		.qpll0_refclk_sel(3'd5),	//GTSOUTHREFCLK00
		.qpll1_refclk_sel(3'd5),	//GTSOUTHREFCLK01

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
	// The actual SERDES interfaces

	wire[2:0]	rx_p = {smpm_2_rx_p, smpm_1_rx_p, smpm_0_rx_p};
	wire[2:0]	rx_n = {smpm_2_rx_n, smpm_1_rx_n, smpm_0_rx_n};

	wire[2:0]	tx_p = {smpm_2_tx_p, smpm_1_tx_p, smpm_0_tx_p};
	wire[2:0]	tx_n = {smpm_2_tx_n, smpm_1_tx_n, smpm_0_tx_n};

	/*
	logic[2:0]	tx_invert = 3'b111;
	logic[2:0]	rx_invert = 3'b100;
	*/
	wire[2:0] tx_invert;
	wire[2:0] rx_invert;

	//0: both invert
	//1:

	//Reset generation
	logic[14:0] rst_count = 1;
	logic		tx_reset = 1;
	logic		rx_reset = 1;

	always_ff @(posedge clk_156m25) begin
		if(rst_count != 0)
			rst_count	<= rst_count + 1;
		else begin
			tx_reset	<= 0;
			rx_reset	<= 0;
		end
	end

	for(genvar g=0; g <= 2; g++) begin : lanes

		//TODO: make the apb do something
		APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) serdes_apb();
		assign serdes_apb.pclk = clk_156m25;
		assign serdes_apb.preset_n = 1'b0;

		wire[39:0]	rx_data;
		wire[39:0]	tx_data;
		wire		rx_comma_is_aligned;
		wire[15:0]	rx_char_is_k;
		wire[15:0]	rx_char_is_comma;
		wire[15:0]	rx_symbol_err;
		wire[15:0]	rx_disparity_err;
		wire[15:0]	tx_char_is_k;

		wire		rxoutclk;
		wire		txoutclk;
		wire		rx_commadet_slip;

		GTYLane_UltraScale #(
			.ROUGH_RATE_GBPS(10),
			.DATA_WIDTH(40),
			.RX_COMMA_ALIGN(1),
			.RX_COMMA_ANY_LANE(1),	//needed for QSGMII because we can have commas in all four lanes
			.RX_BUF_BYPASS(0)
		) lane (
			.apb(serdes_apb),

			.rx_p(rx_p[g]),
			.rx_n(rx_n[g]),

			.tx_p(tx_p[g]),
			.tx_n(tx_n[g]),

			.rx_reset(tx_reset),
			.tx_reset(rx_reset),

			.tx_data(tx_data),
			.rx_data(rx_data),

			.clk_ref_north(2'b0),
			.clk_ref_south({1'b0, refclk}),
			.clk_ref(2'b00),
			.clk_lockdet(clk_156m25),

			.rxoutclk(rxoutclk),
			.rxusrclk(rxoutclk),
			.rxusrclk2(rxoutclk),
			.rxuserrdy(1'b1),

			.txoutclk(txoutclk),
			.txusrclk(txoutclk),
			.txusrclk2(txoutclk),
			.txuserrdy(1'b1),

			.rxpllclksel(2'b11),			//QPLL0 hard coded for now
			.txpllclksel(2'b11),

			.qpll_clk(qpll_clkout),
			.qpll_refclk(qpll_refout),
			.qpll_lock(qpll_lock),

			.cpll_pd(1'b1),					//Not using CPLL for now
			.cpll_fblost(),
			.cpll_reflost(),
			.cpll_lock(),
			.cpll_refclk_sel(3'd1),			//set to 1 when only using one clock source even if it's not GTREFCLK0??

			.tx_rate(3'b011),				//divide by 4 (5 Gbps)
			.rx_rate(3'b011),

			.rx_ctle_en(1'b1),

			.txdiffctrl(5'h10),
			.txpostcursor(5'h0),
			.txprecursor(5'h6),
			.tx_invert(tx_invert[g]),
			.rx_invert(rx_invert[g]),

			.rxprbssel(4'b0),
			.txprbssel(4'b0),

			.rx_8b10b_decode(1'b1),
			.rx_comma_is_aligned(rx_comma_is_aligned),
			.rx_char_is_k(rx_char_is_k),
			.rx_char_is_comma(rx_char_is_comma),
			.rx_symbol_err(rx_symbol_err),
			.rx_commadet_slip(rx_commadet_slip),
			.rx_disparity_err(rx_disparity_err),

			.tx_8b10b_encode(1'b1),
			.tx_char_is_k(tx_char_is_k)
		);

		wire[3:0] link_up;
		lspeed_t[3:0] link_speed;

		EthernetRxBus[3:0] mac_rx_bus;

		QSGMIIMACWrapper macs(
			.rx_clk(rxoutclk),
			.rx_data_valid(1'b1),
			.rx_data_is_ctl(rx_char_is_k[3:0]),
			.rx_data(rx_data[31:0]),
			.rx_disparity_err(rx_disparity_err[3:0]),
			.rx_symbol_err(rx_symbol_err[3:0]),

			.tx_clk(txoutclk),
			.tx_data_is_ctl(tx_char_is_k),
			.tx_data(tx_data[31:0]),
			.tx_force_disparity_negative(),	//TODO

			.mac_rx_bus(mac_rx_bus),
			.link_up(link_up),
			.link_speed(link_speed),

			.mac_tx_bus(),
			.mac_tx_ready()
		);

		/*
		//Debug ILA
		ila_2 ila(
			.clk(rxoutclk),
			.probe0(rx_data[31:0]),
			.probe1(rx_comma_is_aligned),
			.probe2(rx_char_is_k),
			.probe3(rx_char_is_comma),
			.probe4(macs.sgmii_rx_data_valid),
			.probe5(macs.sgmii_rx_data_is_ctl[0]),
			.probe6(macs.sgmii_rx_data[7:0]),
			.probe7(rx_symbol_err),
			.probe8(rx_disparity_err),

			.probe9(rx_commadet_slip),
			.probe10(macs.sgmii_rx_data_is_ctl[3]),
			.probe11(macs.sgmii_rx_data[31:24])
		);

		ila_3 ila3(
			.clk(txoutclk),
			.probe0(mac_rx_bus)
		);


		vio_0 vio(
			.clk(txoutclk),
			.probe_in0(link_up),
			.probe_in1(link_speed),

			.probe_out0(tx_invert[g]),
			.probe_out1(rx_invert[g])
		);
		*/

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Debug VIO

endmodule
