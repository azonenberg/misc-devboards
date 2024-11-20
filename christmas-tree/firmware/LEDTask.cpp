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

LEDTask::LEDTask()
	: TimerTask(0, 2500)	//250ms per tick = 2 Hz iterations
	, m_green0(&GPIOA, 11, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_green1(&GPIOB, 7, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_green2(&GPIOB, 1, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_green3(&GPIOA, 15, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_green4(&GPIOA, 12, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_red0(&GPIOB, 8, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_red1(&GPIOB, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_red2(&GPIOB, 3, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_red3(&GPIOB, 2, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_red4(&GPIOA, 4, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
	, m_ledCtrl(&GPIOA, 10, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0)
{
	m_green0 = 1;
	m_green1 = 1;
	m_green2 = 1;
	m_green3 = 1;
	m_green4 = 1;

	m_red0 = 1;
	m_red1 = 1;
	m_red2 = 1;
	m_red3 = 1;
	m_red4 = 1;

	//Try to program some LEDs
	/*
		All clock domains are 32 MHz (31.25 ns) period

		To send data:
		* 50us or more of logic 0
		* 1 bit: 900ns +/- 80 high, 300 +/- 80 low
		* 0 bit: 300ns +/- 80 high, 900 +/- 80 low

		300 ns = 9.6 clocks
		900ns = 28.8 clocks

		Rounded: 10 and 29

		1.2 to 3.6 us delay between 24-bit data bursts

		Converted
	 */

	//Reset
	m_ledCtrl = 0;
	g_logTimer.Sleep(5);

	uint32_t colors[8] =
	{
		0x800000,
		0x000080,
		0x008000,
		0x808000,
		0x100010,
		0x001010,
		0x101010,
		0x001010
	};

	//Wait for the UART to finish printing any boot-time log messages so it doesn't mess up bitbang timing
	g_uart.Flush();
	RefreshRGB(colors);
}

//use fixed optimization level to ensure deterministic timing
#pragma GCC push_options
#pragma GCC optimize("-O3")

void LEDTask::RefreshRGB(uint32_t* colors)
{
	DisableInterrupts();
	for(int i=0; i<8; i++)
	{
		SendBitbangRGB(colors[i]);
		NOP10
	}

	EnableInterrupts();
}

void LEDTask::SendBitbangRGB(uint32_t rgb)
{
	//GPIOPin wrapper is too slow for precision bitbanging, do raw SFR accesses
	for(uint32_t mask = 0x800000; mask != 0; mask >>= 1)
		SendBitbangBit( (rgb & mask) == mask);
}
#pragma GCC pop_options

void LEDTask::OnTimer()
{
}
