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

module UltraRAMTest();

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clocking

	//internal GSR lasts 100 ns in sim and URAM isn't ungated until then
	logic ready = 0;
	initial begin
		#110;
		ready = 1;
	end

	logic clk = 0;
	always begin
		#1;
		clk = ready;
		#1;
		clk = 0;
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// DUT

	//Lower port write bus
	logic		x_porta_en		= 0;
	logic[22:0]	x_porta_addr	= 0;
	logic		x_porta_wr		= 0;
	logic[71:0]	x_porta_wdata	= 0;

	//Upper port write bus
	logic		y_porta_en		= 0;
	logic[22:0]	y_porta_addr	= 0;
	logic		y_porta_wr		= 0;
	logic[71:0]	y_porta_wdata	= 0;

	//Lower port read bus
	logic		x_portb_en		= 0;
	logic[22:0]	x_portb_addr	= 0;
	logic		x_portb_wr		= 0;
	wire[71:0]	x_portb_rdata;
	wire		x_portb_rdaccess;

	//Upper port read bus
	logic		y_portb_en		= 0;
	logic[22:0]	y_portb_addr	= 0;
	logic		y_portb_wr		= 0;
	wire[71:0]	y_portb_rdata;
	wire		y_portb_rdaccess;

	UltraRAMCascadeBus porta_x_tieoff_south();
	UltraRAMCascadeBus porta_x_tieoff_north();

	UltraRAMCascadeBus porta_y_tieoff_south();
	UltraRAMCascadeBus porta_y_tieoff_north();

	UltraRAMCascadeBus portb_tieoff_north();
	UltraRAMCascadeBus portb_tieoff_south();
	UltraRAMCascadeBus portb_cascade();

	UltraRAMWrapper #(
		.CASCADE_ORDER_A("NONE"),
		.CASCADE_ORDER_B("FIRST"),
		.SELF_ADDR_A(11'h000),
		.SELF_ADDR_B(11'h000),
		.SELF_MASK_A(11'h7ff),
		.SELF_MASK_B(11'h7fe)
	) block0 (
		.clk(clk),
		.sleep(1'b0),

		.a_en(x_porta_en),
		.a_addr(x_porta_addr),
		.a_wr(x_porta_wr),
		.a_bwe(9'h1ff),
		.a_wdata(x_porta_wdata),
		.a_inject_seu(1'b0),
		.a_inject_deu(1'b0),
		.a_core_ce(1'b1),
		.a_ecc_ce(1'b1),
		.a_rst(1'b0),
		.a_rdata(),
		.a_rdaccess(),
		.a_seu(),
		.a_deu(),

		.b_en(x_portb_en),
		.b_addr(x_portb_addr),
		.b_wr(x_portb_wr),
		.b_bwe(9'h0),
		.b_wdata(72'h0),
		.b_inject_seu(1'b0),
		.b_inject_deu(1'b0),
		.b_core_ce(1'b1),
		.b_ecc_ce(1'b1),
		.b_rst(1'b0),
		.b_rdata(x_portb_rdata),
		.b_rdaccess(x_portb_rdaccess),
		.b_seu(),
		.b_deu(),

		.a_cascade_south(porta_x_tieoff_south),
		.a_cascade_north(porta_x_tieoff_north),
		.b_cascade_south(portb_tieoff_south),
		.b_cascade_north(portb_cascade)
	);

	UltraRAMWrapper #(
		.CASCADE_ORDER_A("NONE"),
		.CASCADE_ORDER_B("LAST"),
		.SELF_ADDR_A(11'h000),
		.SELF_ADDR_B(11'h001),
		.SELF_MASK_A(11'h7ff),
		.SELF_MASK_B(11'h7fe)
	) block1 (
		.clk(clk),
		.sleep(1'b0),

		.a_en(y_porta_en),
		.a_addr(y_porta_addr),
		.a_wr(y_porta_wr),
		.a_bwe(9'h1ff),
		.a_wdata(y_porta_wdata),
		.a_inject_seu(1'b0),
		.a_inject_deu(1'b0),
		.a_core_ce(1'b1),
		.a_ecc_ce(1'b1),
		.a_rst(1'b0),
		.a_rdata(),
		.a_rdaccess(),
		.a_seu(),
		.a_deu(),

		.b_en(y_portb_en),
		.b_addr(y_portb_addr),
		.b_wr(y_portb_wr),
		.b_bwe(9'h0),
		.b_wdata(72'h0),
		.b_inject_seu(1'b0),
		.b_inject_deu(1'b0),
		.b_core_ce(1'b1),
		.b_ecc_ce(1'b1),
		.b_rst(1'b0),
		.b_rdata(y_portb_rdata),
		.b_rdaccess(y_portb_rdaccess),
		.b_seu(),
		.b_deu(),

		.a_cascade_south(porta_y_tieoff_south),
		.a_cascade_north(porta_y_tieoff_north),
		.b_cascade_south(portb_cascade),
		.b_cascade_north(portb_tieoff_north)
	);

	UltraRAMCascadeTieoff tieoff_north_a_x(.tieoff(porta_x_tieoff_north));
	UltraRAMCascadeTieoff tieoff_south_a_x(.tieoff(porta_x_tieoff_south));
	UltraRAMCascadeTieoff tieoff_north_a_y(.tieoff(porta_y_tieoff_north));
	UltraRAMCascadeTieoff tieoff_south_a_y(.tieoff(porta_y_tieoff_south));

	UltraRAMCascadeTieoff tieoff_south_b(.tieoff(portb_tieoff_south));
	UltraRAMCascadeTieoff tieoff_north_b(.tieoff(portb_tieoff_north));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Test state machine

	logic[7:0] count = 0;
	always_ff @(posedge clk) begin

		x_porta_en		<= 0;
		x_porta_wr		<= 0;
		x_porta_wdata	<= 0;

		y_porta_en		<= 0;
		y_porta_wr		<= 0;
		y_porta_wdata	<= 0;

		x_portb_en		<= 0;
		x_portb_addr	<= 0;
		x_portb_wr		<= 0;

		y_portb_en		<= 0;
        y_portb_addr	<= 0;
		y_portb_wr		<= 0;

		case(count)

			//dual write
			0: begin
				x_porta_en		<= 1;
				x_porta_wr		<= 1;
				x_porta_addr	<= 23'hcd;
				x_porta_wdata	<= 64'hdeadbeef_c0debabe;

				y_porta_en		<= 1;
				y_porta_wr		<= 1;
				y_porta_addr	<= 23'hcd;
				y_porta_wdata	<= 64'hcccccccc_dddddddd;

				count			<= 1;
			end

			//second single write
			1: begin
				x_porta_en		<= 1;
				x_porta_wr		<= 1;
				x_porta_addr	<= 23'h80;
				x_porta_wdata	<= 64'hc0ffffee_f00df00d;
				count			<= 2;
			end

			//read first of dual writes
			2: begin
				x_portb_en		<= 1;
				x_portb_wr		<= 0;
				x_portb_addr	<= 23'hcd;
				count			<= 3;
			end

			//read single write
			3: begin
				x_portb_en		<= 1;
				x_portb_wr		<= 0;
				x_portb_addr	<= 23'h80;
				count			<= 4;
			end

			//read second of dual writes
			4: begin
				x_portb_en		<= 1;
				x_portb_wr		<= 0;
				x_portb_addr	<= 23'h10cd;
				count			<= 5;
			end

		endcase

	end

endmodule
