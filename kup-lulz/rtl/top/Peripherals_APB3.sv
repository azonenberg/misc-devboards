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
	@brief Small (1 kB) peripherals on the APB3 bus segment (0xc012_0000 - 0xc012_ffff) in the switch fabric clock domain
 */
module Peripherals_APB3(

	//Upstream APB to the root bridge
	APB.completer	apb,

	//Switch fabric clock domain (lots of registers have to be shifted to this)
	input wire		clk_fabric,

	//Line card 0 control registers
	//TODO: move module instantiation under switch fabric hierarchy area?
	output wire[11:0]	lc0_port_vlan[23:0],
	output wire			lc0_port_drop_tagged[23:0],
	output wire			lc0_port_drop_untagged[23:0]

	//TODO: performance counters etc?
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Shift the entire APB segment into the switch fabric clock domain upstream of the bridge

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb_clk_fabric();
	APB_CDC cdc_fabric(
		.upstream(apb),

		.downstream_pclk(clk_fabric),
		.downstream(apb_clk_fabric)
	);


	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB3 (0xc012_0000)

	localparam NUM_APB3_PERIPHERALS	= 4;
	localparam APB3_BLOCK_SIZE		= 32'h400;
	localparam APB3_ADDR_WIDTH		= $clog2(APB3_BLOCK_SIZE);
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB3_ADDR_WIDTH), .USER_WIDTH(0)) apb3[NUM_APB3_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(APB3_BLOCK_SIZE),
		.NUM_PORTS(NUM_APB3_PERIPHERALS)
	) bridge (
		.upstream(apb_clk_fabric),
		.downstream(apb3)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB3: Line card 0 control registers (0xc012_0000)

	LineCardControlRegisters lc0_ctlregs(
		.apb(apb3[0]),

		.port_vlan(lc0_port_vlan),
		.port_drop_tagged(lc0_port_drop_tagged),
		.port_drop_untagged(lc0_port_drop_untagged)
	);

endmodule
