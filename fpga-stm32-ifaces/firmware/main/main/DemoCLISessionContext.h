#ifndef DemoCLISessionContext_h
#define DemoCLISessionContext_h

#include <embedded-cli/CLIOutputStream.h>
#include <embedded-cli/CLISessionContext.h>

class DemoCLISessionContext : public CLISessionContext
{
public:
	DemoCLISessionContext();

	void Initialize(CLIOutputStream* stream, const char* username)
	{
		m_stream = stream;
		CLISessionContext::Initialize(m_stream, username);
	}

	virtual void PrintPrompt() override;

protected:
	virtual void OnExecute() override;

	CLIOutputStream* m_stream;
	const char* m_hostname;
};

#endif
