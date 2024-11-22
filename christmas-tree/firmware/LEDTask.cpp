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
	, m_prbs(1)
	, m_redPattern(0)
	, m_greenPattern(0)
{
	//Reset everything
	m_ledCtrl = 0;
	g_logTimer.Sleep(5);

	//Turn off all the LEDs
	uint32_t colors[8] = {0};
	RefreshRGB(colors);
	RefreshRedGreen();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Random number generation

///@brief Generate a random bit using the PRBS-15 polynomial
bool LEDTask::RandomBit()
{
	uint32_t next = ( (m_prbs >> 14) ^ (m_prbs >> 13) ) & 1;
	m_prbs = (m_prbs << 1) | next;
	return (bool) next;
}

uint32_t LEDTask::RandomColor()
{
	//8 random colors
	static const uint32_t colors[]=
	{
		0x200000,
		0x201000,
		0x202000,
		0x002000,
		0x002020,
		0x200020,
		0x100020,
		0x202020
	};

	uint8_t index =
		(RandomBit() << 2) |
		(RandomBit() << 1) |
		RandomBit();

	return colors[index];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helpers for pushing state out to the LEDs

void LEDTask::RefreshRedGreen()
{
	m_green0 = (m_greenPattern & 1) == 1;
	m_green1 = (m_greenPattern & 2) == 2;
	m_green2 = (m_greenPattern & 4) == 4;
	m_green3 = (m_greenPattern & 8) == 8;
	m_green4 = (m_greenPattern & 16) == 16;

	m_red0 = (m_redPattern & 1) == 1;
	m_red1 = (m_redPattern & 2) == 2;
	m_red2 = (m_redPattern & 4) == 4;
	m_red3 = (m_redPattern & 8) == 8;
	m_red4 = (m_redPattern & 16) == 16;
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level pattern control

void LEDTask::OnTimer()
{
	/*
	//Pattern step
	m_step ++;
	if(m_step > 16)
		m_step = 0;*/

	//Figure out new color
	OnTimer_ModeRandom();

	//Update the LEDs
	RefreshRedGreen();
	RefreshRGB(m_rgbColors);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Random mode

void LEDTask::OnTimer_ModeRandom()
{
	//Red and green: random flashing
	m_redPattern =
		(RandomBit() << 4) |
		(RandomBit() << 3) |
		(RandomBit() << 2) |
		(RandomBit() << 1) |
		RandomBit();
	m_greenPattern =
		(RandomBit() << 4) |
		(RandomBit() << 3) |
		(RandomBit() << 2) |
		(RandomBit() << 1) |
		RandomBit();

	//RGB: random colors
	for(int i=0; i<8; i++)
		m_rgbColors[i] = RandomColor();
}
