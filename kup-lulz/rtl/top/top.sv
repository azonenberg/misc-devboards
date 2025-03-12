`timescale 1ns / 1ps
`default_nettype none

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

	//SMPM GTY ports
	/*
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
	output wire			smpm_2_tx_n,*/


	//SFP28 GTY ports and control signals
	/*
	input wire			sfp_0_rx_p,
	input wire			sfp_0_rx_n,

	output wire			sfp_0_tx_p,
	output wire			sfp_0_tx_n,
	*/
	input wire			sfp_1_rx_p,
	input wire			sfp_1_rx_n,

	output wire			sfp_1_tx_p,
	output wire			sfp_1_tx_n,

	output wire[1:0]	sfp0_rs,
	output wire			sfp0_tx_disable
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Tie off SFP control signals

	assign sfp0_tx_disable = 0;
	assign sfp0_rs = 2'b11;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// System clock input

	wire	clk_156m25_raw;
	IBUFDS ibuf(
		.I(clk_156m25_p),
		.IB(clk_156m25_n),
		.O(clk_156m25_raw)
		);

	wire	clk_156m25;
	BUFG bufg(
		.I(clk_156m25_raw),
		.O(clk_156m25));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SERDES reference clock input

	wire	refclk;
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
	// Quad PLL

	/**
		Use QPLL0 for better performance at 25G
		At lower speeds, anything works
	 */

	//use GTSOUTHREFCLK0 (mux sel 5) because quad 224 refclk comes from quad 225 REFCLK0
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
	) qpll (
		.clk_lockdet(clk_156m25),
		.clk_ref_north(2'b0),
		.clk_ref_south({1'b0, refclk}),
		.clk_ref(2'b0),

		.apb(qpll_apb),

		.qpll_powerdown(2'b00),		//using QPLL1 for everything

		.qpll0_refclk_sel(3'd5),	//GTSOUTHREFCLK00
		.qpll1_refclk_sel(3'd5),	//GTSOUTHREFCLK00

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
	// GTY APB bridge on SFP+ 1 going to Artix board

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_req();
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_comp();

	//For initial testing, ignore the requester since the Artix board doesn't send anything ot us
	wire	artix_tx_clk;

	GTY_APBBridge #(
		.TX_INVERT(0),
		.RX_INVERT(0),
		.TX_ILA(1),
		.RX_ILA(1)
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

	//TODO: tie APB requester interface to something interesting

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
