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

//UART console
UART* g_uart = NULL;
Logger g_log;

Timer* g_logTimer;

void InitClocks();
void InitUART();
void InitLog();
void InitPower();
void DetectHardware();
void InitLEDs();

void InitSPEPHY();
void InitBaseTPHY();

#define PHY_ADDR_SPE 0x00
#define PHY_ADDR_BASET 0x00

GPIOPin* g_pwren1v0 = nullptr;
GPIOPin* g_led[4] = {0};

BitbangedMDIOInterface* g_basetMDIO = nullptr;
BitbangedMDIOInterface* g_speMDIO = nullptr;

bool g_speedIsGig = false;

int main()
{
	//Copy .data from flash to SRAM (for some reason the default newlib startup won't do this??)
	memcpy(&__data_start, &__data_romstart, &__data_end - &__data_start + 1);

	//Hardware setup
	InitClocks();
	InitUART();
	InitLog();
	DetectHardware();

	//Hold PHYs in reset during boot
	GPIOPin baset_rst_n(&GPIOA, 5, GPIOPin::MODE_OUTPUT);
	GPIOPin spe_rst_n(&GPIOA, 8, GPIOPin::MODE_OUTPUT);
	baset_rst_n = 0;
	spe_rst_n = 0;

	//Turn on all switchable power rails to start
	//The DP83TC814 (100mbit) doesn't need the 1.0V rail, but we won't know which PHY we have until we ask
	//during PHY bringup, which requires that it be powered!
	InitPower();

	//Set up the GPIO LEDs
	InitLEDs();

	//For now, ignore PHY interrupts

	//Clear PHY reset 10ms after power good
	GPIOPin pgood_in(&GPIOA, 1, GPIOPin::MODE_INPUT);
	while(!pgood_in)
	{}
	g_logTimer->Sleep(100);
	g_log("Power good, releasing PHY reset\n");
	baset_rst_n = 1;
	spe_rst_n = 1;

	//Wait another 100us after releasing reset before programming
	g_logTimer->Sleep(1);

	//Initialize the PHYs.
	//Do the SPE one first as the configuration of the baseT phy depends on which one we have loaded
	InitSPEPHY();
	InitBaseTPHY();

	//Poll link state
	bool baset_linkUp = false;
	bool spe_linkUp = false;
	while(1)
	{
		//Poll baseT link status
		auto status = g_basetMDIO->Read(PHY_ADDR_BASET, 0x01);
		bool up = (status & 0x4) == 0x4;
		if(up && !baset_linkUp)
			g_log("Base-T link is up\n");
		if(!up && baset_linkUp)
			g_log("Base-T link is down\n");
		baset_linkUp = up;

		//Poll SPE link status
		status = g_speMDIO->Read(PHY_ADDR_SPE, 0x01);
		up = (status & 0x4) == 0x4;
		if(up && !spe_linkUp)
			g_log("SPE link is up\n");
		if(!up && spe_linkUp)
			g_log("SPE link is down\n");
		spe_linkUp = up;
	}

	return 0;
}

void InitClocks()
{
	//Initialize the PLL
	//CPU clock = AHB clock = APB clock = 48 MHz
	RCCHelper::InitializePLLFromInternalOscillator(2, 12, 1, 1);
}

void InitUART()
{
	//Initialize the UART
	static GPIOPin uart_tx(&GPIOA, 2,	GPIOPin::MODE_PERIPHERAL, 1);
	static GPIOPin uart_rx(&GPIOA, 3, GPIOPin::MODE_PERIPHERAL, 1);
	static UART uart(&USART1, &USART1, 417);
	g_uart = &uart;

	//Enable RXNE interrupt vector (IRQ27)
	//TODO: better contants here
	volatile uint32_t* NVIC_ISER0 = (volatile uint32_t*)(0xe000e100);
	*NVIC_ISER0 = 0x8000000;

	//Clear screen and move cursor to X0Y0
	uart.Printf("\x1b[2J\x1b[0;0H");
}

void InitLog()
{
	//APB1 is 48 MHz
	//Divide down to get 10 kHz ticks
	static Timer logtim(&TIM1, Timer::FEATURE_ADVANCED, 4800);
	g_logTimer = &logtim;

	g_log.Initialize(g_uart, &logtim);
	g_log("UART logging ready\n");
}

void InitPower()
{
	g_log("Turning on 1.0 and 1.2V power rails\n");

	static GPIOPin pwren_1v0(&GPIOA, 4, GPIOPin::MODE_OUTPUT);
	static GPIOPin pwren_1v2(&GPIOB, 7, GPIOPin::MODE_OUTPUT);

	pwren_1v0 = 1;
	pwren_1v2 = 1;

	g_pwren1v0 = &pwren_1v0;
}

void InitLEDs()
{
	GPIOPin gpio_led0(&GPIOA, 15, GPIOPin::MODE_OUTPUT);
	GPIOPin gpio_led1(&GPIOB, 3, GPIOPin::MODE_OUTPUT);
	GPIOPin gpio_led2(&GPIOB, 4, GPIOPin::MODE_OUTPUT);
	GPIOPin gpio_led3(&GPIOB, 5, GPIOPin::MODE_OUTPUT);
	gpio_led0 = 0;
	gpio_led1 = 0;
	gpio_led2 = 0;
	gpio_led3 = 0;

	g_led[0] = &gpio_led0;
	g_led[1] = &gpio_led1;
	g_led[2] = &gpio_led2;
	g_led[3] = &gpio_led3;
}

