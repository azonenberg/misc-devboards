/***********************************************************************************************************************
*                                                                                                                      *
* baseT1 media converter                                                                                               *
*                                                                                                                      *
* Copyright (c) 2024 Andrew D. Zonenberg and contributors                                                              *
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

#include "converter.h"
#include "BitbangedMDIOInterface.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

BitbangedMDIOInterface::BitbangedMDIOInterface(GPIOPin& clk, GPIOPin& io)
	: m_clk(clk)
	, m_io(io)
{
	m_io.SetMode(GPIOPin::MODE_INPUT, 0, false);
	m_clk = 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Bitbanging stuff

void BitbangedMDIOInterface::ClockCycle()
{
	asm("nop");
	asm("nop");
	m_clk = 1;
	asm("nop");
	asm("nop");
	m_clk = 0;
}

void BitbangedMDIOInterface::SendAddress(uint8_t addr)
{
	m_io = static_cast<bool>(addr & 0x10);
	ClockCycle();
	m_io = static_cast<bool>(addr & 0x08);
	ClockCycle();
	m_io = static_cast<bool>(addr & 0x04);
	ClockCycle();
	m_io = static_cast<bool>(addr & 0x02);
	ClockCycle();
	m_io = static_cast<bool>(addr & 0x01);
	ClockCycle();

}

uint16_t BitbangedMDIOInterface::Read(uint8_t phyaddr, uint8_t regaddr)
{
	//Send 32 clock edges with MDIO floating high as the preamble
	for(int i=0; i<8; i++)
	{
		ClockCycle();
		ClockCycle();
		ClockCycle();
		ClockCycle();
	}

	//Start driving the bus
	m_io.SetMode(GPIOPin::MODE_OUTPUT, 0, false);

	//Send start-of-frame: 0 then 1
	m_io = 0;
	ClockCycle();
	m_io = 1;
	ClockCycle();

	//Send read opcode
	m_io = 1;
	ClockCycle();
	m_io = 0;
	ClockCycle();

	//Send addresses
	SendAddress(phyaddr);
	SendAddress(regaddr);

	//Tristate MDIO and send two clocks for bus turnaround delay
	m_io.SetMode(GPIOPin::MODE_INPUT, 0, false);
	ClockCycle();
	ClockCycle();

	//Read the reply
	uint16_t ret = 0;
	for(int i=0; i<16; i++)
	{
		ret <<= 1;
		if(m_io)
			ret |= 1;
		ClockCycle();
	}

	return ret;
}

void BitbangedMDIOInterface::Write(uint8_t phyaddr, uint8_t regaddr, uint16_t regval)
{
	//Send 32 clock edges with MDIO floating high as the preamble
	for(int i=0; i<8; i++)
	{
		ClockCycle();
		ClockCycle();
		ClockCycle();
		ClockCycle();
	}

	//Start driving the bus
	m_io.SetMode(GPIOPin::MODE_OUTPUT, 0, false);

	//Send start-of-frame: 0 then 1
	m_io = 0;
	ClockCycle();
	m_io = 1;
	ClockCycle();

	//Send write opcode
	m_io = 0;
	ClockCycle();
	m_io = 1;
	ClockCycle();

	//Send addresses
	SendAddress(phyaddr);
	SendAddress(regaddr);

	//Send constant 2'b10 during turnaround slot since we're not actually turning the bus around
	m_io = 1;
	ClockCycle();
	m_io = 0;
	ClockCycle();

	//Send the message
	for(int i=0; i<16; i++)
	{
		if(regval & 0x8000)
			m_io = 1;
		else
			m_io = 0;
		regval <<= 1;

		ClockCycle();
	}

	//Tristate MDIO and send a few trailing clocks for bus turnaround delay
	m_io.SetMode(GPIOPin::MODE_INPUT, 0, false);
	ClockCycle();
	ClockCycle();
}
