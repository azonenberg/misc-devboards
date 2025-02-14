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
*/
	input wire			smpm_2_rx_p,
	input wire			smpm_2_rx_n,

	output wire			smpm_2_tx_p,
	output wire			smpm_2_tx_n,


	//SFP28 GTY ports and control signals
	/*
	input wire			sfp_0_rx_p,
	input wire			sfp_0_rx_n,

	output wire			sfp_0_tx_p,
	output wire			sfp_0_tx_n,

	input wire			sfp_1_rx_p,
	input wire			sfp_1_rx_n,

	output wire			sfp_1_tx_p,
	output wire			sfp_1_tx_n,
*/
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
	// VIO for SERDES config

	wire[4:0] tx_diffctrl = 8;
	wire[4:0] tx_postcursor = 4;
	wire[4:0] tx_precursor = 0;

	wire[24:0]	sdm_data0 = 0;
	wire[24:0]	sdm_data1 = 0;

	wire		gty_force_reset = 0;
	wire[2:0]	tx_rate = 3;
	wire[2:0]	rx_rate = 3;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY block on SMPM 0 going to scope
/*
	//TODO: make the apb do something
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) lane0_apb();
	assign lane0_apb.pclk = clk_156m25;
	assign lane0_apb.preset_n = 1'b0;

	wire	rxoutclk;
	wire	txoutclk;

	GTYLane_UltraScale #(

		.CPLL_FBDIV(4),			//Combined CPLL feedback divider is 16
		.CPLL_FBDIV_45(4)		//This gives 156.25 * 16 = 2500 MHz, times 2 for DDR is 5 Gbps line rate

	) lane0 (
		.apb(lane0_apb),

		.rx_p(smpm_0_rx_p),
		.rx_n(smpm_0_rx_n),

		.tx_p(smpm_0_tx_p),
		.tx_n(smpm_0_tx_n),

		.rx_reset(gty_force_reset),
		.tx_reset(gty_force_reset),

		.tx_data(32'h0),
		.rx_data(),

		.clk_ref_north(2'b0),
		.clk_ref_south({1'b0, refclk}),
		.clk_ref(2'b0),
		.clk_lockdet(clk_156m25),

		.rxoutclk(rxoutclk),
		.rxusrclk(rxoutclk),
		.rxusrclk2(rxoutclk),
		.rxuserrdy(1'b1),

		.txoutclk(txoutclk),
		.txusrclk(txoutclk),
		.txusrclk2(txoutclk),
		.txuserrdy(1'b1),

		.rxpllclksel(2'b10),		//QPLL1
		.txpllclksel(2'b10),		//QPLL1

		.qpll_clk(qpll_clkout),
		.qpll_refclk(qpll_refout),
		.qpll_lock(qpll_lock),

		.cpll_pd(1'b1),					//Don't use CPLL for now it seems to be buggy if you're not using the wizard
		.cpll_fblost(),
		.cpll_reflost(),
		.cpll_lock(),
		.cpll_refclk_sel(3'd1),	//set to 1 when only using one clock source even if it's not GTREFCLK0??

		.tx_rate(tx_rate),
		.rx_rate(rx_rate),

		.rx_ctle_en(1'b1),

		.txdiffctrl(tx_diffctrl),
		.txpostcursor(tx_postcursor),
		.txprecursor(tx_precursor),
		.tx_invert(1'b0),
		.rx_invert(1'b0),

		.rxprbssel(4'b0101),	//PRBS-31
		.txprbssel(4'b0101)
	);
*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Second clone GTY block on SMPM 1 going to BERT
/*
	//TODO: make the apb do something
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) lane1_apb();
	assign lane1_apb.pclk = clk_156m25;
	assign lane1_apb.preset_n = 1'b0;

	wire	lane1_txoutclk;
	wire	lane1_rxoutclk;

	wire		rxprbserr;
	wire		rxprbslocked;
	wire[31:0]	rx_data;

	GTYLane_UltraScale #(

		.CPLL_FBDIV(4),			//Combined CPLL feedback divider is 16
		.CPLL_FBDIV_45(4)		//This gives 156.25 * 16 = 2500 MHz, times 2 for DDR is 5 Gbps line rate

	) lane1 (
		.apb(lane1_apb),

		.rx_p(smpm_1_rx_p),
		.rx_n(smpm_1_rx_n),

		.tx_p(smpm_1_tx_p),
		.tx_n(smpm_1_tx_n),

		.rx_reset(gty_force_reset),
		.tx_reset(gty_force_reset),

		.tx_data(32'h0),
		.rx_data(rx_data),

		.clk_ref_north(2'b0),
		.clk_ref_south({1'b0, refclk}),
		.clk_ref(2'b0),
		.clk_lockdet(clk_156m25),

		.rxoutclk(lane1_rxoutclk),
		.rxusrclk(lane1_rxoutclk),
		.rxusrclk2(lane1_rxoutclk),
		.rxuserrdy(1'b1),

		.txoutclk(lane1_txoutclk),
		.txusrclk(lane1_txoutclk),
		.txusrclk2(lane1_txoutclk),
		.txuserrdy(1'b1),

		.rxpllclksel(2'b10),		//QPLL1
		.txpllclksel(2'b10),		//QPLL1

		.qpll_clk(qpll_clkout),
		.qpll_refclk(qpll_refout),
		.qpll_lock(qpll_lock),

		.cpll_pd(1'b1),					//Don't use CPLL for now it seems to be buggy if you're not using the wizard
		.cpll_fblost(),
		.cpll_reflost(),
		.cpll_lock(),
		.cpll_refclk_sel(3'd1),		//set to 1 when only using one clock source even if it's not GTREFCLK0??

		.tx_rate(tx_rate),
		.rx_rate(rx_rate),

		.rx_ctle_en(1'b0),

		.txdiffctrl(tx_diffctrl),
		.txpostcursor(tx_postcursor),
		.txprecursor(tx_precursor),
		.tx_invert(1'b0),
		.rx_invert(1'b0),

		.rxprbssel(4'b0101),	//PRBS-31
		.txprbssel(4'b0101),
		.rxprbserr(rxprbserr),
		.rxprbslocked(rxprbslocked)
	);
*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY block on SMPM 2 going to Artix board

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

		.rx_p(smpm_2_rx_p),
		.rx_n(smpm_2_rx_n),

		.tx_p(smpm_2_tx_p),
		.tx_n(smpm_2_tx_n),

		.rxoutclk(),
		.txoutclk(artix_tx_clk),

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),
		.qpll_lock(qpll_lock),

		.apb_req(apb_req),
		.apb_comp(apb_comp)
	);

	assign apb_comp.pclk 		= artix_tx_clk;
	assign apb_comp.preset_n	= 1;

	wire	apb_req_en;

	vio_0 vio(
		.clk(artix_tx_clk),
		.probe_out0(apb_comp.paddr),
		.probe_out1(apb_comp.pwdata),
		.probe_out2(apb_comp.pwrite),
		.probe_out3(apb_req_en),
		.probe_in0(apb_comp.prdata)
	);

	initial begin
		apb_comp.penable	= 0;
		apb_comp.psel		= 0;
	end

	logic	apb_req_en_ff	= 0;
	always_ff @(posedge artix_tx_clk) begin
		apb_req_en_ff	<= apb_req_en;

		if(apb_req_en && !apb_req_en_ff)
			apb_comp.psel		<= 1;
		if(apb_comp.psel)
			apb_comp.penable	<= 1;

		if(apb_comp.pready) begin
			apb_comp.psel		<= 0;
			apb_comp.penable	<= 0;
		end

	end

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

/*
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SFP28 ports

	APB_SerdesTest test(
		.refclk(refclk),

		.sysclk(clk_156m25),

		.sfp_0_rx_p(sfp_0_rx_p),
		.sfp_0_rx_n(sfp_0_rx_n),

		.sfp_0_tx_p(sfp_0_tx_p),
		.sfp_0_tx_n(sfp_0_tx_n),

		.sfp_1_rx_p(sfp_1_rx_p),
		.sfp_1_rx_n(sfp_1_rx_n),

		.sfp_1_tx_p(sfp_1_tx_p),
		.sfp_1_tx_n(sfp_1_tx_n)
	);
	*/

endmodule
