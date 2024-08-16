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
#include <supervisor/supervisor-common.h>
#include <bootloader/bootloader-common.h>
#include <bootloader/BootloaderAPI.h>
#include "hwinit.h"
#include <peripheral/Power.h>

void InitSPI();
void InitADC();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common global hardware config used by both bootloader and application

//UART console
//USART1 is on APB1 (80 MHz), so we need a divisor of 694.44, round to 694
UART<16, 256> g_uart(&USART1, 694);

//APB1 is 80 MHz
//Divide down to get 10 kHz ticks (note TIM2 is double rate)
Timer g_logTimer(&TIM2, Timer::FEATURE_ADVANCED, 16000);

//SPI bus to the main MCU
SPI<64, 64> g_spi(&SPI1, true, 2, false);
GPIOPin* g_spiCS = nullptr;

//I2C1 defaults to running of APB clock (80 MHz)
//Prescale by 4 to get 20 MHz
//Divide by 200 after that to get 100 kHz
I2C g_i2c(&I2C1, 4, 200);

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
		1,	//APB1 at 80 MHz
		1);	//APB2 at 80 MHz

	//Select ADC clock as sysclk
	RCC.CCIPR |= 0x3000'0000;
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
	//Bring up the IBC before powering up the rest of the system
	InitGPIOs();
	Super_InitI2C();
	Super_InitIBC();
	InitADC();
	InitSPI();

	App_Init();
}

void InitADC()
{
	g_log("Initializing ADC\n");
	LogIndenter li(g_log);

	//Run ADC at sysclk/10 (10 MHz)
	static ADC adc(&_ADC, &_ADC.chans[0], 10);
	g_adc = &adc;
	g_logTimer.Sleep(20);

	//Set up sampling time. Need minimum 5us to accurately read temperature
	//With ADC clock of 8 MHz = 125 ns per cycle this is 40 cycles
	//Max 8 us / 64 clocks for input channels
	//47.5 clocks fits both requirements, use it for everything
	int tsample = 95;
	for(int i=0; i <= 18; i++)
		adc.SetSampleTime(tsample, i);
}

void InitSPI()
{
	g_log("Initializing management SPI bus\n");

	//Set up GPIOs for management bus
	static GPIOPin mgmt_sck(&GPIOA, 5, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 5);
	static GPIOPin mgmt_mosi(&GPIOA, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 5);
	static GPIOPin mgmt_cs_n(&GPIOA, 4, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 5);
	static GPIOPin mgmt_miso(&GPIOA, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 5);

	//Save the CS# pin
	g_spiCS = &mgmt_cs_n;

	//Set up IRQ6 for SPI CS# (PA4) change
	RCCHelper::EnableSyscfg();
	NVIC_EnableIRQ(10);
	EXTI::SetExtInterruptMux(4, EXTI::PORT_A);
	EXTI::EnableChannel(4);
	EXTI::EnableFallingEdgeTrigger(4);

	//Set up IRQ35 as SPI1 interrupt
	NVIC_EnableIRQ(35);
	g_spi.EnableRxInterrupt();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GPIOs for all of the rail enables

void InitGPIOs()
{
	g_log("Initializing GPIOs\n");

	//Enable pullups on all PGOOD lines
	g_1v0_pgood.SetPullMode(GPIOPin::PULL_UP);
	g_1v2_pgood.SetPullMode(GPIOPin::PULL_UP);
	g_1v8_pgood.SetPullMode(GPIOPin::PULL_UP);
	g_3v3_pgood.SetPullMode(GPIOPin::PULL_UP);

	//turn off all LEDs
	g_pgoodLED = 0;
	g_faultLED = 0;
	g_sysokLED = 0;

	//Set up GPIOs for I2C bus
	static GPIOPin i2c_scl(&GPIOB, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
	static GPIOPin i2c_sda(&GPIOB, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
}
