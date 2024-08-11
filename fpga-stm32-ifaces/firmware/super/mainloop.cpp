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
#include "TempSensorReader.h"

//TODO: fix this path somehow?
#include "../../../../common-ibc/firmware/main/regids.h"

//Indicates the main MCU is alive
bool	g_mainMCUDown = true;

//GPIO pins
GPIOPin g_pgoodLED(&GPIOA, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_faultLED(&GPIOH, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_sysokLED(&GPIOH, 1, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);

GPIOPin g_12v0_en(&GPIOA, 12, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v0_en(&GPIOB, 15, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v0_pgood(&GPIOA, 8, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);

GPIOPin g_1v2_en(&GPIOA, 2, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v2_pgood(&GPIOA, 1, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);

GPIOPin g_1v8_en(&GPIOA, 11, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v8_pgood(&GPIOB, 14, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);

GPIOPin g_3v3_en(&GPIOB, 12, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_3v3_pgood(&GPIOB, 13, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);

GPIOPin g_mcuResetN(&GPIOA, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);

GPIOPin g_fpgaResetN(&GPIOA, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_fpgaInitN(&GPIOA, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0, true);

GPIOPin g_fpgaDone(&GPIOB, 2, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);

bool g_fpgaUp = false;

uint16_t g_ibcTemp = 0;
uint16_t g_ibc3v3 = 0;
uint16_t g_ibcMcuTemp = 0;
uint16_t g_vin48 = 0;
uint16_t g_vout12 = 0;
uint16_t g_voutsense = 0;
uint16_t g_iin = 0;
uint16_t g_iout = 0;

bool PollIBCSensors();

void BSP_MainLoopIteration()
{
	const int logTimerMax = 60000;
	static uint32_t next1HzTick = 0;

	//Check for overflows on our log message timer
	if(g_log.UpdateOffset(logTimerMax) && (next1HzTick >= logTimerMax) )
		next1HzTick -= logTimerMax;

	//Check for FPGA state changes
	bool done = g_fpgaDone;
	if(g_fpgaUp != done)
	{
		//If FPGA goes down, shut down the main MCU
		if(!done)
		{
			g_log("FPGA went down, resetting MCU\n");
			g_mcuResetN = 0;
			g_sysokLED = false;
		}
		else
		{
			g_log("FPGA is up, releasing MCU reset\n");
			g_mcuResetN = 1;
			g_sysokLED = true;	//TODO wait until MCU is confirmed alive?
		}
		g_fpgaUp = done;
	}

	//Check for sensor updates
	PollIBCSensors();

	//1 Hz timer event
	static uint32_t nextHealthPrint = 2;
	if(g_logTimer.GetCount() >= next1HzTick)
	{
		next1HzTick = g_logTimer.GetCount() + 10000;

		//DEBUG: log sensor values
		if(nextHealthPrint == 0)
		{
			//Print sensor values
			g_log("Health sensors\n");
			LogIndenter li(g_log);

			//Supervisor sensors
			auto temp = g_adc->GetTemperature();
			g_log("Super temp:      %uhk C\n", temp);
			auto vdd = g_adc->GetSupplyVoltage();
			g_log("Super 3V3_SB:    %2d.%03d V\n", vdd/1000, vdd % 1000);

			//IBC sensors
			g_log("IBC temperature: %uhk C\n", g_ibcTemp);
			g_log("IBC MCU:         %uhk C\n", g_ibcMcuTemp);
			g_log("IBC 3V3_SB:      %2d.%03d V\n", g_ibc3v3 / 1000, g_ibc3v3 % 1000);
			g_log("48V0:            %2d.%03d V\n", g_vin48 / 1000, g_vin48 % 1000);
			g_log("12V0_OUT:        %2d.%03d V\n", g_vout12 / 1000, g_vout12 % 1000);
			g_log("12V0_SENSE:      %2d.%03d V\n", g_voutsense / 1000, g_voutsense % 1000);
			g_log("48V0 load:       %2d.%03d A\n", g_iin / 1000, g_iin % 1000);
			g_log("12V0 load:       %2d.%03d A\n", g_iout / 1000, g_iout % 1000);

			nextHealthPrint = 15;
		}
		nextHealthPrint --;
	}
}

/**
	@brief Requests more sensor data from the IBC

	@return true if sensor values are updated
 */
bool PollIBCSensors()
{
	static IBCRegisterReader regreader;
	static TempSensorReader tempreader;

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

		//end of loop, wrap around
		default:
			state = 0;
			return true;
	}

	return false;
}

void PowerOn()
{
	g_log("Turning power on\n");
	LogIndenter li(g_log);

	//12V ramp rate is slew rate controlled to about 2 kV/sec, so should take 0.5 ms to come up
	//Give it 5 ms to be safe (plus extra delay from UART messages)
	//(we don't have any sensing on this rail so we have to just hope it came up)
	g_log("Enabling 12V rail\n");
	g_12v0_en = 1;
	g_logTimer.Sleep(50);

	//no pgood signal, TODO poll ADCs

	/*
	//TODO: poll the 12V rail via our ADC and measure it to verify it's good
	auto vin = Get12VRailVoltage();
	g_log("Measured 12V0 rail voltage: %d.%03d V\n", vin/1000, vin % 1000);
	if(vin < 11000)
	{
		PanicShutdown();

		g_log(Logger::ERROR, "12V supply failed to come up\n");

		while(1)
		{}
	}
	*/

	//Turn on other rails in sequence (VCCINT - VCCAUX - VCCO)
	StartRail(g_1v0_en, g_1v0_pgood, 75, "1V0");
	StartRail(g_1v8_en, g_1v8_pgood, 75, "1V8");
	StartRail(g_3v3_en, g_3v3_pgood, 75, "3V3");

	//1V2 for the PHY can go on whenever (TODO check sequencing vs 3V3)
	StartRail(g_1v2_en, g_1v2_pgood, 75, "1V2");

	//Start the FPGA
	g_log("Releasing FPGA reset\n");
	g_fpgaResetN = 1;
	g_fpgaInitN = 1;
	g_pgoodLED = 1;
}

/**
	@brief Shuts down all rails in reverse order but without any added sequencing delays
 */
void PanicShutdown()
{
	//active low for now
	g_1v0_en = 0;
	g_1v2_en = 0;
	g_1v8_en = 0;
	g_3v3_en = 0;
	g_12v0_en = 0;

	g_mcuResetN = 0;

	//set LEDs to fault state
	g_faultLED = 1;
	g_pgoodLED = 0;
	g_sysokLED = 0;
}

/**
	@brief Turns on a single power rail, checking for failure
 */
void StartRail(GPIOPin& en, GPIOPin& pgood, uint32_t timeout, const char* name)
{
	g_log("Turning on %s\n", name);

	en = 1;
	for(uint32_t i=0; i<timeout; i++)
	{
		if(pgood)
			return;
		g_logTimer.Sleep(1);
	}
	if(!pgood)
	{
		PanicShutdown();

		g_log(Logger::ERROR, "Rail %s failed to come up\n", name);

		while(1)
		{}
	}
}
