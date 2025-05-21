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
	@brief Stuff related to the GTY quad (227) running the QSFP28 interface to the second PHY (only 3 of 4 used)
 */
module QSFP0_Quad(

	//System clock input
	input wire				clk_156m25,

	//SERDES reference clock
	input wire				refclk,

	//The actual SERDES interfaces
	/*
	input wire			qsfp0_lane0_rx_p,
	input wire			qsfp0_lane0_rx_n,

	output wire			qsfp0_lane0_tx_p,
	output wire			qsfp0_lane0_tx_n,
	*/

	input wire			qsfp0_lane1_rx_p,
	input wire			qsfp0_lane1_rx_n,

	output wire			qsfp0_lane1_tx_p,
	output wire			qsfp0_lane1_tx_n,

	input wire			qsfp0_lane2_rx_p,
	input wire			qsfp0_lane2_rx_n,

	output wire			qsfp0_lane2_tx_p,
	output wire			qsfp0_lane2_tx_n,

	input wire			qsfp0_lane3_rx_p,
	input wire			qsfp0_lane3_rx_n,

	output wire			qsfp0_lane3_tx_p,
	output wire			qsfp0_lane3_tx_n,

	//APB management bus for QPLL
	APB.completer			apb_qpll,
	APB.completer			apb_serdes_lane[3:0],

	//Link state
	wire[11:0]				link_up,

	//AXI streams for the individual port data streams (clk_fabric domain for TX, port clock for RX)
	AXIStream.transmitter	axi_rx[11:0],
	AXIStream.receiver		axi_tx[11:0]
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

	QuadPLL_UltraScale #(
		.QPLL0_MULT(66),	//156.25 MHz * 66 = 10.3125 GHz
							//note that output is DDR so we have to do sub-rate to get 10GbE
		.QPLL1_MULT(64)		//156.25 MHz * 64 = 10.000 GHz
	) qpll_227 (
		.clk_lockdet(clk_156m25),
		.clk_ref_north(2'b0),
		.clk_ref_south(2'b0),
		.clk_ref({1'b0, refclk}),

		.apb(apb_qpll),

		.qpll_powerdown(2'b01),		//using QPLL1 for everything so shut down QPLL0

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
	// The actual SERDES interfaces

	wire[3:0]	rx_p = {qsfp0_lane3_rx_p, qsfp0_lane2_rx_p, qsfp0_lane1_rx_p, 1'b0};
	wire[3:0]	rx_n = {qsfp0_lane3_rx_n, qsfp0_lane2_rx_n, qsfp0_lane1_rx_n, 1'b0};

	wire[3:0]	tx_p;
	wire[3:0]	tx_n;
	assign qsfp0_lane3_tx_p = tx_p[3];
	assign qsfp0_lane3_tx_n = tx_n[3];
	assign qsfp0_lane2_tx_p = tx_p[2];
	assign qsfp0_lane2_tx_n = tx_n[2];
	assign qsfp0_lane1_tx_p = tx_p[1];
	assign qsfp0_lane1_tx_n = tx_n[1];

	/*
		Inversions: RX2, TX[2:0] on the line card
		no swaps on qsfp-to-arc6
		all TX swapped on kup-lulz
		rx3/1 swapped on kup-lulz

		so in net: tx are swapped at both sides, this cancels out
		rx2 swapped on line card which maps to fpga 1, which is also swapped, this cancels
		fpga also has swaps on rx3 which is arc6 0 so that has to get swapped
	*/
	wire[3:0]	tx_invert = 4'b0000;
	wire[3:0]	rx_invert = 4'b0101;

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

	//SERDES data buses
	wire[39:0]	rx_data[3:0];
	wire[39:0]	tx_data[3:0];
	wire		rx_comma_is_aligned[3:0];
	wire[15:0]	rx_char_is_k[3:0];
	wire[15:0]	rx_char_is_comma[3:0];
	wire[15:0]	rx_symbol_err[3:0];
	wire[15:0]	rx_disparity_err[3:0];
	wire[15:0]	tx_char_is_k[3:0];

	wire		rxoutclk[3:0];
	wire		txoutclk[3:0];
	wire		rx_commadet_slip[3:0];

	for(genvar g=1; g <= 3; g++) begin : serdes

		GTYLane_UltraScale #(
			.ROUGH_RATE_GBPS(5),
			.DATA_WIDTH(40),
			.RX_COMMA_ALIGN(1),
			.RX_COMMA_ANY_LANE(1),	//needed for QSGMII because we can have commas in all four lanes
			.RX_BUF_BYPASS(1)
		) lane (
			.apb(apb_serdes_lane[g]),

			.rx_p(rx_p[g]),
			.rx_n(rx_n[g]),

			.tx_p(tx_p[g]),
			.tx_n(tx_n[g]),

			.rx_reset(tx_reset),
			.tx_reset(rx_reset),

			.tx_data(tx_data[g]),
			.rx_data(rx_data[g]),

			.clk_ref_north(2'b0),
			.clk_ref_south(2'b00),
			.clk_ref({1'b0, refclk}),
			.clk_lockdet(clk_156m25),

			.rxoutclk(rxoutclk[g]),
			.rxusrclk(rxoutclk[g]),
			.rxusrclk2(rxoutclk[g]),
			.rxuserrdy(1'b1),

			.txoutclk(txoutclk[g]),
			.txusrclk(txoutclk[g]),
			.txusrclk2(txoutclk[g]),
			.txuserrdy(1'b1),

			.rxpllclksel(2'b10),			//QPLL1 hard coded for now
			.txpllclksel(2'b10),

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
			.rx_comma_is_aligned(rx_comma_is_aligned[g]),
			.rx_char_is_k(rx_char_is_k[g]),
			.rx_char_is_comma(rx_char_is_comma[g]),
			.rx_symbol_err(rx_symbol_err[g]),
			.rx_commadet_slip(rx_commadet_slip[g]),
			.rx_disparity_err(rx_disparity_err[g]),

			.tx_8b10b_encode(1'b1),
			.tx_char_is_k(tx_char_is_k[g])
		);
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Shuffle things around because some TX/RX are not paired properly on kup-lulz due to routing constraints

	/**
		In the end, we want lanes 0-2 of the ARC6

		On kup-lulz
			tx side
				fpga	qsfp
				0		2
				1		0
				2		1
				3		3

			rx side
				fpga	qsfp
				0		1
				1		0
				2		3
				3		2

		On qsfp-to-arc6
			(tx/rx paired same)
				qsfp	arc6
				0		2
				1		3
				2		0
				3		1

		so final mapping
			tx
				fpga	arc6
				2		0
				3		1
				1		2
				0		3 (not used)

			rx
				fpga	arc6
				3		0
				2		1
				1		2
				0		3
	 */

	wire		shuf_rxoutclk[2:0];
	wire[39:0]	shuf_rx_data[2:0];
	wire[15:0]	shuf_rx_char_is_k[2:0];
	wire[15:0]	shuf_rx_symbol_err[2:0];
	wire[15:0]	shuf_rx_disparity_err[2:0];

	wire[15:0]	shuf_tx_char_is_k[2:0];
	wire[39:0]	shuf_tx_data[2:0];
	wire		shuf_txoutclk[2:0];

	//RX side
	assign shuf_rxoutclk[0] = rxoutclk[3];
	assign shuf_rx_data[0] = rx_data[3];
	assign shuf_rx_char_is_k[0] = rx_char_is_k[3];
	assign shuf_rx_symbol_err[0] = rx_symbol_err[3];
	assign shuf_rx_disparity_err[0] = rx_disparity_err[3];

	assign shuf_rxoutclk[1] = rxoutclk[2];
	assign shuf_rx_data[1] = rx_data[2];
	assign shuf_rx_char_is_k[1] = rx_char_is_k[2];
	assign shuf_rx_symbol_err[1] = rx_symbol_err[2];
	assign shuf_rx_disparity_err[1] = rx_disparity_err[2];

	assign shuf_rxoutclk[2] = rxoutclk[1];
	assign shuf_rx_data[2] = rx_data[1];
	assign shuf_rx_char_is_k[2] = rx_char_is_k[1];
	assign shuf_rx_symbol_err[2] = rx_symbol_err[1];
	assign shuf_rx_disparity_err[2] = rx_disparity_err[1];

	//TX side
	assign shuf_txoutclk[0] = txoutclk[2];
	assign tx_data[2] = shuf_tx_data[0];
	assign tx_char_is_k[2] = shuf_tx_char_is_k[0];

	assign shuf_txoutclk[1] = txoutclk[3];
	assign tx_data[3] = shuf_tx_data[1];
	assign tx_char_is_k[3] = shuf_tx_char_is_k[1];

	assign shuf_txoutclk[2] = txoutclk[1];
	assign tx_data[1] = shuf_tx_data[2];
	assign tx_char_is_k[1] = shuf_tx_char_is_k[2];

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MACs

	for(genvar g=0; g < 3; g++) begin : macs

		lspeed_t[3:0] link_speed;

		//MAC-side TX/RX data in SERDES clock domain
		AXIStream #(.DATA_WIDTH(32), .ID_WIDTH(0), .DEST_WIDTH(0), .USER_WIDTH(1)) mac_axi_tx[3:0]();

		AXIS_QSGMIIMACWrapper macs (
			.rx_clk(shuf_rxoutclk[g]),
			.rx_data_valid(1'b1),
			.rx_data_is_ctl(shuf_rx_char_is_k[g][3:0]),
			.rx_data(shuf_rx_data[g][31:0]),
			.rx_disparity_err(shuf_rx_disparity_err[g][3:0]),
			.rx_symbol_err(shuf_rx_symbol_err[g][3:0]),

			.tx_clk(shuf_txoutclk[g]),
			.tx_data_is_ctl(shuf_tx_char_is_k[g]),
			.tx_data(shuf_tx_data[g][31:0]),
			.tx_force_disparity_negative(),	//TODO

			.link_up(link_up[g*4 +: 4]),
			.link_speed(link_speed),

			.axi_rx(axi_rx[g*4 +: 4]),
			.axi_tx(mac_axi_tx)
		);

		for(genvar h=0; h<4; h++) begin : cdc_fifos
			AXIS_CDC #(.FIFO_DEPTH(512)) tx_fifo (.axi_rx(axi_tx[g*4 + h]), .tx_clk(shuf_txoutclk[g]), .axi_tx(mac_axi_tx[h]));
		end

	end

endmodule
