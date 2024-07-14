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

#ifndef frontpanel_h
#define frontpanel_h

#include <core/platform.h>

#include <peripheral/ADC.h>
#include <peripheral/I2C.h>

#include <embedded-utils/FIFO.h>
#include <embedded-utils/StringBuffer.h>

//#include <bootloader/BootloaderAPI.h>
#include "../bsp-super/hwinit.h"

void InitGPIOs();
void InitI2C();
void InitSPI();

extern UART<16, 256> g_uart;
extern I2C g_i2c;

//GPIOs
extern GPIOPin g_pgoodLED;
extern GPIOPin g_faultLED;
extern GPIOPin g_sysokLED;
extern GPIOPin g_12v0_en;
extern GPIOPin g_1v0_en;
extern GPIOPin g_1v0_pgood;
extern GPIOPin g_1v2_en;
extern GPIOPin g_1v2_pgood;
extern GPIOPin g_1v8_en;
extern GPIOPin g_1v8_pgood;
extern GPIOPin g_3v3_en;
extern GPIOPin g_3v3_pgood;

extern GPIOPin g_mcuResetN;
extern GPIOPin g_fpgaResetN;
extern GPIOPin g_fpgaInitN;

void PowerOn();
void StartRail(GPIOPin& en, GPIOPin& pgood, uint32_t timeout, const char* name);

#endif
