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

#include "supervisor.h"
#include "SupervisorSPIServer.h"

SupervisorSPIServer::SupervisorSPIServer()
	: m_nbyte(0)
	, m_command(0)
{
}

/**
	@brief Called on CS# falling edge
 */
void SupervisorSPIServer::OnFallingEdge()
{
	m_nbyte = 0;
	m_command = 0;
}

/**
	@brief Called when a SPI byte arrives
 */
void SupervisorSPIServer::OnByte(uint8_t b)
{
	if(m_nbyte == 0)
		OnCommand(b);
	else
		OnDataByte(b);

	m_nbyte ++;
}

/**
	@brief Called when a SPI command arrives
 */
void SupervisorSPIServer::OnCommand(uint8_t b)
{
	m_command = b;

	switch(m_command)
	{
		case SUPER_REG_VERSION:
			g_spi.NonblockingWriteFifo((const uint8_t*)g_version, sizeof(g_version));
			break;

		case SUPER_REG_IBCVERSION:
			g_spi.NonblockingWriteFifo((const uint8_t*)g_ibcSwVersion, sizeof(g_ibcSwVersion));
			break;
	}
}

/**
	@brief Called when a SPI data byte (not command) arrives
 */
void SupervisorSPIServer::OnDataByte([[maybe_unused]] uint8_t b)
{
}
