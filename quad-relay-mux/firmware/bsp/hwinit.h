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

#ifndef hwinit_h
#define hwinit_h

#include <peripheral/ADC.h>
#include <peripheral/EXTI.h>
#include <peripheral/Flash.h>
#include <peripheral/GPIO.h>
#include <peripheral/I2C.h>
#include <peripheral/SPI.h>
#include <peripheral/UART.h>

#include <drivers/TCA6424A.h>

///@brief Initialize application-specific hardware stuff
extern void App_Init();

//Common ISRs used by application and bootloader
void USART1_Handler();
void USART2_Handler();

void InitGPIOs();

extern UART<16, 256> g_uart;
extern UART<16, 256> g_scpiUART;

extern char g_version[20];

extern TCA6424A g_expander;

void SetRelay(size_t chan, bool dir);

extern TCA6424A_GPIO* g_muxled_a[4];
extern TCA6424A_GPIO* g_muxled_b[4];

#endif
