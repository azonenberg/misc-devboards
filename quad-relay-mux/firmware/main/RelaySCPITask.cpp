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

#include "relaymux.h"
#include "RelaySCPITask.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

RelaySCPITask::RelaySCPITask()
	: SCPITask(&g_scpiUART)
{
	for(int i=0; i<4; i++)
		m_select[i] = 0;
}

void RelaySCPITask::OnCommand(const char* subject, const char* command, const char* args)
{
	//g_log("OnCommand subject=%s command=%s args=%s\n", subject, command, args);

	if(strstr(subject, "CHAN") == subject)
	{
		if(0 != strcmp(command, "MUX"))
			return;

		//Mux config
		int nchan = subject[4] - '0';
		if( (nchan < 0) || (nchan > 3) )
			return;

		bool sel = (args[0] == 'B');
		m_select[nchan] = sel;
		SetRelay(nchan, sel);

		*(g_muxled_a[nchan]) = (sel == 0);
		*(g_muxled_b[nchan]) = (sel == 1);
	}
}

void RelaySCPITask::OnQuery([[maybe_unused]] const char* subject, [[maybe_unused]] const char* command)
{
	if(strstr(subject, "CHAN") == subject)
	{
		if(0 != strcmp(command, "MUX"))
			return;

		//Mux config
		int nchan = subject[4] - '0';
		if( (nchan < 0) || (nchan > 3) )
		{
			m_device->Printf("A\n");	//invalid but we dont want to bork the client
			return;
		}

		m_device->Printf("%c\n", m_select[nchan] ? 'B' : 'A');
	}
}

void RelaySCPITask::OnSpecialCommand(const char* line)
{
	if(!strcmp(line, "*IDN?"))
		m_device->Printf("AntikernelLabs,AKL-QUADRELAY,NoSerial,0.1\n");

	else
		g_log(Logger::WARNING, "Unrecognized special command \"%s\"\n", line);
}
