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

typedef void(*fnptr)();

extern uint32_t __stack;
extern uint32_t __bss_start__;
extern uint32_t __bss_end__;

//prototypes
extern "C" void _start();
void MMUFault_Handler();
void UsageFault_Handler();
void BusFault_Handler();
void HardFault_Handler();
void NMI_Handler();

void USART2_Handler();

void defaultISR();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interrupt vector table

fnptr __attribute__((section(".vector"))) vectorTable[] =
{
	(fnptr)&__stack,		//stack
	_start,					//reset
	NMI_Handler,			//NMI
	HardFault_Handler,		//hardfault
	MMUFault_Handler,		//mmufault
	BusFault_Handler,		//busfault
	UsageFault_Handler,		//usagefault
	defaultISR,				//reserved_7
	defaultISR,				//reserved_8
	defaultISR,				//reserved_9
	defaultISR,				//reserved_10
	defaultISR,				//svcall
	defaultISR,				//debug
	defaultISR,				//reserved_13
	defaultISR,				//pend_sv
	defaultISR,				//systick
	defaultISR,				//irq0 WWDG
	defaultISR,				//irq1 PVD
	defaultISR,				//irq2 RTC
	defaultISR,				//irq3 FLASH
	defaultISR,				//irq4 RCC_CRS
	defaultISR,				//irq5 EXTI[1:0]
	defaultISR,				//irq6 EXTI[3:2]
	defaultISR,				//irq7 EXTI[15:4]
	defaultISR,				//irq8 reserved
	defaultISR,				//irq9 DMA1_Channel1
	defaultISR,				//irq10 DMA1_Channel[3:2]
	defaultISR,				//irq11 DMA1_Channel[7:4]
	defaultISR,				//irq12 ADC_COMP
	defaultISR,				//irq13 LPTIM1
	defaultISR,				//irq14 USART4/USART5
	defaultISR,				//irq15 TIM2
	defaultISR,				//irq16 TIM3
	defaultISR,				//irq17 TIM6
	defaultISR,				//irq18 TIM7
	defaultISR,				//irq19 reserved
	defaultISR,				//irq20 TIM21
	defaultISR,				//irq21 I2C3
	defaultISR,				//irq22 TIM22
	defaultISR,				//irq23 I2C1
	defaultISR,				//irq24 I2C2
	defaultISR,				//irq25 SPI1
	defaultISR,				//irq26 SPI2
	defaultISR,				//irq27 USART1
	USART2_Handler,			//irq28 USART2
	defaultISR				//irq29 LPUART1 + AES
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Firmware version string used for the bootloader if we have one

extern "C" const char
	__attribute__((section(".fwid")))
	__attribute__((used))
	g_firmwareID[] = "christmas-tree";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Stub for unused interrupts

void defaultISR()
{
	Reset();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Exception vectors

void NMI_Handler()
{
	Reset();
}

void HardFault_Handler()
{
	//Save registers
	uint32_t* msp;
	asm volatile("mrs %[result], MSP" : [result]"=r"(msp));
	msp += 12;	//locals/alignment
	uint32_t r0 = msp[0];
	uint32_t r1 = msp[1];
	uint32_t r2 = msp[2];
	uint32_t r3 = msp[3];
	uint32_t r12 = msp[4];
	uint32_t lr = msp[5];
	uint32_t pc = msp[6];
	uint32_t xpsr = msp[7];

	g_uart.Printf("Hard fault\n");
	g_uart.Printf("    HFSR  = %08x\n", *(volatile uint32_t*)(0xe000ed2C));
	g_uart.Printf("    MMFAR = %08x\n", *(volatile uint32_t*)(0xe000ed34));
	g_uart.Printf("    BFAR  = %08x\n", *(volatile uint32_t*)(0xe000ed38));
	g_uart.Printf("    CFSR  = %08x\n", *(volatile uint32_t*)(0xe000ed28));
	g_uart.Printf("    UFSR  = %08x\n", *(volatile uint16_t*)(0xe000ed2a));
	g_uart.Printf("    DFSR  = %08x\n", *(volatile uint32_t*)(0xe000ed30));
	g_uart.Printf("    MSP   = %08x\n", msp);
	g_uart.BlockingFlush();
	g_uart.Printf("    r0    = %08x\n", r0);
	g_uart.Printf("    r1    = %08x\n", r1);
	g_uart.Printf("    r2    = %08x\n", r2);
	g_uart.Printf("    r3    = %08x\n", r3);
	g_uart.Printf("    r12   = %08x\n", r12);
	g_uart.Printf("    lr    = %08x\n", lr);
	g_uart.Printf("    pc    = %08x\n", pc);
	g_uart.Printf("    xpsr  = %08x\n", xpsr);

	g_uart.Printf("    Stack:\n");
	g_uart.BlockingFlush();
	for(int i=0; i<16; i++)
	{
		g_uart.Printf("        %08x\n", msp[i]);
		g_uart.BlockingFlush();
	}

	while(1)
	{}
}

void BusFault_Handler()
{
	Reset();
}

void UsageFault_Handler()
{
	Reset();
}

void MMUFault_Handler()
{
	Reset();
}

/**
	@brief USART2 interrupt
 */
void USART2_Handler()
{
	if(USART2.ISR & USART_ISR_TXE)
		g_uart.OnIRQTxEmpty();

	if(USART2.ISR & USART_ISR_RXNE)
		g_uart.OnIRQRxData();
}
