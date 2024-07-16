`default_nettype none
`timescale 1ns/1ps

/***********************************************************************************************************************
*                                                                                                                      *
* misc-devboards                                                                                                       *
*                                                                                                                      *
* Copyright (c) 2023-2024 Andrew D. Zonenberg and contributors                                                         *
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

module top(
	input wire			clk_25mhz,

	//FPGA FMC pins
	//for now, make them all inputs so we can have the MCU toggle for testing
	input wire			fmc_clk,
	output wire			fmc_nwait,
	input wire			fmc_noe,
	inout wire[15:0]	fmc_ad,
	input wire			fmc_nwe,
	input wire[1:0]		fmc_nbl,
	input wire			fmc_nl_nadv,
	input wire[2:0]		fmc_a_hi,
	input wire			fmc_ne3,
	input wire			fmc_ne1,

	output logic[3:0]	led = 0
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clock synthesis PLL

	wire	clk_100mhz_raw;
	wire	pll_lock;
	wire	clk_fb;

	PLLE2_BASE #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT(40),	//1 GHz VCO
		.DIVCLK_DIVIDE(1),
		.CLKFBOUT_PHASE(0),
		.CLKIN1_PERIOD(40),
		.STARTUP_WAIT("FALSE"),

		.CLKOUT0_DIVIDE(10),	//100 MHz
		.CLKOUT1_DIVIDE(5),
		.CLKOUT2_DIVIDE(5),
		.CLKOUT3_DIVIDE(5),
		.CLKOUT4_DIVIDE(5),
		.CLKOUT5_DIVIDE(5),

		.CLKOUT0_PHASE(0),
		.CLKOUT1_PHASE(0),
		.CLKOUT2_PHASE(0),
		.CLKOUT3_PHASE(0),
		.CLKOUT4_PHASE(0),
		.CLKOUT5_PHASE(0),

		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5)
	) pll (
		.CLKIN1(clk_25mhz),
		.CLKFBIN(clk_fb),
		.CLKFBOUT(clk_fb),
		.RST(1'b0),
		.CLKOUT0(clk_100mhz_raw),
		.CLKOUT1(),
		.CLKOUT2(),
		.CLKOUT3(),
		.CLKOUT4(),
		.CLKOUT5(),
		.LOCKED(pll_lock),
		.PWRDWN(0)
	);

	(* KEEP = "yes" *)
	wire	clk_100mhz;
	BUFGCE bufg_clk_100mhz(
		.I(clk_100mhz_raw),
		.O(clk_100mhz),
		.CE(pll_lock)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// FMC to APB bridge

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(20), .USER_WIDTH(0)) fmc_apb();

	FMC_APBBridge fmcbridge(
		.apb(fmc_apb),

		.fmc_clk(fmc_clk),
		.fmc_nwait(fmc_nwait),
		.fmc_noe(fmc_noe),
		.fmc_ad(fmc_ad),
		.fmc_nwe(fmc_nwe),
		.fmc_nbl(fmc_nbl),
		.fmc_nl_nadv(fmc_nl_nadv),
		.fmc_a_hi(fmc_a_hi),
		.fmc_cs_n(fmc_ne1)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB root bridge

	//Two 16-bit bus segments at 0xc000_0000 (APB1) and c001_0000 (APB2)
	//APB1 has 1 kB address space per peripheral and is for small stuff
	//APB2 has 4 kB address space per peripheral and is only used for Ethernet
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) rootAPB[1:0]();

	//Root bridge
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),	//MSBs are not sent over FMC so we set to zero on our side
		.BLOCK_SIZE(32'h1_0000),
		.NUM_PORTS(2)
	) root_bridge (
		.upstream(fmc_apb),
		.downstream(rootAPB)
	);

	//Pipeline stages at top side of each root in case we need to improve timing
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb1_root();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(1)) regslice_apb1_root(
		.upstream(rootAPB[0]),
		.downstream(apb1_root));

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb2_root();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(1)) regslice_apb2_root(
		.upstream(rootAPB[1]),
		.downstream(apb2_root));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB bridge for small peripherals

	//APB1
	localparam NUM_APB1_PERIPHERALS = 2;
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb1[NUM_APB1_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(32'h400),
		.NUM_PORTS(NUM_APB1_PERIPHERALS)
	) apb1_bridge (
		.upstream(apb1_root),
		.downstream(apb1)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GPIO core

	wire[31:0]	gpioa_out;
	wire[31:0]	gpioa_in;
	wire[31:0]	gpioa_tris;

	//add some latency to test reads
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_gpioa();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(0)) regslice_apb_gpioa(
		.upstream(apb1[0]),
		.downstream(apb_gpioa));

	//c000_0000
	APB_GPIO gpioA(
		.apb(apb_gpioa),

		.gpio_out(gpioa_out),
		.gpio_in(gpioa_in),
		.gpio_tris(gpioa_tris)
	);

	always_comb begin
		led = gpioa_out[3:0];
	end

	assign gpioa_in = 32'hcafebabe;

endmodule
