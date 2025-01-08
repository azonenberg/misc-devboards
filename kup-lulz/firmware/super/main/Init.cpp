/***********************************************************************************************************************
*                                                                                                                      *
* misc-devboards                                                                                                       *
*                                                                                                                      *
* Copyright (c) 2023-2025 Andrew D. Zonenberg and contributors                                                         *
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
#include "KupLulzSuperSPIServer.h"
#include "LEDTask.h"
#include "ButtonTask.h"
#include <math.h>
#include <peripheral/ITM.h>
#include <peripheral/DWT.h>

//TODO: fix this path somehow?
#include "../../../../common-ibc/firmware/main/regids.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Power rail descriptors

//12V ramp rate is slew rate controlled to about 2 kV/sec, so should take 0.5 ms to come up
//Give it 5 ms to be safe (plus extra delay from UART messages) and check with the ADC
/*GPIOPin g_12v0_en(&GPIOB, 5, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
RailDescriptor12V0 g_12v0("12V0", g_12v0_en, g_logTimer, 50);*/

GPIOPin g_vccint_en(&GPIOC, 13, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_vccint_pgood(&GPIOB, 13, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
//RailDescriptorWithEnableAndPGood g_vccint("VCCINT", g_vccint_en, g_vccint_pgood, g_logTimer, 75);
RailDescriptorWithEnable g_vccint("VCCINT", g_vccint_en, g_logTimer, 75);

GPIOPin g_1v8_en(&GPIOC, 15, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_1v8_pgood(&GPIOC, 14, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_1v8("1V8", g_1v8_en, g_1v8_pgood, g_logTimer, 75);

GPIOPin g_gty_vcc_en(&GPIOA, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_gty_vcc_pgood(&GPIOB, 0, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_gty_vcc("GTY_VCC", g_gty_vcc_en, g_gty_vcc_pgood, g_logTimer, 75);

GPIOPin g_gty_vtt_en(&GPIOB, 14, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_gty_vtt_pgood(&GPIOB, 15, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_gty_vtt("GTY_VTT", g_gty_vtt_en, g_gty_vtt_pgood, g_logTimer, 75);

GPIOPin g_gty_vccaux_en(&GPIOA, 11, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_gty_vccaux_pgood(&GPIOA, 8, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithActiveLowEnableAndPGood g_gty_vccaux("GTY_VCCAUX", g_gty_vccaux_en, g_gty_vccaux_pgood, g_logTimer, 75);

GPIOPin g_3v3_en(&GPIOA, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
GPIOPin g_3v3_pgood(&GPIOA, 1, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndPGood g_3v3("3V3", g_3v3_en, g_3v3_pgood, g_logTimer, 75);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Power rail sequence

etl::vector g_powerSequence
{
	//12V0 has to come up first or we can't do anything
	//DERP: we don't actually have 12V0_EN wired to the supervisor!!!
	//(RailDescriptor*) g_12v0,

	//VCCINT - VCCAUX - VCCO for the FPGA
	//GTY_VCC - GTY_VTT
	(RailDescriptor*)&g_vccint,
	&g_1v8,
	&g_gty_vcc,
	&g_gty_vtt,

	&g_3v3,

	//No sequencing requirement for GTY_VCCAUX directly
	//but it's regulated from 3V3 so that has to come up first
	&g_gty_vccaux
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Reset descriptors


//Active low edge triggered reset
GPIOPin g_fpgaResetN(&GPIOB, 12, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);
ActiveLowResetDescriptor g_fpgaResetDescriptor(g_fpgaResetN, "FPGA PROG");

//Active low level triggered delay-boot flag
//Use this as the "FPGA is done booting" indicator
GPIOPin g_fpgaInitN(&GPIOB, 2, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);
GPIOPin g_fpgaDone(&GPIOB, 10, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
ActiveLowResetDescriptorWithActiveHighDone g_fpgaInitDescriptor(g_fpgaInitN, g_fpgaDone, "FPGA INIT");

//MCU reset comes at the end
GPIOPin g_mcuResetN(&GPIOB, 9, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
ActiveLowResetDescriptor g_mcuResetDescriptor(g_mcuResetN, "MCU");

etl::vector g_resetSequence
{
	//First boot the FPGA
	(ResetDescriptor*)&g_fpgaResetDescriptor,	//need to cast at least one entry to base class
												//for proper template deduction
	&g_fpgaInitDescriptor,

	//then release the MCU
	&g_mcuResetDescriptor
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Task tables

etl::vector<Task*, MAX_TASKS>  g_tasks;
etl::vector<TimerTask*, MAX_TIMER_TASKS>  g_timerTasks;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// The top level supervisor controller

KupLulzPowerResetSupervisor g_super(g_powerSequence, g_resetSequence);

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

	//Start tracing
	#ifdef _DEBUG
		ITM::Enable();
		DWT::EnablePCSampling(DWT::PC_SAMPLE_SLOW);
		ITM::EnableDwtForwarding();
	#endif

	static LEDTask ledTask;
	static ButtonTask buttonTask;
	static KupLulzSuperSPIServer spiserver(g_spi);

	g_tasks.push_back(&ledTask);
	g_tasks.push_back(&buttonTask);
	g_tasks.push_back(&g_super);
	g_tasks.push_back(&spiserver);

	g_timerTasks.push_back(&ledTask);

	//Add pullups for rail descriptors
	//g_vccint_pgood.SetPullMode(

	//Turn on immediately, don't wait for a button press
	g_super.PowerOn();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main loop
