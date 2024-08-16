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

#include "supervisor.h"
#include "IBCRegisterReader.h"
#include <supervisor/TempSensorReader.h>
#include "SupervisorSPIServer.h"

//TODO: fix this path somehow?
#include "../../../../common-ibc/firmware/main/regids.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// System status indicator LEDs

GPIOPin g_pgoodLED(&GPIOA, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_faultLED(&GPIOH, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_sysokLED(&GPIOH, 1, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Power rail descriptors

//12V ramp rate is slew rate controlled to about 2 kV/sec, so should take 0.5 ms to come up
//Give it 5 ms to be safe (plus extra delay from UART messages)
//TODO: add a new descriptor type that can get feedback from the IBC remote sense
//to make sure we actually have correct voltage
GPIOPin g_12v0_en(&GPIOA, 12, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnable g_12v0("12V0", g_12v0_en, g_logTimer, 50);

GPIOPin g_1v0_en(&GPIOB, 15, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v0_pgood(&GPIOA, 8, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_1v0("1V0", g_1v0_en, g_1v0_pgood, g_logTimer, 75);

GPIOPin g_1v2_en(&GPIOA, 2, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v2_pgood(&GPIOA, 1, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_1v2("1V2", g_1v2_en, g_1v2_pgood, g_logTimer, 75);

GPIOPin g_1v8_en(&GPIOA, 11, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v8_pgood(&GPIOB, 14, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_1v8("1V8", g_1v8_en, g_1v8_pgood, g_logTimer, 75);

GPIOPin g_3v3_en(&GPIOB, 12, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_3v3_pgood(&GPIOB, 13, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_3v3("3V3", g_3v3_en, g_3v3_pgood, g_logTimer, 75);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Power rail sequence

etl::vector g_powerSequence
{
	//12V has to come up first since it supplies everything else
	(RailDescriptor*)&g_12v0,					//need to cast at least one entry to base class
												//for proper template deduction

	//VCCINT - VCCAUX - VCCO for the FPGA
	&g_1v0,
	&g_1v8,
	&g_3v3,

	//1V2 rail for the PHY should come up after 3.3V rail (note 1 on page 62)
	&g_1v2
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Reset descriptors

//Active low edge triggered reset
GPIOPin g_fpgaResetN(&GPIOA, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
ActiveLowResetDescriptor g_fpgaResetDescriptor(g_fpgaResetN, "FPGA PROG");

//Active low level triggered delay-boot flag
//Use this as the "FPGA is done booting" indicator
GPIOPin g_fpgaInitN(&GPIOA, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0, true);
GPIOPin g_fpgaDone(&GPIOB, 2, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
ActiveLowResetDescriptorWithActiveHighDone g_fpgaInitDescriptor(g_fpgaInitN, g_fpgaDone, "FPGA INIT");

//MCU reset comes at the end
GPIOPin g_mcuResetN(&GPIOA, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
ActiveLowResetDescriptor g_mcuResetDescriptor(g_mcuResetN, "MCU");

etl::vector g_resetSequence
{
	//First boot the FPGA
	(ResetDescriptor*)&g_fpgaResetDescriptor,	//need to cast at least one entry to base class
												//for proper template deduction
	&g_fpgaInitDescriptor,

	//then release the MCU
	&g_mcuResetDescriptor,
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// The top level supervisor controller

IfacePowerResetSupervisor g_super(g_powerSequence, g_resetSequence);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// System health monitoring

uint16_t g_ibcTemp = 0;
uint16_t g_ibc3v3 = 0;
uint16_t g_ibcMcuTemp = 0;
uint16_t g_vin48 = 0;
uint16_t g_vout12 = 0;
uint16_t g_voutsense = 0;
uint16_t g_iin = 0;
uint16_t g_iout = 0;
uint16_t g_3v3Voltage = 0;
uint16_t g_mcutemp = 0;

bool PollIBCSensors();

///@brief Firmware version string
char g_version[20] = {0};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Peripheral initialization

void App_Init()
{
	RCCHelper::Enable(&_RTC);

	//Format version string
	StringBuffer buf(g_version, sizeof(g_version));
	static const char* buildtime = __TIME__;
	buf.Printf("%s %c%c%c%c%c%c",
		__DATE__, buildtime[0], buildtime[1], buildtime[3], buildtime[4], buildtime[6], buildtime[7]);
	g_log("Firmware version %s\n", g_version);

	g_super.PowerOn();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main loop

void UpdateLEDs();
void UpdateResets();

const int g_logTimerMax = 60000;

void BSP_MainLoopIteration()
{
	//Handle wraps of the timer in the logger
	g_log.UpdateOffset(g_logTimerMax);

	//Core supervisor state machine
	UpdateLEDs();
	g_super.Iteration();

	//Management and system health
	static SupervisorSPIServer spiserver(g_spi);
	PollIBCSensors();
	spiserver.Poll();
}

/**
	@brief Updatethe system status indicator LEDs
 */
void UpdateLEDs()
{
	//PGOOD LED just tracks power rail states
	g_pgoodLED = g_super.IsPowerOn();

	//OK LED: off = down, blinking = booting, solid = normal operation
	if(g_super.IsPowerOn())
	{
		if(g_super.IsResetsDone())
			g_sysokLED = true;

		else
		{
			//Blink OK LED at 2 Hz if reset state machine is running but we're waiting for everything to come up
			static uint32_t nextBlink = 0;
			const uint32_t blinkDelay = 2500;

			auto now = g_logTimer.GetCount();
			if(now >= nextBlink)
			{
				g_sysokLED = !g_sysokLED;
				nextBlink = now + blinkDelay;
				if(nextBlink > g_logTimerMax)
					nextBlink -= g_logTimerMax;
			}
		}
	}
	else
		g_sysokLED = false;
}

/**
	@brief Requests more sensor data from the IBC

	@return true if sensor values are updated
 */
bool PollIBCSensors()
{
	static IBCRegisterReader regreader;
	static TempSensorReader tempreader(g_i2c, g_tempI2cAddress);

	static int state = 0;

	static int iLastUpdate = 0;
	iLastUpdate ++;

	if(iLastUpdate > 30000)
	{
		g_log(Logger::WARNING, "I2C sensor state machine timeout (IBC hang or reboot?), resetting and trying again\n");

		//Reset both readers and return to the idle state, wait 10ms before retrying anything
		tempreader.Reset();
		regreader.Reset();
		g_i2c.Reset();
		state = 0;
		iLastUpdate = 0;
		g_logTimer.Sleep(2);
	}

	//Read the values
	switch(state)
	{
		case 0:
			if(tempreader.ReadTempNonblocking(g_ibcTemp))
			{
				iLastUpdate = 0;
				state ++;
			}
			break;

		case 1:
			if(regreader.ReadRegisterNonblocking(IBC_REG_VIN, g_vin48))
			{
				iLastUpdate = 0;
				state ++;
			}
			break;

		case 2:
			if(regreader.ReadRegisterNonblocking(IBC_REG_VOUT, g_vout12))
			{
				iLastUpdate = 0;
				state ++;
			}
			break;

		case 3:
			if(regreader.ReadRegisterNonblocking(IBC_REG_VSENSE, g_voutsense))
			{
				iLastUpdate = 0;
				state ++;
			}
			break;

		case 4:
			if(regreader.ReadRegisterNonblocking(IBC_REG_IIN, g_iin))
				state ++;
			break;

		case 5:
			if(regreader.ReadRegisterNonblocking(IBC_REG_IOUT, g_iout))
				state ++;
			break;

		case 6:
			if(regreader.ReadRegisterNonblocking(IBC_REG_MCU_TEMP, g_ibcMcuTemp))
				state ++;
			break;

		case 7:
			if(regreader.ReadRegisterNonblocking(IBC_REG_3V3_SB, g_ibc3v3))
				state ++;
			break;

		//Also read our own internal health sensors at this point in the rotation
		//(should we rename this function PollHealthSensors or something?)
		//TODO: nonblocking ADC accesses?
		case 8:
			if(g_adc->GetTemperatureNonblocking(g_mcutemp))
				state ++;
			break;

		case 9:
			g_3v3Voltage = g_adc->GetSupplyVoltage();
			state ++;
			break;

		//end of loop, wrap around
		default:
			state = 0;
			return true;
	}

	return false;
}
