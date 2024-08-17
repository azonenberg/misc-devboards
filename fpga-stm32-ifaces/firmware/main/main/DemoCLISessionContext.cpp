#include "ifacetest.h"
#include "DemoCLISessionContext.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Command IDs

enum cmdid_t
{
	CMD_CAT
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level commands

static const clikeyword_t g_rootCommands[] =
{
	{"cat",		CMD_CAT,			nullptr,	"meow" },
	{nullptr,	INVALID_COMMAND,	nullptr,	nullptr }
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

DemoCLISessionContext::DemoCLISessionContext()
	: CLISessionContext(g_rootCommands)
{
	m_hostname = "fmctest";
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level command dispatch

void DemoCLISessionContext::PrintPrompt()
{
	m_stream->Printf("%s@%s# ", m_username, m_hostname);
	m_stream->Flush();
}

void DemoCLISessionContext::OnExecute()
{
	switch(m_command[0].m_commandID)
	{
		case CMD_CAT:
			m_stream->Printf("nyaa~\n");
			break;

		default:
			m_stream->Printf("Unrecognized command\n");
			break;
	}
}
