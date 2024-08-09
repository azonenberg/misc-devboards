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
#include "TempSensorReader.h"

/**
	@brief Nonblocking read of the temperature

	Call this function periodically

	@return True if the temperature has been updated, false if no new data
 */
bool TempSensorReader::ReadTempNonblocking(uint16_t& regval)
{
	switch(m_state)
	{
		//Start a new register access
		case STATE_IDLE:
			g_i2c.NonblockingStart(1, g_tempI2cAddress, false);
			m_state = STATE_ADDR_START;
			break;

		//Wait for the start sequence to finish
		case STATE_ADDR_START:
			if(g_i2c.IsStartDone())
			{
				g_i2c.NonblockingWrite(0x00);
				m_state = STATE_REGID;
			}
			break;

		//Wait for register ID to send
		case STATE_REGID:
			if(g_i2c.IsWriteDone())
			{
				//Start the read
				g_i2c.NonblockingStart(2, g_tempI2cAddress, true);
				m_state = STATE_DATA_LO;
			}
			break;

		//Wait for the first data byte to be ready
		case STATE_DATA_LO:
			if(g_i2c.IsReadReady())
			{
				m_tmpval = g_i2c.GetReadData();
				m_state = STATE_DATA_HI;
			}
			break;

		//Wait for the second data byte to be ready
		case STATE_DATA_HI:
			if(g_i2c.IsReadReady())
			{
				regval = g_i2c.GetReadData() | (m_tmpval << 8);
				m_state = STATE_IDLE;
				return true;
			}
	}

	return false;
}
