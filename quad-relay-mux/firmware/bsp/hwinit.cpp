/***********************************************************************************************************************
*                                                                                                                      *
* misc-devboards                                                                                                       *
*                                                                                                                      *
* Copyright (c) 2023-2026 Andrew D. Zonenberg and contributors                                                         *
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
#include "hwinit.h"
#include <peripheral/Power.h>

void InitI2C();
void InitRelays();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common global hardware config used by both bootloader and application

//UART console

//USART1 is on APB1 (80 MHz), so we need a divisor of 694.44, round to 694
UART<16, 256> g_scpiUART(&USART1, 694);

//USART2 is on APB1 (80 MHz), so we need a divisor of 694.44, round to 694
UART<16, 256> g_uart(&USART2, 694);

//I2C1 defaults to running of APB clock (80 MHz)
//Prescale by 4 to get 20 MHz
//Divide by 50 after that to get 400 kHz
I2C g_i2c(&I2C1, 4, 50);

///@brief Our firmware version string
char g_version[20] = {0};

//APB1 is 80 MHz
//Divide down to get 10 kHz ticks (note TIM2 is double rate)
Timer g_logTimer(&TIM2, Timer::FEATURE_ADVANCED, 16000);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// I2C IO expander

TCA6424A g_expander(&g_i2c, 0x44);

GPIOPin g_expanderReset(&GPIOC, 14, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GPIOs on expander

TCA6424A_GPIO g_mux0_leda(g_expander, 22);
TCA6424A_GPIO g_mux0_ledb(g_expander, 23);

TCA6424A_GPIO g_mux1_leda(g_expander, 20);
TCA6424A_GPIO g_mux1_ledb(g_expander, 21);

TCA6424A_GPIO g_mux2_leda(g_expander, 18);
TCA6424A_GPIO g_mux2_ledb(g_expander, 19);

TCA6424A_GPIO g_mux3_leda(g_expander, 16);
TCA6424A_GPIO g_mux3_ledb(g_expander, 17);

TCA6424A_GPIO* g_muxled_a[4] = { &g_mux0_leda, &g_mux1_leda, &g_mux2_leda, &g_mux3_leda };
TCA6424A_GPIO* g_muxled_b[4] = { &g_mux0_ledb, &g_mux1_ledb, &g_mux2_ledb, &g_mux3_ledb };

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Relay control lines

GPIOPin g_relay0_a(&GPIOA, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);
GPIOPin g_relay0_b(&GPIOA, 1, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);

GPIOPin g_relay1_a(&GPIOA, 4, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);
GPIOPin g_relay1_b(&GPIOA, 5, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);

GPIOPin g_relay2_a(&GPIOA, 6, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);
GPIOPin g_relay2_b(&GPIOA, 7, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);

GPIOPin g_relay3_a(&GPIOB, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);
GPIOPin g_relay3_b(&GPIOB, 1, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);

GPIOPin* g_relay_a[4] = { &g_relay0_a, &g_relay1_a, &g_relay2_a, &g_relay3_a };
GPIOPin* g_relay_b[4] = { &g_relay0_b, &g_relay1_b, &g_relay2_b, &g_relay3_b };

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

void BSP_InitUART()
{
	//Initialize the UART for local console: 115.2 Kbps
	//TODO: nice interface for enabling UART interrupts
	GPIOPin uart_tx(&GPIOA, 2, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);
	GPIOPin uart_rx(&GPIOA, 3, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);

	//Same for SCPI
	GPIOPin scpi_uart_tx(&GPIOA, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);
	GPIOPin scpi_uart_rx(&GPIOA, 10, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);

	g_logTimer.Sleep(10);	//wait for UART pins to be high long enough to remove any glitches during powerup

	//Enable the UART interrupts
	NVIC_EnableIRQ(37);
	NVIC_EnableIRQ(38);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common features shared by both application and bootloader

void BSP_Init()
{
	InitGPIOs();
	InitI2C();
	InitRelays();

	App_Init();
}

void BSP_InitMemory()
{
}

void BSP_MainLoopIteration()
{
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GPIOs for all of the rail enables

void InitGPIOs()
{
	g_log("Initializing GPIOs\n");

	//Set up GPIOs for I2C bus
	static GPIOPin i2c_scl(&GPIOB, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
	static GPIOPin i2c_sda(&GPIOB, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);

	//Release IO expander reset
	g_expanderReset = 0;
	g_logTimer.Sleep(20);
	g_expanderReset = 1;
	g_logTimer.Sleep(20);

	//Clear relays to the off state
	for(size_t i=0; i<4; i++)
	{
		*(g_relay_a[i]) = 0;
		*(g_relay_b[i]) = 0;
	}
}

void InitI2C()
{
	g_log("Initializing I2C\n");

	//Set all LED channels as output
	for(size_t i=0; i<4; i++)
	{
		g_muxled_a[i]->SetDirection(false);
		(*g_muxled_a[i]) = 1;

		g_muxled_b[i]->SetDirection(false);
		(*g_muxled_b[i]) = 0;
	}

	g_log("done\n");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Relay configuration

void InitRelays()
{
	for(size_t i=0; i<4; i++)
		SetRelay(i, 0);
}

void SetRelay(size_t chan, bool dir)
{
	//Turn it on
	if(!dir)
		*g_relay_a[chan] = 1;
	else
		*g_relay_b[chan] = 1;

	//Relays spec max 5ms operating time
	//Give them 10ms of power to be conservative
	g_logTimer.Sleep(100);

	//Turn it off
	*g_relay_a[chan] = 0;
	*g_relay_b[chan] = 0;
}
