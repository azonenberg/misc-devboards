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
	@brief Small (1 kB) peripherals on the APB1 bus segment (0xc010_0000 - 0xc010_ffff)
 */
module Peripherals_APB1(

	//Upstream APB to the root bridge
	APB.completer	apb,

	//Status signals
	input wire		mgmt0_frame_ready,
	input wire		mgmt0_link_up_pclk,

	//QSFP GPIOs
	output wire		qsfp0_lpmode,
	output wire		qsfp0_i2c_sel_n,
	output wire		qsfp0_rst_n,
	input wire		qsfp0_present_n,
	input wire		qsfp0_int_n,

	//QSFP I2C
	inout wire		qsfp0_i2c_sda,
	output wire		qsfp0_i2c_scl,

	//Buses out to other blocks
	APB.requester	apb_smpm_qpll,
	APB.requester	apb_sfp_qpll,
	APB.requester	apb_smpm_serdes_lane[2:0],
	APB.requester	apb_qsfp0_qpll,
	APB.requester	apb_qsfp0_serdes_lane[3:0]
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1 (0xc010_0000)

	localparam NUM_APB1_PERIPHERALS	= 13;
	localparam APB1_BLOCK_SIZE		= 32'h400;
	localparam APB1_ADDR_WIDTH		= $clog2(APB1_BLOCK_SIZE);
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) apb1[NUM_APB1_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(APB1_BLOCK_SIZE),
		.NUM_PORTS(NUM_APB1_PERIPHERALS)
	) apb1_bridge (
		.upstream(apb),
		.downstream(apb1)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: Device information (0xc010_0000)

	APB_DeviceInfo_UltraScale devinfo(
		.apb(apb1[0]),
		.clk_dna(apb1[0].pclk),
		.clk_icap(apb1[0].pclk)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: GPIO with status/control signals (0xc010_0400)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) apb_gpioa();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(1)) regslice_apb_gpioa(
		.upstream(apb1[1]),
		.downstream(apb_gpioa));

	wire[31:0]	gpioa_out;
	wire[31:0]	gpioa_in;
	wire[31:0]	gpioa_tris;

	APB_GPIO gpioA(
		.apb(apb_gpioa),

		.gpio_out(gpioa_out),
		.gpio_in(gpioa_in),
		.gpio_tris(gpioa_tris)
	);

	//Hook up inputs
	assign gpioa_in[0]		= mgmt0_frame_ready;
	assign gpioa_in[1]		= mgmt0_link_up_pclk;
	assign gpioa_in[2]		= qsfp0_lpmode;
	assign gpioa_in[3]		= qsfp0_i2c_sel_n;
	assign gpioa_in[4]		= qsfp0_rst_n;
	assign gpioa_in[5]		= qsfp0_present_n;
	assign gpioa_in[6]		= qsfp0_int_n;

	//Hook up outputs
	assign qsfp0_lpmode		= gpioa_out[2];
	assign qsfp0_i2c_sel_n	= gpioa_out[3];
	assign qsfp0_rst_n		= gpioa_out[4];

	//Tie off unused signals
	assign gpioa_in[31:7]	= 0;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: curve25519 accelerator (0xc010_0800)

	//For now, run in the same clock domain as the normal PCLK but this may change
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) cryptBus();

	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_crypt( .upstream(apb1[2]), .downstream(cryptBus) );

	APB_Curve25519 crypt25519(.apb(cryptBus));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: QPLL DRP for SMPM interface (0xc010_0c00)

	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_smpm_qpll( .upstream(apb1[3]), .downstream(apb_smpm_qpll) );

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: QPLL DRP for SFP interface (0xc010_1000)

	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_sfp_qpll( .upstream(apb1[4]), .downstream(apb_sfp_qpll) );

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: SMPM SERDES lane DRPs (0xc010_1400, 0xc010_1800, 0xc010_1c00)

	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_smpm_serdes_0( .upstream(apb1[5]), .downstream(apb_smpm_serdes_lane[0]) );
	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_smpm_serdes_1( .upstream(apb1[6]), .downstream(apb_smpm_serdes_lane[1]) );
	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_smpm_serdes_2( .upstream(apb1[7]), .downstream(apb_smpm_serdes_lane[2]) );

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: QPLL DRP for QSFP0 interface (0xc010_2000)

	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_qsfp0_qpll( .upstream(apb1[8]), .downstream(apb_qsfp0_qpll) );

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1: QSFP0 SERDES lane DRPs (0xc010_2400, 0xc010_2800, 0xc010_2c00, 0xc010_3000)

	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_qsfp0_serdes_0( .upstream(apb1[9]), .downstream(apb_qsfp0_serdes_lane[0]) );
	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_qsfp0_serdes_1( .upstream(apb1[10]), .downstream(apb_qsfp0_serdes_lane[1]) );
	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_qsfp0_serdes_2( .upstream(apb1[11]), .downstream(apb_qsfp0_serdes_lane[2]) );
	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(1))
		apb_regslice_qsfp0_serdes_3( .upstream(apb1[12]), .downstream(apb_qsfp0_serdes_lane[3]) );

endmodule
