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
	// APB interfaces for everything

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_device_req();
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_device_comp();

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_host_req();
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_host_comp();

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY tx and rx lanes for the two test interfaces

	wire host_tx_clk;

	GTY_APBBridge #(
		.TX_INVERT(0),
		.RX_INVERT(1),
		.TX_ILA(1),
		.RX_ILA(0),
		.TX_CDC_BYPASS(1)
	) host_bridge (
		.sysclk(sysclk),
		.clk_ref({1'b0, refclk}),

		.rx_p(sfp_0_rx_p),
		.rx_n(sfp_0_rx_n),

		.tx_p(sfp_0_tx_p),
		.tx_n(sfp_0_tx_n),

		.rxoutclk(),
		.txoutclk(host_tx_clk),

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),
		.qpll_lock(qpll_lock),

		.apb_req(apb_host_req),
		.apb_comp(apb_host_comp)
	);

	GTY_APBBridge #(
		.TX_INVERT(0),
		.RX_INVERT(1),
		.TX_ILA(0),
		.RX_ILA(1),
		.TX_CDC_BYPASS(1)
	) device_bridge (
		.sysclk(sysclk),
		.clk_ref({1'b0, refclk}),

		.rx_p(sfp_1_rx_p),
		.rx_n(sfp_1_rx_n),

		.tx_p(sfp_1_tx_p),
		.tx_n(sfp_1_tx_n),

		.rxoutclk(),
		.txoutclk(),

		.qpll_clkout(qpll_clkout),
		.qpll_refout(qpll_refout),
		.qpll_lock(qpll_lock),

		.apb_req(apb_device_req),
		.apb_comp(apb_device_comp)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Dummy peripheral for testing stuff

	APB_DummyPeripheral dummy(.apb(apb_device_req));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// VIO for sending traffic

	assign apb_host_comp.pclk 		= host_tx_clk;
	assign apb_host_comp.preset_n	= 1;

	wire	apb_req_en;

	vio_0 vio(
		.clk(host_tx_clk),
		.probe_out0(apb_host_comp.paddr),
		.probe_out1(apb_host_comp.pwdata),
		.probe_out2(apb_host_comp.pwrite),
		.probe_out3(apb_req_en),
		.probe_in0(apb_host_comp.prdata)
	);

	initial begin
		apb_host_comp.penable	= 0;
		apb_host_comp.psel		= 0;
	end

	logic	apb_req_en_ff	= 0;
	always_ff @(posedge host_tx_clk) begin
		apb_req_en_ff	<= apb_req_en;

		if(apb_req_en && !apb_req_en_ff)
			apb_host_comp.psel		<= 1;
		if(apb_host_comp.psel)
			apb_host_comp.penable	<= 1;

		if(apb_host_comp.pready) begin
			apb_host_comp.psel		<= 0;
			apb_host_comp.penable	<= 0;
		end

	end

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Dummy APB peripheral

module APB_DummyPeripheral(
	APB.completer 		apb
);
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Register logic

	logic[31:0] foo = 0;

	//Combinatorial readback and writes
	always_comb begin

		apb.pready		= apb.psel && apb.penable;
		apb.prdata		= 0;
		apb.pslverr		= 0;
		apb.prdata		= 0;

		if(apb.pready && !apb.pwrite)
			apb.prdata		= foo;

	end

	always_ff @(posedge apb.pclk) begin
		if(apb.pwrite && apb.pready)
			foo	<= apb.pwdata;
	end

endmodule


