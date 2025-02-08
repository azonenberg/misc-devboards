`timescale 1ns / 1ps
`default_nettype none

module APB_SerdesTest(
	input wire	refclk,

	input wire	sysclk,

	input wire	sfp_0_rx_p,
	input wire	sfp_0_rx_n,

	output wire	sfp_0_tx_p,
	output wire	sfp_0_tx_n,

	input wire	sfp_1_rx_p,
	input wire	sfp_1_rx_n,

	output wire	sfp_1_tx_p,
	output wire	sfp_1_tx_n
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// QPLL for the SFP28 interfaces

	//TODO: make the apb do something
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) qpll_apb();
	assign qpll_apb.pclk = sysclk;
	assign qpll_apb.preset_n = 1'b0;

	wire[1:0]	qpll_clkout;
	wire[1:0]	qpll_refout;
	wire[1:0]	qpll_lock;
	wire[1:0]	fbclk_lost;
	wire[1:0]	refclk_lost;

	QuadPLL_UltraScale #(
		.QPLL0_MULT(66),	//156.25 MHz * 66 = 10.3125 GHz
							//note that output is DDR so we have to do sub-rate to get 10GbE
		.QPLL1_MULT(64)		//156.25 MHz * 64 = 10.000 GHz
	) qpll (
		.clk_lockdet(sysclk),
		.clk_ref_north(2'b0),
		.clk_ref_south(2'b0),
		.clk_ref({1'b0, refclk}),

		.apb(qpll_apb),

		.qpll_powerdown(2'b00),		//QPLL1 active, QPLL0 off

		.qpll0_refclk_sel(3'd1),	//GTREFCLK00
		.qpll1_refclk_sel(3'd1),	//GTREFCLK00

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),

		.qpll_reset(2'b0),
		.sdm_reset(1'b0),
		.sdm_toggle(1'b0),

		.fbclk_lost(fbclk_lost),
		.qpll_lock(qpll_lock),
		.refclk_lost(refclk_lost)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY tx and rx lanes for the two test interfaces

	GTY_APBBridge #(
		.TX_INVERT(0),
		.RX_INVERT(1)
	) bridge0 (
		.sysclk(sysclk),
		.clk_ref({1'b0, refclk}),

		.rx_p(sfp_0_rx_p),
		.rx_n(sfp_0_rx_n),

		.tx_p(sfp_0_tx_p),
		.tx_n(sfp_0_tx_n),

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),
		.qpll_lock(qpll_lock)
	);

	GTY_APBBridge #(
		.TX_INVERT(0),
		.RX_INVERT(1)
	) bridge1 (
		.sysclk(sysclk),
		.clk_ref({1'b0, refclk}),

		.rx_p(sfp_1_rx_p),
		.rx_n(sfp_1_rx_n),

		.tx_p(sfp_1_tx_p),
		.tx_n(sfp_1_tx_n),

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),
		.qpll_lock(qpll_lock)
	);

endmodule
