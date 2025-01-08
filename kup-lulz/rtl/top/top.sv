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
	// Echo clock output

	wire	clk_echo;

	ODDRE1 #
	(
		.SRVAL(0),
		.IS_C_INVERTED(0),
		.IS_D1_INVERTED(0),
		.IS_D2_INVERTED(0),
		.SIM_DEVICE("ULTRASCALE_PLUS")
	) ddr_obuf
	(
		.C(clk_156m25),
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

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TODO VIO

	wire[3:0] tx_prbssel;
	wire[4:0] tx_diffctrl;
	wire[4:0] tx_postcursor;
	wire[4:0] tx_precursor;

	vio_0 vio(
		.clk(clk_156m25),
		.probe_out0(tx_prbssel),
		.probe_out1(tx_diffctrl),
		.probe_out2(tx_postcursor),
		.probe_out3(tx_precursor)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY block

	wire	txsrcclk;
	wire	txusrclk;
	wire	txusrclk2;
	wire	rxsrcclk;
	wire	rxusrclk;
	wire	rxusrclk2;

	wire	refclk;
	IBUFDS_GTE4 refclk_ibuf(
		.I(refclk_p),
		.IB(refclk_n),
		.O(refclk)
	);

	gtwizard_ultrascale_0 gty (
		.gtwiz_userclk_tx_reset_in(1'b0),
		.gtwiz_userclk_tx_srcclk_out(txsrcclk),
		.gtwiz_userclk_tx_usrclk_out(txusrclk),
		.gtwiz_userclk_tx_usrclk2_out(txusrclk2),
		.gtwiz_userclk_tx_active_out(),
		.gtwiz_userclk_rx_reset_in(1'b0),
		.gtwiz_userclk_rx_srcclk_out(rxsrcclk),
		.gtwiz_userclk_rx_usrclk_out(rxusrclk),
		.gtwiz_userclk_rx_usrclk2_out(rxusrclk2),
		.gtwiz_userclk_rx_active_out(),
		.gtwiz_reset_clk_freerun_in(clk_156m25),
		.gtwiz_reset_all_in(1'b0),
		.gtwiz_reset_tx_pll_and_datapath_in(1'b0),
		.gtwiz_reset_tx_datapath_in(1'b0),
		.gtwiz_reset_rx_pll_and_datapath_in(1'b0),
		.gtwiz_reset_rx_datapath_in(1'b0),
		.gtwiz_reset_rx_cdr_stable_out(),
		.gtwiz_reset_tx_done_out(),
		.gtwiz_reset_rx_done_out(),
		.gtwiz_userdata_tx_in(32'h55555555),
		.gtwiz_userdata_rx_out(),
		.gtrefclk00_in(refclk),
		.qpll0outclk_out(),
		.qpll0outrefclk_out(),
		.gtyrxn_in(smpm_0_rx_n),
		.gtyrxp_in(smpm_0_rx_p),
		.txdiffctrl_in(tx_diffctrl),
		.txpostcursor_in(tx_postcursor),
		.txprbssel_in(tx_prbssel),
		.txprecursor_in(tx_precursor),
		.gtpowergood_out(),
		.gtytxn_out(smpm_0_tx_n),
		.gtytxp_out(smpm_0_tx_p),
		.rxpmaresetdone_out(),
		.txpmaresetdone_out()
		);

endmodule
