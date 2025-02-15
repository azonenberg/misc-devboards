`timescale 1ns / 1ps
`default_nettype none

module top(
	input wire			clk_25mhz,

	output wire[3:0]	led,

	input wire			gtp_refclk_p,
	input wire			gtp_refclk_n,

	input wire			gtp_rx_p,
	input wire			gtp_rx_n,

	output wire			gtp_tx_p,
	output wire			gtp_tx_n
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTP using the wizard

	wire	gtp_tx_mmcm_lock;
	wire	gtp_rx_mmcm_lock;
	wire	gtp_tx_reset_done;
	wire	gtp_rx_reset_done;

	wire	gtp_txusrclk;
	wire	gtp_txusrclk2;

	wire	gtp_rxusrclk;
	wire	gtp_rxusrclk2;

	wire[31:0]	gtp_rx_data;
	wire[31:0]	gtp_rx_charisk;

	wire[31:0]	gtp_tx_data;
	wire[31:0]	gtp_tx_charisk;

	wire		gtp_rx_prbs_err;
	wire[2:0]	gtp_rx_prbssel = 0;

	wire		gtp_lane_rx_reset_done;

	wire[4:0]	gtp_tx_postcursor = 5'h0;
	wire[4:0]	gtp_tx_precursor = 5'h4;
	wire[3:0]	gtp_tx_diffctrl = 5'h8;

	wire		gtp_lane_tx_reset_done;
	wire[2:0]	gtp_tx_prbssel = 0;

	gtwizard_0  gtwizard_0_i
	(
		.soft_reset_tx_in(0),
		.soft_reset_rx_in(0),
		.dont_reset_on_data_error_in(1),
		.q0_clk0_gtrefclk_pad_n_in(gtp_refclk_n),
		.q0_clk0_gtrefclk_pad_p_in(gtp_refclk_p),
		.gt0_tx_mmcm_lock_out(gtp_tx_mmcm_lock),
		.gt0_rx_mmcm_lock_out(gtp_rx_mmcm_lock),
		.gt0_tx_fsm_reset_done_out(gtp_tx_reset_done),
		.gt0_rx_fsm_reset_done_out(gtp_rx_reset_done),
		.gt0_data_valid_in(1'b1),

		.gt0_txusrclk_out(gtp_txusrclk),
		.gt0_txusrclk2_out(gtp_txusrclk2),
		.gt0_rxusrclk_out(gtp_rxusrclk),
		.gt0_rxusrclk2_out(gtp_rxusrclk2),

		.gt0_drpaddr_in                 (9'h0),
		.gt0_drpdi_in                   (16'h0),
		.gt0_drpdo_out                  (),
		.gt0_drpen_in                   (1'b0),
		.gt0_drprdy_out                 (),
		.gt0_drpwe_in                   (1'b0),

		.gt0_eyescanreset_in            (1'b0),
		.gt0_rxuserrdy_in               (gtp_rx_mmcm_lock),

		.gt0_eyescandataerror_out       (),
		.gt0_eyescantrigger_in          (1'b0),

		.gt0_rxdata_out                 (gtp_rx_data),
		.gt0_rxcharisk_out              (gtp_rx_charisk),

		.gt0_rxprbserr_out              (gtp_rx_prbs_err),
		.gt0_rxprbssel_in               (gtp_rx_prbssel),

		.gt0_rxprbscntreset_in          (1'b0),

		.gt0_gtprxn_in                  (gtp_rx_n),
		.gt0_gtprxp_in                  (gtp_rx_p),

		.gt0_dmonitorout_out            (),

		.gt0_rxlpmhfhold_in             (1'b0),
		.gt0_rxlpmlfhold_in             (1'b0),

		.gt0_rxoutclkfabric_out         (),

		.gt0_gtrxreset_in               (1'b0),
		.gt0_rxlpmreset_in              (1'b0),

		.gt0_rxresetdone_out            (gtp_lane_rx_reset_done),

		.gt0_txpostcursor_in            (gtp_tx_postcursor),
		.gt0_txprecursor_in             (gtp_tx_precursor),

		.gt0_gttxreset_in               (1'b0),
		.gt0_txuserrdy_in               (gtp_tx_mmcm_lock),

		.gt0_txcharisk_in				(gtp_tx_charisk),
		.gt0_txdata_in                  (gtp_tx_data),

		.gt0_gtptxn_out                 (gtp_tx_n),
		.gt0_gtptxp_out                 (gtp_tx_p),
		.gt0_txdiffctrl_in              (gtp_tx_diffctrl),

		.gt0_txoutclkfabric_out         (),
		.gt0_txoutclkpcs_out            (),

		.gt0_txresetdone_out            (gtp_lane_tx_reset_done),

		.gt0_txprbssel_in               (gtp_tx_prbssel),

		.gt0_pll0reset_out(),
		.gt0_pll0outclk_out(),
		.gt0_pll0outrefclk_out(),
		.gt0_pll0lock_out(),
		.gt0_pll0refclklost_out(),
		.gt0_pll1outclk_out(),
		.gt0_pll1outrefclk_out(),

		.sysclk_in(clk_25mhz)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Shift comma alignment to the correct position (we have a 32 bit bus but internal datapath is 16 bit)

	wire[3:0]	gtp_rx_charisk_aligned;
	wire[31:0]	gtp_rx_data_aligned;

	BlockAligner8b10b aligner(
		.clk(gtp_rxusrclk2),

		.kchar_in(gtp_rx_charisk),
		.data_in(gtp_rx_data),

		.kchar_out(gtp_rx_charisk_aligned),
		.data_out(gtp_rx_data_aligned)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SCCB endpoint

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_req();
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_comp();

	wire	tx_ll_link_up;
	wire	rx_ll_link_up;

	SCCB_APBBridge #(
		.SYMBOL_WIDTH(4),
		.TX_CDC_BYPASS(1'b1)
	) bridge (

		.rx_clk(gtp_rxusrclk2),
		.rx_kchar(gtp_rx_charisk_aligned),
		.rx_data(gtp_rx_data_aligned),
		.rx_data_valid(1'b1),
		.rx_ll_link_up(rx_ll_link_up),

		.tx_clk(gtp_txusrclk2),
		.tx_kchar(gtp_tx_charisk),
		.tx_data(gtp_tx_data),
		.tx_ll_link_up(tx_ll_link_up),

		.apb_req(apb_req),
		.apb_comp(apb_comp)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Root APB bridge

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(8), .USER_WIDTH(0)) rootAPB[1:0]();

	APBBridge #(
		.BASE_ADDR(32'h0000_0000),	//MSBs are not sent over SCCB so we set to zero on our side
		.BLOCK_SIZE(32'h100),
		.NUM_PORTS(2)
	) root_bridge (
		.upstream(apb_req),
		.downstream(rootAPB)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB GPIO block

	wire[31:0]	gpio_out;
	wire[31:0]	gpio_tris;

	APB_GPIO gpio(
		.apb(rootAPB[0]),

		.gpio_out(gpio_out),
		.gpio_tris(gpio_tris),
		.gpio_in(32'hc0def00d)
	);

	assign led = gpio_out[3:0];

endmodule
