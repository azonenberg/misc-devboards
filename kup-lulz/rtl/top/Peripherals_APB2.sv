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
	@brief Large (4 kB) peripherals on the APB2 bus segment (0xc011_0000 - 0xc011_ffff)
 */
module Peripherals_APB2(

	//Upstream APB to the root bridge
	APB.completer			apb,

	//Management Ethernet status GPIOs
	input wire				mgmt_eth_link_up,
	output wire				mgmt_eth_frame_ready,

	//Management Ethernet AXI
	input wire				mgmt_eth_tx_clk,
	AXIStream.receiver		mgmt_eth_rx,
	AXIStream.transmitter	mgmt_eth_tx
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB2 (0xc011_0000)

	localparam NUM_APB2_PERIPHERALS	= 4;
	localparam APB2_BLOCK_SIZE		= 32'h1000;
	localparam APB2_ADDR_WIDTH		= $clog2(APB2_BLOCK_SIZE);
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB2_ADDR_WIDTH), .USER_WIDTH(0)) apb2[NUM_APB2_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(APB2_BLOCK_SIZE),
		.NUM_PORTS(NUM_APB2_PERIPHERALS)
	) apb2_bridge (
		.upstream(apb),
		.downstream(apb2)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Ethernet RX FIFO (0xc011_0000)

	APB_AXIS_EthernetRxBuffer mgmt0_rx_fifo(
		.apb(apb2[0]),

		.axi_rx(mgmt_eth_rx),
		.eth_link_up(mgmt_eth_link_up),

		.rx_frame_ready(mgmt_eth_frame_ready)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Ethernet TX FIFO (0xc011_1000)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB2_ADDR_WIDTH), .USER_WIDTH(0)) apb_tx_fifo();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(0)) regslice_apb_tx_fifo(
		.upstream(apb2[1]),
		.downstream(apb_tx_fifo));

	APB_AXIS_EthernetTxBuffer mgmt0_tx_fifo(
		.apb(apb_tx_fifo),
		.link_up_pclk(mgmt_eth_link_up),
		.tx_clk(mgmt_eth_tx_clk),
		.axi_tx(mgmt_eth_tx)
	);

	/*
	EthernetChecksumOffload eth_offload(
		.clk(mgmt0_tx_clk),
		.link_up(mgmt0_link_up_pclk),
		.buf_tx_ready(fifo_tx_ready),
		.buf_tx_bus(fifo_tx_bus),
		.mac_tx_ready(mgmt0_tx_ready),
		.mac_tx_bus(mgmt0_tx_bus)
	);
	*/

endmodule
