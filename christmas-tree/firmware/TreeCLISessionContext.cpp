/***********************************************************************************************************************
*                                                                                                                      *
* christmas-tree                                                                                                       *
*                                                                                                                      *
* Copyright (c) 2024 Andrew D. Zonenberg and contributors                                                              *
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
#include "TreeCLISessionContext.h"
#include <math.h>

//const char* g_iincalObjectName = "cal.iin";
//const char* g_ioutcalObjectName = "cal.iout";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Command IDs

enum cmdid_t
{
	CMD_COMMIT,
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level commands

static const clikeyword_t g_rootCommands[] =
{
	{"commit",		CMD_COMMIT,			nullptr,				"Commit pending configuration to flash" },
	{nullptr,		INVALID_COMMAND,	nullptr,				nullptr }
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

TreeCLISessionContext::TreeCLISessionContext()
	: CLISessionContext(g_rootCommands)
{
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level command dispatch

void TreeCLISessionContext::PrintPrompt()
{
	m_stream->Printf("%s@christmastree# ", m_username);
	m_stream->Flush();
}

void TreeCLISessionContext::OnExecute()
{
	switch(m_command[0].m_commandID)
	{
		/*case CMD_CALIBRATE:
			OnCalibrate();
			break;

		case CMD_CAT:
			m_stream->Printf("nyaa~\n");
			break;
			*/
		case CMD_COMMIT:
			OnCommit();
			break;

		default:
			m_stream->Printf("Unrecognized command\n");
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "commit"

void TreeCLISessionContext::OnCommit()
{
	//g_kvs->StoreObjectIfNecessary(g_inputCurrentShuntOffset, (uint16_t)0, g_iincalObjectName);
	//g_kvs->StoreObjectIfNecessary(g_outputCurrentShuntOffset, (uint16_t)0, g_ioutcalObjectName);
}
