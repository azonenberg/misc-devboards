`default_nettype none
`timescale 1ns/1ps

module SCCB_Sim();

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clock generation (same clock domain for TX and RX for now)

	logic clk_host = 0;
	logic clk_dev = 0;

	always begin
		#1;
		clk_host = 1;
		clk_dev = 1;
		#1;
		clk_host = 0;
		clk_dev = 0;
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Host side

	wire[31:0]	host_tx_data;
	wire[3:0]	host_tx_kchar;

	wire[31:0]	dev_tx_data;
	wire[3:0]	dev_tx_kchar;

	//The APB bus
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_req_unused();

	//APB interface for reverse direction, not used
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_comp();

	wire	host_tx_ll_link_up;

	SCCB_APBBridge #(
		.TX_CDC_BYPASS(1)	//using our own clock as the transmit data source already
	) host_bridge (
		.rx_clk(clk_dev),
		.rx_kchar(dev_tx_kchar),
		.rx_data(dev_tx_data),
		.rx_data_valid(1'b1),

		.tx_clk(clk_host),
		.tx_kchar(host_tx_kchar),
		.tx_data(host_tx_data),
		.tx_ll_link_up(host_tx_ll_link_up),

		.apb_req(apb_req_unused),
		.apb_comp(apb_comp)
	);

	//Tie off unused APB signals
	assign apb_comp.pprot 		= 0;
	assign apb_comp.pwakeup 	= 0;
	assign apb_comp.pauser		= 0;
	assign apb_comp.pwuser		= 0;

	//Hook up clock
	assign apb_comp.pclk 		= clk_host;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Device side

	//The APB bus
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_req();

	//APB interface for reverse direction, not used
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_comp_unused();

	wire	device_tx_ll_link_up;

	SCCB_APBBridge #(
		.TX_CDC_BYPASS(1)	//not using requester port so bypass the CDC there
	) device_bridge (
		.rx_clk(clk_host),
		.rx_kchar(host_tx_kchar),
		.rx_data(host_tx_data),
		.rx_data_valid(1'b1),

		.tx_clk(clk_dev),
		.tx_kchar(dev_tx_kchar),
		.tx_data(dev_tx_data),
		.tx_ll_link_up(device_tx_ll_link_up),

		.apb_req(apb_req),
		.apb_comp(apb_comp_unused)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Dummy APB peripheral

	APB_Dummy dummy(.apb(apb_req));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Host-side control logic

	logic[7:0] host_state = 0;

	initial begin
		apb_comp.preset_n	= 0;
		apb_comp.pwdata		= 0;
		apb_comp.pstrb		= 0;
		apb_comp.pwrite		= 0;
		apb_comp.paddr		= 0;
		apb_comp.penable	= 0;
		apb_comp.psel		= 0;
	end

	always_ff @(posedge clk_host) begin

		apb_comp.preset_n	<= 1;

		case(host_state)

			//Wait for link to come up then start sending a frame
			//Write of 0xdeadbeef to 0xbaadc0de
			0: begin
				if(host_tx_ll_link_up) begin
					apb_comp.psel		<= 1;
					apb_comp.pwrite		<= 1;
					apb_comp.pwdata		<= 32'hdeadbeef;
					apb_comp.paddr		<= 32'hbaadc0de;
					apb_comp.pstrb		<= 4'b1111;
					host_state			<= 1;
				end
			end

			1: begin
				apb_comp.penable		<= 1;
				host_state				<= 2;
			end

			2: begin
				if(apb_comp.pready) begin
					apb_comp.penable	<= 0;
					apb_comp.psel		<= 0;
					host_state			<= 3;
				end
			end

			//Do a second write of different values to see why things are getting stuck
			3: begin
				apb_comp.psel		<= 1;
				apb_comp.pwrite		<= 1;
				apb_comp.pwdata		<= 32'hfeedface;
				apb_comp.paddr		<= 32'hcafebabe;
				apb_comp.pstrb		<= 4'b1111;
				host_state			<= 4;
			end

			4: begin
				apb_comp.penable		<= 1;
				host_state				<= 5;
			end

			5: begin
				if(apb_comp.pready) begin
					apb_comp.penable	<= 0;
					apb_comp.psel		<= 0;
					host_state			<= 6;
				end
			end

			//Do a read
			6: begin
				apb_comp.psel		<= 1;
				apb_comp.pwrite		<= 0;
				apb_comp.paddr		<= 32'hcafebabe;
				apb_comp.pstrb		<= 0;
				host_state			<= 7;
			end

			7: begin
				apb_comp.penable		<= 1;
				host_state				<= 8;
			end

			8: begin
				if(apb_comp.pready) begin
					apb_comp.penable	<= 0;
					apb_comp.psel		<= 0;
					host_state			<= 9;
				end
			end

		endcase

	end

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Dummy APB peripheral

module APB_Dummy(
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

