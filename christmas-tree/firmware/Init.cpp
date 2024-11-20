/***********************************************************************************************************************
*                                                                                                                      *
* christmas-tree                                                                                                       *
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

#include "christmas-tree.h"
#include "LEDTask.h"

//UART console
//USART2 is on APB1 (32MHz), so we need a divisor of 277.77, round to 278
UART<16, 256> g_uart(&USART2, 278);

//Firmware version string
char g_version[32] = {0};

//APB1 is 32 MHz
//Divide down to get 10 kHz ticks (note TIM2 is double rate)
Timer g_logTimer(&TIMER2, Timer::FEATURE_GENERAL_PURPOSE_16BIT, 6400);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Task tables

etl::vector<Task*, MAX_TASKS>  g_tasks;
etl::vector<TimerTask*, MAX_TIMER_TASKS>  g_timerTasks;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BSP init

void BSP_InitPower()
{
	RCCHelper::Enable(&PWR);
	Power::ConfigureLDO(RANGE_VOS1);
}

void BSP_InitClocks()
{
	//Configure the flash with wait states and prefetching before making any changes to the clock setup.
	//A bit of extra latency is fine, the CPU being faster than flash is not.
	Flash::SetConfiguration(32, RANGE_VOS1);

	//Set operating frequency
	RCCHelper::InitializePLLFromHSI16(
		4,	//VCO at 16*4 = 64 MHz
		2,	//CPU frequency is 64/2 = 32 MHz (max 32)
		1,	//AHB at 32 MHz (max 32)
		1,	//APB2 at 32 MHz (max 32)
		1);	//APB1 at 32 MHz (max 32)
}

void BSP_InitLog()
{
	//Wait 10ms to avoid resets during shutdown from destroying diagnostic output
	g_logTimer.Sleep(100);

	//Clear screen and move cursor to X0Y0
	g_uart.Printf("\x1b[2J\x1b[0;0H");

	//Start the logger
	g_log.Initialize(&g_uart, &g_logTimer);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Low level init

void BSP_InitUART()
{
	//Initialize the UART for local console: 115.2 Kbps
	GPIOPin uart_tx(&GPIOA, 2, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4);
	GPIOPin uart_rx(&GPIOA, 3, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4);

	g_logTimer.Sleep(10);	//wait for UART pins to be high long enough to remove any glitches during powerup

	//Enable the UART interrupt
	NVIC_EnableIRQ(28);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main system startup

void BSP_Init()
{
	//Format version string
	StringBuffer buf(g_version, sizeof(g_version));
	static const char* buildtime = __TIME__;
	buf.Printf("%s %c%c%c%c%c%c",
		__DATE__, buildtime[0], buildtime[1], buildtime[3], buildtime[4], buildtime[6], buildtime[7]);
	g_log("Firmware version %s\n", g_version);

	static LEDTask ledTask;
	g_tasks.push_back(&ledTask);
	g_timerTasks.push_back(&ledTask);
}
