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

#include "ifacetest.h"

/**
	@brief Digital temperature sensor

	APB4 clock is 68.75 MHz, so divide by 80 to get 859 kHz ticks
	(must be <1 MHz)
	15 cycles integration time = 18.75 us
 */
DigitalTempSensor g_dts(&DTS, 80, 15, 64000000);

/**
	@brief SPI bus to supervisor

	SPI4 runs on spi 4/5 kernel clock domain
	default after reset is APB2 clock which is 62.5 MHz, divide by 128 to get 488 kHz
 */
//SPI<64, 64> g_superSPI(&SPI4, true, 128);

///@brief Chip select for supervisor CS
//GPIOPin* g_superSPICS = nullptr;

///@brief Version string for supervisor MCU
//char g_superVersion[20] = {0};

///@brief Version string for IBC MCU
char g_ibcVersion[20] = {0};

///@brief The SSH server
//ManagementSSHTransportServer* g_sshd = nullptr;

const IPv4Address g_defaultNtpServer	= { .m_octets{10, 2, 5, 26} };
