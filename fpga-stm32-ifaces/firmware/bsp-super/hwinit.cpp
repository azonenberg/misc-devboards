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
	@brief	Boot-time hardware initialization
 */
#include <core/platform.h>
#include <bootloader/bootloader-common.h>
#include <bootloader/BootloaderAPI.h>
#include "hwinit.h"
#include <peripheral/Power.h>

void InitFPGASPI();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common global hardware config used by both bootloader and application

//UART console
//USART1 is on APB1 (40 MHz), so we need a divisor of 347.22, round to 347
UART<16, 256> g_uart(&USART1, 347);

//APB1 is 40 MHz
//Divide down to get 10 kHz ticks (note TIM2 is double rate)
Timer g_logTimer(&TIM2, Timer::FEATURE_ADVANCED, 8000);

//SPI bus to the FPGA
SPI<2048, 64> g_fpgaSPI(&SPI1, true, 2, false);
GPIOPin* g_fpgaSPICS = nullptr;

///@brief The battery-backed RAM used to store state across power cycles
volatile BootloaderBBRAM* g_bbram = reinterpret_cast<volatile BootloaderBBRAM*>(&_RTC.BKP[0]);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Low level init

void BSP_InitPower()
{
	Power::ConfigureLDO(RANGE_VOS1);
}

void BSP_InitClocks()
{
	//Configure the flash with wait states and prefetching before making any changes to the clock setup.
	//A bit of extra latency is fine, the CPU being faster than flash is not.
	Flash::SetConfiguration(80, RANGE_VOS1);

	RCCHelper::InitializePLLFromHSI16(
		2,	//Pre-divide by 2 (PFD frequency 8 MHz)
		20,	//VCO at 8*20 = 160 MHz
		4,	//Q divider is 40 MHz (nominal 48 but we're not using USB so this is fine)
		2,	//R divider is 80 MHz (fmax for CPU)
		1,	//no further division from SYSCLK to AHB (80 MHz)
		2,	//APB1 at 40 MHz
		2);	//APB2 at 40 MHz
}

void BSP_InitUART()
{
	//Initialize the UART for local console: 115.2 Kbps
	//TODO: nice interface for enabling UART interrupts
	GPIOPin uart_tx(&GPIOA, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);
	GPIOPin uart_rx(&GPIOA, 10, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);

	g_logTimer.Sleep(10);	//wait for UART pins to be high long enough to remove any glitches during powerup

	//Enable the UART interrupt
	NVIC_EnableIRQ(37);
}

void BSP_InitLog()
{
	//Wait 10ms to avoid resets during shutdown from destroying diagnostic output
	g_logTimer.Sleep(100);

	//Clear screen and move cursor to X0Y0 (but only in bootloader)
	#ifndef NO_CLEAR_SCREEN
	g_uart.Printf("\x1b[2J\x1b[0;0H");
	#endif

	//Start the logger
	g_log.Initialize(&g_uart, &g_logTimer);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common features shared by both application and bootloader

void BSP_Init()
{
	App_Init();
	InitFPGASPI();
}

void InitFPGASPI()
{
	/*
	g_log("Initializing FPGA SPI\n");

	//Set up GPIOs for FPGA bus
	static GPIOPin fpga_sck(&GPIOE, 13, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 5);
	static GPIOPin fpga_mosi(&GPIOE, 15, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 5);
	static GPIOPin fpga_cs_n(&GPIOB, 0, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 5);
	//DO NOT configure MISO initially since this pin doubles as JTRST
	//If we enable it, JTAG will stop working!

	//Save the CS# pin
	g_fpgaSPICS = &fpga_cs_n;

	//Set up IRQ6 for SPI CS# (PB0) change
	//Use EXTI0 as PB0 interrupt on falling edge
	//TODO: make a wrapper for this?
	RCCHelper::EnableSyscfg();
	NVIC_EnableIRQ(6);
	SYSCFG.EXTICR1 = (SYSCFG.EXTICR1 & 0xfffffff8) | 0x1;
	EXTI.IMR1 |= 1;
	EXTI.FTSR1 |= 1;

	//Set up IRQ35 as SPI1 interrupt
	NVIC_EnableIRQ(35);
	g_fpgaSPI.EnableRxInterrupt();
	*/
}
