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
	@brief	Boot-time hardware intialization
 */
#include "supervisor.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Peripheral initialization

void App_Init()
{
	RCCHelper::Enable(&_RTC);
	InitGPIOs();
	InitI2C();
	PowerOn();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Other hardware init

void InitGPIOs()
{
	g_log("Initializing GPIOs\n");

	//active low enable as long as we're using the v0.1 IBC proto
	g_12v0_en = 1;

	//turn off all regulators
	g_1v0_en = 0;
	g_1v2_en = 0;
	g_1v8_en = 0;
	g_3v3_en = 0;

	//Hold MCU in reset
	g_mcuResetN = 0;
	g_fpgaResetN = 0;
	g_fpgaInitN = 0;

	//Enable pullups on all PGOOD lines
	g_1v0_pgood.SetPullMode(GPIOPin::PULL_UP);
	g_1v2_pgood.SetPullMode(GPIOPin::PULL_UP);
	g_1v8_pgood.SetPullMode(GPIOPin::PULL_UP);
	g_3v3_pgood.SetPullMode(GPIOPin::PULL_UP);

	//turn off all LEDs
	g_pgoodLED = 0;
	g_faultLED = 0;
	g_sysokLED = 0;
}

void InitI2C()
{
	/*
	g_log("Initializing I2C interface\n");

	static GPIOPin i2c_scl(&GPIOB, 13, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
	static GPIOPin i2c_sda(&GPIOB, 11, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
	//PB12 is used as a route-through for SDA, so just leave it in the default floating state
	*/
}
