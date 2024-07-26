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

import EthernetBus::*;

module top(

	//System clock input
	input wire			clk_25mhz,

	//FMC pins to MCU for APB interface
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

	//GPIO LEDs
	output wire[3:0]	led,

	//RGMII PHY
	output wire			rgmii_tx_clk,
	output wire			rgmii_tx_en,
	output wire[3:0]	rgmii_txd,
	input wire			rgmii_rx_clk,
	input wire			rgmii_rx_dv,
	input wire[3:0]		rgmii_rxd,

	//MDIO and control lines to PHY
	inout wire			eth_mdio,
	output wire			eth_mdc,
	output wire			eth_rst_n,

	//PMOD GPIO
	inout wire[7:0]		pmod_gpio,

	//QSPI flash lines
	inout wire[3:0]		flash_dq,
	output wire			flash_cs_n
	//flash SCK is CCLK pin from STARTUPE2
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clock synthesis PLL for Ethernet stuff

	wire	clk_125mhz_raw;
	wire	clk_250mhz_raw;
	wire	pll_lock;
	wire	clk_fb;

	PLLE2_BASE #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT(40),	//1 GHz VCO
		.DIVCLK_DIVIDE(1),
		.CLKFBOUT_PHASE(0),
		.CLKIN1_PERIOD(40),
		.STARTUP_WAIT("FALSE"),

		.CLKOUT0_DIVIDE(8),	//125 MHz
		.CLKOUT1_DIVIDE(4),	//250 MHz
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
	) eth_pll (
		.CLKIN1(clk_25mhz),
		.CLKFBIN(clk_fb),
		.CLKFBOUT(clk_fb),
		.RST(1'b0),
		.CLKOUT0(clk_125mhz_raw),
		.CLKOUT1(clk_250mhz_raw),
		.CLKOUT2(),
		.CLKOUT3(),
		.CLKOUT4(),
		.CLKOUT5(),
		.LOCKED(pll_lock),
		.PWRDWN(0)
	);

	wire	clk_125mhz;
	BUFGCE bufg_clk_125mhz(
		.I(clk_125mhz_raw),
		.O(clk_125mhz),
		.CE(pll_lock)
	);

	wire	clk_250mhz;
	BUFGCE bufg_clk_250mhz(
		.I(clk_250mhz_raw),
		.O(clk_250mhz),
		.CE(pll_lock)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// FMC to APB bridge

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(20), .USER_WIDTH(0)) fmc_apb();

	FMC_APBBridge #(
		.CLOCK_PERIOD(7.27),	//137.5 MHz
		.VCO_MULT(8),			//1.1 GHz VCO
		.CAPTURE_CLOCK_PHASE(-30),
		.LAUNCH_CLOCK_PHASE(-30)
	) fmcbridge(
		.apb(fmc_apb),

		.clk_mgmt(clk_125mhz),

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

	//Pipeline stage for timing
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(20), .USER_WIDTH(0)) fmc_apb_pipe();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(1)) regslice_apb_root(
		.upstream(fmc_apb),
		.downstream(fmc_apb_pipe));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Ethernet MAC

	wire			mgmt0_rx_clk;
	EthernetRxBus	mgmt0_rx_bus;
	EthernetTxBus	mgmt0_tx_bus;
	wire			mgmt0_tx_ready;
	wire			mgmt0_link_up;
	lspeed_t		mgmt0_link_speed;

	RGMIIMACWrapper #(
		.CLK_BUF_TYPE("LOCAL"),
		.PHY_INTERNAL_DELAY_RX(1)
	) port_mgmt0 (
		.clk_125mhz(clk_125mhz),
		.clk_250mhz(clk_250mhz),

		.rgmii_rxc(rgmii_rx_clk),
		.rgmii_rxd(rgmii_rxd),
		.rgmii_rx_ctl(rgmii_rx_dv),

		.rgmii_txc(rgmii_tx_clk),
		.rgmii_txd(rgmii_txd),
		.rgmii_tx_ctl(rgmii_tx_en),

		.mac_rx_clk(mgmt0_rx_clk),
		.mac_rx_bus(mgmt0_rx_bus),

		.mac_tx_bus(mgmt0_tx_bus),
		.mac_tx_ready(mgmt0_tx_ready),

		.link_up(mgmt0_link_up),
		.link_speed(mgmt0_link_speed)
		);

	wire			rgmii_link_up_core;
	ThreeStageSynchronizer sync_rgmii_link_up(
		.clk_in(mgmt0_rx_clk), .din(mgmt0_link_up), .clk_out(fmc_apb.pclk), .dout(rgmii_link_up_core));

	EthernetRxBus	cdc_rx_bus;
	EthernetRxClockCrossing eth_rx_cdc(
		.gmii_rxc(mgmt0_rx_clk),
		.mac_rx_bus(mgmt0_rx_bus),

		.sys_clk(fmc_apb.pclk),
		.rst_n(fmc_apb.preset_n),
		.cdc_rx_bus(cdc_rx_bus),

		.perf_rx_cdc_frames()
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
		.upstream(fmc_apb_pipe),
		.downstream(rootAPB)
	);

	//Pipeline stages at top side of each root in case we need to improve timing
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb1_root();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(0)) regslice_apb1_root(
		.upstream(rootAPB[0]),
		.downstream(apb1_root));

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb2_root();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(0)) regslice_apb2_root(
		.upstream(rootAPB[1]),
		.downstream(apb2_root));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB bridge for small peripherals

	//APB1
	localparam NUM_APB1_PERIPHERALS = 4;
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
	// APB bridge for large peripherals (ethernet etc)

	//APB2
	localparam NUM_APB2_PERIPHERALS = 2;
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(12), .USER_WIDTH(0)) apb2[NUM_APB2_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(32'h1000),
		.NUM_PORTS(NUM_APB2_PERIPHERALS)
	) apb2_bridge (
		.upstream(apb2_root),
		.downstream(apb2)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GPIO core (c000_0000)

	wire[31:0]	gpioa_out;
	wire[31:0]	gpioa_in;
	wire[31:0]	gpioa_tris;

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_gpioa();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(1)) regslice_apb_gpioa(
		.upstream(apb1[0]),
		.downstream(apb_gpioa));

	APB_GPIO gpioA(
		.apb(apb_gpioa),

		.gpio_out(gpioa_out),
		.gpio_in(gpioa_in),
		.gpio_tris(gpioa_tris)
	);

	wire	rx_frame_ready;

	//tie off unused bits
	assign gpioa_in[23:7] = 0;

	//LEDs
	assign led				= gpioa_out[3:0];
	assign gpioa_in[3:0]	= led;

	//Ethernet
	assign eth_rst_n		= gpioa_out[4];
	assign gpioa_in[4]		= eth_rst_n;
	assign gpioa_in[5]		= rgmii_link_up_core;
	assign gpioa_in[6]		= rx_frame_ready;

	//PMOD
	for(genvar g=0; g<8; g++) begin : pmod
		IOBUF iobuf(
			.I(gpioa_out[24+g]),
			.O(gpioa_in[24+g]),
			.T(!gpioa_tris[24+g]),
			.IO(pmod_gpio[g]));
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Device information (c000_0400)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_devinfo();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(1)) regslice_apb_devinfo(
		.upstream(apb1[1]),
		.downstream(apb_devinfo));

	APB_DeviceInfo_7series devinfo(
		.apb(apb_devinfo),
		.clk_dna(clk_25mhz),
		.clk_icap(clk_25mhz) );

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MDIO transciever (c000_0800)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_mdio();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(1)) regslice_apb_mdio(
		.upstream(apb1[2]),
		.downstream(apb_mdio));

	APB_MDIO #(
		.CLK_DIV(125)
	) mdio (
		.apb(apb_mdio),

		.mdio(eth_mdio),
		.mdc(eth_mdc)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SPI flash controller (c000_0c00). For now x1 not quad

	wire	cclk;

	//DQ2 / WP and DQ3 / HOLD aren't used for now, tie high
	IOBUF iobuf_flash_dq3(
		.I(1'b1),
		.O(),
		.T(1'b0),
		.IO(flash_dq[3]));
	IOBUF iobuf_flash_dq2(
		.I(1'b1),
		.O(),
		.T(1'b0),
		.IO(flash_dq[2]));

	//Drive DQ1 / SO to high-Z
	wire	flash_so;
	IOBUF iobuf_flash_dq1(
		.I(1'b0),
		.O(flash_so),
		.T(1'b1),
		.IO(flash_dq[1]));

	//Drive DQ0 / SI with our serial data
	wire	flash_si;
	wire	flash_si_echo;
	IOBUF iobuf_flash_dq0(
		.I(flash_si),
		.O(flash_si_echo),
		.T(1'b0),
		.IO(flash_dq[0]));

	//STARTUP block
	wire	ring_clk;
	STARTUPE2 startup(
		.CLK(ring_clk),
		.GSR(1'b0),
		.GTS(1'b0),
		.KEYCLEARB(1'b1),
		.PACK(1'b0),
		.PREQ(),
		.USRCCLKO(cclk),
		.USRCCLKTS(1'b0),
		.USRDONEO(1'b1),
		.USRDONETS(1'b0),
		.CFGCLK(),
		.CFGMCLK(ring_clk),
		.EOS()
		);

	//SPI bus controller
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_flash();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(1)) regslice_apb_flash(
		.upstream(apb1[3]),
		.downstream(apb_flash));

	APB_SPIHostInterface flash(
		.apb(apb_flash),

		.spi_sck(cclk),
		.spi_mosi(flash_si),
		.spi_miso(flash_so),
		.spi_cs_n(flash_cs_n)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Ethernet RX FIFO (c001_0000)

	APB_EthernetRxBuffer_x32 eth_rx_fifo(
		.apb(apb2[0]),
		.eth_rx_bus(cdc_rx_bus),
		.eth_link_up(rgmii_link_up_core),

		.rx_frame_ready(rx_frame_ready)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Ethernet TX FIFO (c001_1000)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(12), .USER_WIDTH(0)) apb_tx_fifo();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(0)) regslice_apb_tx_fifo(
		.upstream(apb2[1]),
		.downstream(apb_tx_fifo));

	APB_EthernetTxBuffer_x32_1G eth_tx_fifo(
		.apb(apb_tx_fifo),
		.tx_clk(clk_125mhz),
		.tx_bus(mgmt0_tx_bus),
		.tx_ready(mgmt0_tx_ready),
		.link_up_pclk(rgmii_link_up_core)
	);

endmodule