void DetectHardware()
{
	g_log("Identifying hardware\n");
	LogIndenter li(g_log);

	uint16_t rev = DBGMCU.IDCODE >> 16;
	uint16_t device = DBGMCU.IDCODE & 0xfff;
	g_log("Device = 0x%04x %04x\n", device, rev);

	if(device == 0x444)
	{
		//Look up the stepping number
		const char* srev = NULL;
		switch(rev)
		{
			case 0x1000:
				srev = "A";
				break;
			default:
				srev = "(unknown)";
		}

		g_log("STM32F03x stepping %s\n", srev);
		g_log("4 kB total SRAM, 20 byte backup SRAM\n");
		g_log("%d kB Flash\n", F_ID);
		int waferX =
			( (U_ID[0] >> 16) & 0xf ) +
			( (U_ID[0] >> 20) & 0xf )*10 +
			( (U_ID[0] >> 24) & 0xf )*100 +
			( (U_ID[0] >> 28) & 0xf )*100;
		int waferY =
			( (U_ID[0] >> 0) & 0xf ) +
			( (U_ID[0] >> 4) & 0xf )*10 +
			( (U_ID[0] >> 8) & 0xf )*100 +
			( (U_ID[0] >> 12) & 0xf )*100;

		uint8_t waferNum = U_ID[1] & 0xff;
		char waferLot[8] =
		{
			static_cast<char>((U_ID[2] >> 24) & 0xff),
			static_cast<char>((U_ID[2] >> 16) & 0xff),
			static_cast<char>((U_ID[2] >> 8) & 0xff),
			static_cast<char>((U_ID[2] >> 0) & 0xff),
			static_cast<char>((U_ID[1] >> 24) & 0xff),
			static_cast<char>((U_ID[1] >> 16) & 0xff),
			static_cast<char>((U_ID[1] >> 8) & 0xff),
			'\0'
		};
		g_log("Lot %s, wafer %d, die (%d, %d)\n", waferLot, waferNum, waferX, waferY);
	}
	else
		g_log(Logger::WARNING, "Unknown device (0x%06x)\n", device);
}

void InitSPEPHY()
{
	g_log("Initializing SPE PHY\n");
	LogIndenter li(g_log);

	static GPIOPin mdc(&GPIOA, 9, GPIOPin::MODE_OUTPUT);
	static GPIOPin mdio(&GPIOA, 10, GPIOPin::MODE_INPUT);

	//Make the MDIO interface
	static BitbangedMDIOInterface iface(mdc, mdio);
	g_speMDIO = &iface;

	//Read and validate PHY ID
	auto id1 = iface.Read(PHY_ADDR_SPE, 0x02);
	auto id2 = iface.Read(PHY_ADDR_SPE, 0x03);
	uint32_t oui = (id2 >> 10) | (id1 << 6);
	if(oui != 0x80028)
	{
		g_log(Logger::ERROR, "Invalid PHY vendor OUI: %06x\n", oui);
		while(1)
		{}
	}

	//PHY model number
	auto model = (id2 >> 4) & 0x3f;
	auto stepping = (id2 & 0xf);
	if(model == 0x26)
	{
		g_log("Detected DP83TC814 stepping %d (100base-T1)\n", stepping);
		g_log("Turning off 1.0V power rail as it's not needed for this PHY\n");
		*g_pwren1v0 = 0;
		g_speedIsGig = false;
	}
	else
		g_log(Logger::WARNING, "Unknown TI PHY %02x stepping %d\n", stepping);

	//TODO: do other init?
}

void InitBaseTPHY()
{
	g_log("Initializing BaseT PHY\n");
	LogIndenter li(g_log);

	static GPIOPin mdc(&GPIOB, 0, GPIOPin::MODE_OUTPUT);
	static GPIOPin mdio(&GPIOA, 7, GPIOPin::MODE_INPUT);

	//Make the MDIO interface
	static BitbangedMDIOInterface iface(mdc, mdio);
	g_basetMDIO = &iface;

	//Read and validate PHY ID
	auto id1 = iface.Read(PHY_ADDR_BASET, 0x02);
	auto id2 = iface.Read(PHY_ADDR_BASET, 0x03);
	uint32_t oui = (id2 >> 10) | (id1 << 6);
	if(oui != 0x885)
	{
		g_log(Logger::ERROR, "Invalid PHY vendor OUI: %06x\n", oui);
		while(1)
		{}
	}

	//PHY model number
	auto model = (id2 >> 4) & 0x3f;
	auto stepping = (id2 & 0xf);
	if(model == 0x22)
		g_log("Detected KSZ9031RNX stepping %d \n", stepping);
	else
		g_log(Logger::WARNING, "Unknown Kendin PHY %02x stepping %d\n", stepping);

	//If we have a 100baseT1 PHY, advertise only 100baseTX on the baseT side
	if(!g_speedIsGig)
	{
		g_log("Advertising only 100baseTX mode\n");

		//1000baseT control: advertise not 1000baseT half or full duplex capable
		iface.Write(PHY_ADDR_BASET, 0x9, 0x0000);

		//Base advertisement: 100/full only
		iface.Write(PHY_ADDR_BASET, 0x4, 0x0101);

		//Restart negotiation
		iface.Write(PHY_ADDR_BASET, 0x0, 0x1300);
	}

	//If we have a 1000baseT1 PHY, advertise only 1000baseT1 on the baseT side
	else
	{
		//TODO
	}
}
