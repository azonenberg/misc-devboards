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

/**
	@brief Top level module for the design
 */
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

	//SMPM ports are to left PHY on line card
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
	output wire			smpm_2_tx_n,

	//SFP0 is 10Gbase-R management interface
	input wire			sfp0_rx_los,
	output wire[1:0]	sfp0_rs,
	output wire			sfp0_tx_disable,

	input wire			sfp_0_rx_p,
	input wire			sfp_0_rx_n,

	output wire			sfp_0_tx_p,
	output wire			sfp_0_tx_n,

	//SFP1 is SCCB link to lcbringup
	input wire			sfp_1_rx_p,
	input wire			sfp_1_rx_n,

	output wire			sfp_1_tx_p,
	output wire			sfp_1_tx_n
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// System clock inputs

	wire	clk_156m25;
	wire	refclk;

	TopLevelClocks clocks(
		.clk_156m25_p(clk_156m25_p),
		.clk_156m25_n(clk_156m25_n),

		.refclk_p(refclk_p),
		.refclk_n(refclk_n),

		.gpio_p(gpio_p),
		.gpio_n(gpio_n),

		.clk_156m25(clk_156m25),
		.refclk(refclk)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY quad for the SFP+ interfaces

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .USER_WIDTH(0)) apb_req();

	AXIStream #(.DATA_WIDTH(32), .ID_WIDTH(0), .DEST_WIDTH(0), .USER_WIDTH(1)) mgmt0_rx_data();
	AXIStream #(.DATA_WIDTH(32), .ID_WIDTH(0), .DEST_WIDTH(0), .USER_WIDTH(1)) mgmt0_tx_data();

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_sfp_qpll();

	wire	mgmt0_link_up;
	wire	mgmt0_tx_clk;

	SFP_Quad sfp_quad_225(
		.clk_156m25(clk_156m25),
		.refclk(refclk),

		.sfp_0_rx_p(sfp_0_rx_p),
		.sfp_0_rx_n(sfp_0_rx_n),

		.sfp_0_tx_p(sfp_0_tx_p),
		.sfp_0_tx_n(sfp_0_tx_n),

		.sfp_1_rx_p(sfp_1_rx_p),
		.sfp_1_rx_n(sfp_1_rx_n),

		.sfp_1_tx_p(sfp_1_tx_p),
		.sfp_1_tx_n(sfp_1_tx_n),

		.sfp0_rx_los(sfp0_rx_los),
		.sfp0_rs(sfp0_rs),
		.sfp0_tx_disable(sfp0_tx_disable),

		.apb_req(apb_req),

		.apb_qpll(apb_sfp_qpll),

		.mgmt0_rx_data(mgmt0_rx_data),
		.mgmt0_tx_data(mgmt0_tx_data),
		.mgmt0_tx_clk(mgmt0_tx_clk),

		.mgmt0_link_up(mgmt0_link_up)
	);

	//Transfer the RX-side Ethernet data into the SCCB clock domain
	AXIStream #(.DATA_WIDTH(32), .ID_WIDTH(0), .DEST_WIDTH(0), .USER_WIDTH(1)) mgmt0_rx_data_pclk();
	AXIS_CDC #(
		.FIFO_DEPTH(1024)
	) mgmt0_rx_cdc (
		.axi_rx(mgmt0_rx_data),

		.tx_clk(apb_req.pclk),
		.axi_tx(mgmt0_rx_data_pclk)
	);

	//Shift link state into the SCCB and TX clock domains
	wire	mgmt0_link_up_pclk;

	ThreeStageSynchronizer #(
		.IN_REG(1)
	) sync_link_up(
		.clk_in(mgmt0_rx_data.aclk),
		.din(mgmt0_link_up),
		.clk_out(mgmt0_rx_data_pclk.aclk),
		.dout(mgmt0_link_up_pclk));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GTY quad for the SMPM interfaces

	//Ethernet links coming off the QSGMII PHY
	AXIStream #(.DATA_WIDTH(32), .ID_WIDTH(0), .DEST_WIDTH(0), .USER_WIDTH(1)) linecard_rx_data[11:0]();
	AXIStream #(.DATA_WIDTH(32), .ID_WIDTH(0), .DEST_WIDTH(0), .USER_WIDTH(1)) linecard_tx_data[11:0]();

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_smpm_qpll();
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .USER_WIDTH(0)) apb_smpm_serdes_lane[2:0]();

	wire[11:0]	smpm_link_up;

	SMPM_Quad smpm_quad_224(
		.clk_156m25(clk_156m25),
		.clk_fabric(clk_156m25),	//TODO: switch to 312.5 MHz fabric clock??
		.refclk(refclk),

		.smpm_0_rx_p(smpm_0_rx_p),
		.smpm_0_rx_n(smpm_0_rx_n),

		.smpm_0_tx_p(smpm_0_tx_p),
		.smpm_0_tx_n(smpm_0_tx_n),

		.smpm_1_rx_p(smpm_1_rx_p),
		.smpm_1_rx_n(smpm_1_rx_n),

		.smpm_1_tx_p(smpm_1_tx_p),
		.smpm_1_tx_n(smpm_1_tx_n),

		.smpm_2_rx_p(smpm_2_rx_p),
		.smpm_2_rx_n(smpm_2_rx_n),

		.smpm_2_tx_p(smpm_2_tx_p),
		.smpm_2_tx_n(smpm_2_tx_n),

		.link_up(smpm_link_up),

		.apb_qpll(apb_smpm_qpll),
		.apb_serdes_lane(apb_smpm_serdes_lane),

		.axi_rx(linecard_rx_data),
		.axi_tx(linecard_tx_data)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Root APB bridge (0xc010_0000)

	//64 kB blocks
	localparam ROOT_BLOCK_SIZE	= 32'h1_0000;
	localparam ROOT_ADDR_WIDTH	= $clog2(ROOT_BLOCK_SIZE);
	localparam ROOT_NUM_BLOCKS	= 2;

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(ROOT_ADDR_WIDTH), .USER_WIDTH(0)) apb_root[ROOT_NUM_BLOCKS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(ROOT_BLOCK_SIZE),
		.NUM_PORTS(ROOT_NUM_BLOCKS)
	) root_bridge (
		.upstream(apb_req),
		.downstream(apb_root)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1 (0xc010_0000)

	wire	mgmt0_frame_ready;

	Peripherals_APB1 apb1(
		.apb(apb_root[0]),

		.mgmt0_frame_ready(mgmt0_frame_ready),
		.mgmt0_link_up_pclk(mgmt0_link_up_pclk),

		.apb_smpm_qpll(apb_smpm_qpll),
		.apb_sfp_qpll(apb_sfp_qpll),
		.apb_smpm_serdes_lane(apb_smpm_serdes_lane)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB2 (0xc011_0000)

	Peripherals_APB2 apb2(
		.apb(apb_root[1]),

		.mgmt_eth_link_up(mgmt0_link_up_pclk),
		.mgmt_eth_frame_ready(mgmt0_frame_ready),

		.mgmt_eth_tx_clk(mgmt0_tx_clk),
		.mgmt_eth_rx(mgmt0_rx_data_pclk),
		.mgmt_eth_tx(mgmt0_tx_data)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Switch fabric TODO

	//dummy sink fabric is always ready for new data for now
	//for(genvar g=0; g<12; g=g+1)
	for(genvar g=1; g<12; g=g+1)
		assign linecard_rx_data[g].tready = 1;

endmodule
