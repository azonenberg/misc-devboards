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

/**
	@file
	@author	Andrew D. Zonenberg
	@brief	System initialization
 */

#include "ifacetest.h"
#include <ctype.h>
//#include "../super/superregs.h"

/**
	@brief Initialize global GPIO LEDs
 */
void InitLEDs()
{
	g_leds[0] = 1;
	g_leds[1] = 1;
	g_leds[2] = 1;
	g_leds[3] = 1;
}

/**
	@brief Initialize the SPI bus to the supervisor
 */
void InitSupervisor()
{
	/*
	g_log("Initializing supervisor\n");
	LogIndenter li(g_log);

	//Set up the GPIOs for chip selects and deselect everything
	auto slew = GPIOPin::SLEW_MEDIUM;
	static GPIOPin super_cs_n(&GPIOE, 4, GPIOPin::MODE_OUTPUT, slew);
	super_cs_n = 1;
	g_superSPICS = &super_cs_n;
	g_logTimer.Sleep(1);

	//Initialize the rest of our IOs
	static GPIOPin spi_sck(&GPIOE, 2, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_MEDIUM, 5);
	static GPIOPin spi_miso(&GPIOE, 5, GPIOPin::MODE_PERIPHERAL, slew, 5);
	static GPIOPin spi_mosi(&GPIOE, 6, GPIOPin::MODE_PERIPHERAL, slew, 5);

	//Get the supervisor firmware version
	super_cs_n = 0;
	g_superSPI.BlockingWrite(SUPER_REG_VERSION);
	g_superSPI.WaitForWrites();
	g_superSPI.DiscardRxData();
	g_superSPI.BlockingRead();	//discard dummy byte
	for(size_t i=0; i<sizeof(g_superVersion); i++)
		g_superVersion[i] = g_superSPI.BlockingRead();
	g_superVersion[sizeof(g_superVersion)-1] = '\0';
	super_cs_n = 1;
	g_log("Firmware version: %s\n", g_superVersion);

	//Get IBC firmware version
	super_cs_n = 0;
	g_superSPI.BlockingWrite(SUPER_REG_IBCVERSION);
	g_superSPI.WaitForWrites();
	g_superSPI.DiscardRxData();
	g_superSPI.BlockingRead();	//discard dummy byte
	for(size_t i=0; i<sizeof(g_ibcVersion); i++)
		g_ibcVersion[i] = g_superSPI.BlockingRead();
	g_ibcVersion[sizeof(g_ibcVersion)-1] = '\0';
	super_cs_n = 1;
	g_log("IBC firmware version: %s\n", g_ibcVersion);
	*/
}

/**
	@brief Initialize sensors and log starting values for each
 */
void InitSensors()
{
	/*
	g_log("Initializing sensors\n");
	LogIndenter li(g_log);

	//Wait 50ms to get accurate readings
	g_logTimer.Sleep(500);

	//Read fans
	for(uint8_t i=0; i<2; i++)
	{
		auto rpm = GetFanRPM(i);
		if(rpm == 0)
			g_log(Logger::ERROR, "Fan %d:                                 STOPPED\n", i, rpm);
		else
			g_log("Fan %d:                                 %d RPM\n", i, rpm);

		//skip reading fan1 as we don't have it connected
		break;
	}

	//Read FPGA temperature
	auto temp = GetFPGATemperature();
	g_log("FPGA die temperature:                  %uhk C\n", temp);

	//Read FPGA voltage sensors
	int volt = GetFPGAVCCINT();
	g_log("FPGA VCCINT:                            %uhk V\n", volt);
	volt = GetFPGAVCCBRAM();
	g_log("FPGA VCCBRAM:                           %uhk V\n", volt);
	volt = GetFPGAVCCAUX();
	g_log("FPGA VCCAUX:                            %uhk V\n", volt);

	InitDTS();
	*/
}

/**
	@brief Initialize the digital temperature sensor
 */
void InitDTS()
{
	auto tempval = g_dts.GetTemperature();
	g_log("MCU die temperature:                   %d.%02d C\n",
		(tempval >> 8),
		static_cast<int>(((tempval & 0xff) / 256.0) * 100));
}

void RegisterProtocolHandlers(IPv4Protocol& ipv4)
{
	//static ManagementTCPProtocol tcp(&ipv4);
	static DemoUDPProtocol udp(&ipv4);
	//ipv4.UseTCP(&tcp);
	ipv4.UseUDP(&udp);
	//g_dhcpClient = &udp.GetDHCP();
}
