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

#ifndef LEDTask_h
#define LEDTask_h

#include <core/TimerTask.h>

//helpers for cycle accurate timing
#define NOP asm("nop");
#define NOP2 NOP NOP
#define NOP3 NOP NOP NOP
#define NOP4 NOP NOP NOP NOP
#define NOP5 NOP NOP NOP NOP NOP
#define NOP6 NOP5 NOP
#define NOP7 NOP5 NOP NOP
#define NOP10 NOP5 NOP5
#define NOP19 NOP10 NOP5 NOP4
#define NOP21 NOP10 NOP10 NOP
#define NOP22 NOP10 NOP10 NOP2
#define NOP23 NOP10 NOP10 NOP3
#define NOP24 NOP10 NOP10 NOP4
#define NOP25 NOP10 NOP10 NOP5
#define NOP26 NOP10 NOP10 NOP NOP NOP NOP NOP NOP

class LEDTask : public TimerTask
{
public:
	LEDTask();

protected:
	virtual void OnTimer();

	void OnTimer_ModeRandom();

	GPIOPin m_green0;
	GPIOPin m_green1;
	GPIOPin m_green2;
	GPIOPin m_green3;
	GPIOPin m_green4;

	GPIOPin m_red0;
	GPIOPin m_red1;
	GPIOPin m_red2;
	GPIOPin m_red3;
	GPIOPin m_red4;

	GPIOPin m_ledCtrl;

	void RefreshRGB(uint32_t* colors);
	void RefreshRedGreen();
	void SendBitbangRGB(uint32_t rgb);

	//LED bitbang
	void __attribute__((always_inline)) SetLEDCtrlHigh()
	{ GPIOA.BSRR = 0x400; }

	void __attribute__((always_inline)) SetLEDCtrlLow()
	{ GPIOA.BSRR = 0x4000000; };

	///@brief send logic 1
	void __attribute__((always_inline)) SendBitbang1()
	{
		SetLEDCtrlHigh();
		NOP22
		SetLEDCtrlLow();
		NOP4
	}

	///@brief send logic 0
	void __attribute__((always_inline)) SendBitbang0()
	{
		SetLEDCtrlHigh();
		NOP6
		SetLEDCtrlLow();
		NOP19
	}

	void __attribute__((always_inline)) SendBitbangBit(bool b)
	{
		if(b)
			SendBitbang1();
		else
			SendBitbang0();
	}

	int m_step;

	//LFSR for random generation
	uint32_t m_prbs;

	bool RandomBit();
	uint32_t RandomColor();

	//Current pattern state
	uint8_t m_redPattern;
	uint8_t m_greenPattern;
	uint32_t m_rgbColors[8];
};

#endif


