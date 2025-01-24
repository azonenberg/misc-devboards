`timescale 1ns / 1ps
`default_nettype none

module top(
	output wire	gpio_p,
	output wire	gpio_n,

	input wire	clk_156m25_p,
	input wire	clk_156m25_n,

	input wire	refclk_p,
	input wire	refclk_n,

	input wire	smpm_0_rx_p,
	input wire	smpm_0_rx_n,

	output wire	smpm_0_tx_p,
	output wire	smpm_0_tx_n
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY reference clock input

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

	wire[1:0]	qpll_reset;
	wire[1:0]	sdm_reset;
	wire[1:0]	fbclk_lost;
	wire[1:0]	qpll_lock;
	wire[1:0]	refclk_lost;

	wire[1:0]	qpll_clkout;
	wire[1:0]	qpll_refout;
	wire[1:0]	pll_clksel;
	wire[1:0]	qpll_pd;
	wire[1:0]	sdm_toggle;

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

		.qpll_powerdown(qpll_pd),

		.qpll0_refclk_sel(3'd5),	//GTSOUTHREFCLK00
		.qpll1_refclk_sel(3'd5),	//GTSOUTHREFCLK00

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),

		.qpll_reset(qpll_reset),
		.sdm_reset(sdm_reset),
		.sdm_toggle(sdm_toggle),

		.fbclk_lost(fbclk_lost),
		.qpll_lock(qpll_lock),
		.refclk_lost(refclk_lost)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// VIO for SERDES config

	wire[3:0] tx_prbssel;
	wire[3:0] rx_prbssel;
	wire[4:0] tx_diffctrl;
	wire[4:0] tx_postcursor;
	wire[4:0] tx_precursor;

	wire[24:0]	sdm_data0;
	wire[24:0]	sdm_data1;

	wire		gty_force_reset;
	wire[2:0]	tx_rate;
	wire[2:0]	rx_rate;

	vio_0 vio(
		.clk(clk_156m25),

		.probe_in0(fbclk_lost),			//2
		.probe_in1(qpll_lock),			//2
		.probe_in2(refclk_lost),		//2

		.probe_out0(tx_prbssel),
		.probe_out1(tx_diffctrl),
		.probe_out2(tx_postcursor),
		.probe_out3(tx_precursor),

		.probe_out4(qpll_reset),		//2
		.probe_out5(sdm_reset),			//2
		.probe_out6(sdm_data0),
		.probe_out7(sdm_data1),
		.probe_out8(rx_prbssel),
		.probe_out9(rx_rate),			//3

		.probe_out10(gty_force_reset),	//1
		.probe_out11(pll_clksel),		//2
		.probe_out12(qpll_pd),			//2
		.probe_out13(tx_rate),			//3
		.probe_out14(sdm_toggle)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY block

	//TODO: make the apb do something
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) lane0_apb();
	assign lane0_apb.pclk = clk_156m25;
	assign lane0_apb.preset_n = 1'b0;

	logic	rxuserrdy = 0;
	logic	txuserrdy = 0;

	wire	rxoutclk;
	wire	txoutclk;

	logic tx_reset = 1;
	logic rx_reset = 1;
	logic[7:0] count = 1;

	//TODO: move reset logic internal
	logic[7:0] rxcount = 1;
	always_ff@(posedge rxoutclk) begin
		if(rxcount != 0)
			rxcount <= rxcount + 1;
		else
			rxuserrdy	<= 1;

		if(rx_reset) begin
			rxuserrdy	<= 0;
			rxcount		<= 1;
		end
	end

	logic[7:0] txcount = 1;
	always_ff@(posedge txoutclk) begin
		if(txcount != 0)
			txcount <= txcount + 1;
		else
			txuserrdy	<= 1;

		if(tx_reset) begin
			txuserrdy	<= 0;
			txcount		<= 1;
		end
	end

	always_ff @(posedge clk_156m25) begin
		if(count == 0) begin
			tx_reset	<= 0;
			rx_reset	<= 0;
		end
		else
			count <= count + 1;
	end

	GTYLane_UltraScale #(

		.CPLL_FBDIV(4),			//Combined CPLL feedback divider is 16
		.CPLL_FBDIV_45(4)		//This gives 156.25 * 16 = 2500 MHz, times 2 for DDR is 5 Gbps line rate

	) lane0 (
		.apb(lane0_apb),

		.rx_p(smpm_0_rx_p),
		.rx_n(smpm_0_rx_n),

		.tx_p(smpm_0_tx_p),
		.tx_n(smpm_0_tx_n),

		.rx_reset(rx_reset | gty_force_reset),
		.tx_reset(tx_reset | gty_force_reset),

		.tx_data(64'h0),
		.rx_data(),

		.clk_ref_north(2'b0),
		.clk_ref_south({1'b0, refclk}),
		.clk_ref(2'b0),
		.clk_lockdet(clk_156m25),

		.rxoutclk(rxoutclk),
		.rxusrclk(rxoutclk),
		.rxusrclk2(rxoutclk),
		.rxuserrdy(rxuserrdy),

		.txoutclk(txoutclk),
		.txusrclk(txoutclk),
		.txusrclk2(txoutclk),
		.txuserrdy(txuserrdy),

		.rxpllclksel(pll_clksel),
		.txpllclksel(pll_clksel),

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

		.rxprbssel(rx_prbssel),
		.txprbssel(tx_prbssel)
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
