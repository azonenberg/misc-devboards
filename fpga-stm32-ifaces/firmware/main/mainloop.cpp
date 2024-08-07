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

#include "ifacetest.h"

#include "DemoCLISessionContext.h"
#include <peripheral/ITMStream.h>
//#include "../super/superregs.h"

///@brief Output stream for local serial console
UARTOutputStream g_localConsoleOutputStream;

///@brief Context data structure for local serial console
DemoCLISessionContext g_localConsoleSessionContext;

extern Iperf3Server* g_iperfServer;

///@brief ITM serial trace data stream
ITMStream g_itmStream(4);

void App_Init()
{
	//Enable interrupts early on since we use them for e.g. debug logging during boot
	EnableInterrupts();

	//Basic hardware setup
	InitLEDs();
	InitDTS();

	//Initialize the local console
	g_localConsoleOutputStream.Initialize(&g_cliUART);
	g_localConsoleSessionContext.Initialize(&g_localConsoleOutputStream, "localadmin");

	//Show the initial prompt
	g_localConsoleSessionContext.PrintPrompt();
}

void BSP_MainLoopIteration()
{
	//Main event loop
	static uint32_t next1HzTick = 0;
	static uint32_t next10HzTick = 0;
	static uint32_t nextPhyPoll = 0;
	const uint32_t logTimerMax = 0xf0000000;

	//Wait for an interrupt
	//asm("wfi");

	//Handle incoming Ethernet frames
	if(*g_ethIRQ)
	{
		auto frame = g_ethIface.GetRxFrame();
		if(frame != nullptr)
			g_ethProtocol->OnRxFrame(frame);
	}

	//Send iperf data if needed
	g_iperfServer->SendDataOnActiveStreams();

	//Check if we had a PHY link state change at 20 Hz
	//TODO: add irq bit for this so we don't have to poll nonstop
	if(g_logTimer.GetCount() >= nextPhyPoll)
	{
		PollPHYs();
		nextPhyPoll = g_logTimer.GetCount() + 500;
	}

	//Poll for UART input
	if(g_cliUART.HasInput())
		g_localConsoleSessionContext.OnKeystroke(g_cliUART.BlockingRead());

	//Keep the log timer from wrapping
	if(g_log.UpdateOffset(logTimerMax))
	{
		next1HzTick -= logTimerMax;
		next10HzTick -= logTimerMax;
	}

	//Refresh of activity LEDs and TCP retransmits at 10 Hz
	if(g_logTimer.GetCount() >= next10HzTick)
	{
		g_ethProtocol->OnAgingTick10x();
		next10HzTick = g_logTimer.GetCount() + 1000;
	}

	//1 Hz timer for various aging processes
	static int i = 0;
	if(g_logTimer.GetCount() >= next1HzTick)
	{
		g_ethProtocol->OnAgingTick();
		next1HzTick = g_logTimer.GetCount() + 10000;

		//DEBUG: send trace data
		g_itmStream.Printf("hai world %d\n", i);
		i++;
	}
}
/*
uint16_t SupervisorRegRead(uint8_t regid)
{
	*g_superSPICS = 0;
	g_superSPI.BlockingWrite(regid);
	g_superSPI.WaitForWrites();
	g_superSPI.DiscardRxData();
	g_superSPI.BlockingRead();	//discard dummy byte
	uint16_t tmp = g_superSPI.BlockingRead();
	tmp |= (g_superSPI.BlockingRead() << 8);
	*g_superSPICS = 1;

	g_logTimer.Sleep(1);

	return tmp;
}
*/
