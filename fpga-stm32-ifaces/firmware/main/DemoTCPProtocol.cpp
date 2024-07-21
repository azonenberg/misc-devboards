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
#include "DemoTCPProtocol.h"

Iperf3Server* g_iperfServer = nullptr;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

DemoTCPProtocol::DemoTCPProtocol(IPv4Protocol* ipv4, UDPProtocol& udp)
	: TCPProtocol(ipv4)
	, m_iperf(*this, udp)
{
	g_iperfServer = &m_iperf;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Message handlers

bool DemoTCPProtocol::IsPortOpen(uint16_t port)
{
	return (port == IPERF3_PORT);
}

void DemoTCPProtocol::OnConnectionAccepted(TCPTableEntry* state)
{
	switch(state->m_localPort)
	{
		case IPERF3_PORT:
			m_iperf.OnConnectionAccepted(state);
			break;

		default:
			break;
	}
}

void DemoTCPProtocol::OnConnectionClosed(TCPTableEntry* state)
{
	//Call base class to free memory
	TCPProtocol::OnConnectionClosed(state);

	switch(state->m_localPort)
	{
		case IPERF3_PORT:
			m_iperf.OnConnectionClosed(state);
			break;

		default:
			break;
	}
}

void DemoTCPProtocol::OnRxData(TCPTableEntry* state, uint8_t* payload, uint16_t payloadLen)
{
	switch(state->m_localPort)
	{
		case IPERF3_PORT:
			m_iperf.OnRxData(state, payload, payloadLen);
			break;

		//ignore it
		default:
			break;
	}
}

uint32_t DemoTCPProtocol::GenerateInitialSequenceNumber()
{
	uint32_t ret;
	m_crypt.GenerateRandom(reinterpret_cast<uint8_t*>(&ret), sizeof(ret));
	return ret;
}
