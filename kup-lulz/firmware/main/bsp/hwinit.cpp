/***********************************************************************************************************************
*                                                                                                                      *
* misc-devboards                                                                                                       *
*                                                                                                                      *
* Copyright (c) 2023-2025 Andrew D. Zonenberg and contributors                                                         *
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

/**
	@file
	@author	Andrew D. Zonenberg
	@brief	Boot-time hardware initialization
 */
#include <core/platform.h>
#include "hwinit.h"
#include <embedded-utils/LogSink.h>
#include <peripheral/DWT.h>
#include <peripheral/ITM.h>
#include <peripheral/Power.h>
#include <ctype.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common peripherals used by application and bootloader

/**
	@brief UART console

	Default after reset is for UART4 to be clocked by PCLK1 (APB1 clock) which is 62.5 MHz
	So we need a divisor of 542.53
 */
UART<32, 256> g_cliUART(&UART4, 543);

///@brief Interface to the FPGA via APB
APBFPGAInterface g_apbfpga;

///@brief QSPI interface to FPGA
OctoSPI* g_qspi = nullptr;

/**
	@brief MAC address I2C EEPROM

	Default kernel clock for I2C2 is pclk2 (68.75 MHz for our current config)
	Prescale by 16 to get 4.29 MHz
	Divide by 40 after that to get 107 kHz
 */
I2C g_macI2C(&I2C2, 16, 40);
/*
///@brief SFP+ DOM / ID EEPROM
I2C* g_sfpI2C = nullptr;

///@brief SFP+ link state
bool g_sfpLinkUp;

///@brief SFP mod_abs
GPIOPin* g_sfpModAbsPin = nullptr;

///@brief SFP tx_disable
GPIOPin* g_sfpTxDisablePin = nullptr;

///@brief SFP tx_fault
GPIOPin* g_sfpTxFaultPin = nullptr;

///@brief SFP laser fault detected
bool g_sfpFaulted = false;

///@brief SFP module inserted (does not imply link is up)
bool g_sfpPresent = false;

///@brief Key manager
SSHKeyManager g_keyMgr;

///@brief The single supported SSH username
char g_sshUsername[CLI_USERNAME_MAX] = "";

///@brief KVS key for the SSH username
const char* g_usernameObjectID = "ssh.username";

///@brief Default SSH username if not configured
const char* g_defaultSshUsername = "admin";

///@brief Selects whether the DHCP client is active or not
bool g_usingDHCP = false;

///@brief The DHCP client
ManagementDHCPClient* g_dhcpClient = nullptr;
*/
///@brief USERCODE of the FPGA (build timestamp)
uint32_t g_usercode = 0;

///@brief FPGA die serial number
uint8_t g_fpgaSerial[8] = {0};

///@brief IRQ line to the FPGA
//GPIOPin g_irq(&GPIOH, 6, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);

///@brief The battery-backed RAM used to store state across power cycles
volatile BootloaderBBRAM* g_bbram = reinterpret_cast<volatile BootloaderBBRAM*>(&_RTC.BKP[0]);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Memory mapped SFRs on the FPGA

//TODO: use linker script to locate these rather than this ugly pointer code?
/*
//volatile APB_DeviceInfo_7series FDEVINFO __attribute__((section(".fdevinfo")));
volatile APB_SystemInfo FDEVINFO __attribute__((section(".fdevinfo")));
volatile APB_GPIO FPGA_GPIO0 __attribute__((section(".fgpio0")));
volatile APB_GPIO FPGA_GPIO1 __attribute__((section(".fgpio1")));
volatile APB_MDIO FMDIO __attribute__((section(".fmdio")));
volatile APB_RelayController FRELAY __attribute__((section(".frelay")));
volatile APB_SPIHostInterface FFRONTSPI __attribute__((section(".ffrontspi")));
volatile APB_CrossbarMatrix FMUXSEL __attribute__((section(".fmuxsel")));
volatile APB_Curve25519 FCURVE25519 __attribute__((section(".fcurve25519")));
volatile uint16_t FIRQSTAT __attribute__((section(".firqstat")));
volatile APB_SPIHostInterface FSPI1 __attribute__((section(".fspi1")));
volatile APB_EthernetTxBuffer_10G FETHTX10 __attribute__((section(".fethtx10")));
volatile APB_EthernetTxBuffer_10G FETHTX1 __attribute__((section(".fethtx1")));
volatile APB_EthernetRxBuffer FETHRX __attribute__((section(".fethrx")));
volatile APB_BERTConfig FBERT0 __attribute__((section(".fbert0")));
volatile APB_BERTConfig FBERT1 __attribute__((section(".fbert1")));
volatile APB_SerdesDRP FDRP0 __attribute__((section(".fdrp0")));
volatile APB_SerdesDRP FDRP1 __attribute__((section(".fdrp1")));
volatile LogicAnalyzer FLA0 __attribute__((section(".fla0")));
volatile LogicAnalyzer FLA1 __attribute__((section(".fla1")));

///@brief Controller for the MDIO interface
MDIODevice g_mgmtPhy(&FMDIO, 0);

APB_SpiFlashInterface* g_fpgaFlash = nullptr;

__attribute__((section(".tcmbss"))) APBEthernetInterface g_ethIface(&FETHRX, &FETHTX10);
*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Task tables

etl::vector<Task*, MAX_TASKS>  g_tasks;
etl::vector<TimerTask*, MAX_TIMER_TASKS>  g_timerTasks;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Do other initialization

#ifdef _DEBUG
void InitTrace();
#endif

void BSP_Init()
{
	InitRTCFromHSE();

	#ifdef _DEBUG
	InitTrace();
	#endif

	App_Init();
}

#ifdef _DEBUG
void InitTrace()
{
	//Enable ITM, enable PC sampling, and turn on forwarding to the TPIU
	ITM::Enable();
	DWT::EnablePCSampling(DWT::PC_SAMPLE_SLOW);
	ITM::EnableDwtForwarding();

	//Turn on ITM stimulus channel 0 for temperature logging
	ITM::EnableChannel(0);
}
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BSP overrides for low level init

void BSP_InitUART()
{
	//Initialize the UART for local console: 115.2 Kbps using PA12 for UART4 transmit and PA11 for UART2 receive
	//TODO: nice interface for enabling UART interrupts
	static GPIOPin uart_tx(&GPIOA, 12, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 6);
	static GPIOPin uart_rx(&GPIOA, 11, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 6);

	//Enable the UART interrupt
	NVIC_EnableIRQ(52);

	g_logTimer.Sleep(10);	//wait for UART pins to be high long enough to remove any glitches during powerup

	//Clear screen and move cursor to X0Y0
	if(IsBootloader())
		g_cliUART.Printf("\x1b[2J\x1b[0;0H");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Higher level initialization we used for a lot of stuff

void InitI2C()
{
	g_log("Initializing I2C interfaces\n");

	static GPIOPin mac_i2c_scl(&GPIOH, 4, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
	static GPIOPin mac_i2c_sda(&GPIOH, 5, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
/*
	static GPIOPin sfp_i2c_scl(&GPIOF, 1, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
	static GPIOPin sfp_i2c_sda(&GPIOF, 0, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);

	//Default kernel clock for I2C2 is is APB1 clock (68.75 MHz for our current config)
	//Prescale by 16 to get 4.29 MHz
	//Divide by 40 after that to get 107 kHz
	static I2C sfp_i2c(&I2C2, 16, 40);
	g_sfpI2C = &sfp_i2c;*/
}

void InitQSPI()
{
	g_log("Initializing QSPI interface\n");

	//Configure the I/O manager
	OctoSPIManager::ConfigureMux(false);
	OctoSPIManager::ConfigurePort(
		1,							//Configuring port 1
		false,						//DQ[7:4] disabled
		OctoSPIManager::C1_HIGH,
		true,						//DQ[3:0] enabled
		OctoSPIManager::C1_LOW,		//DQ[3:0] from OCTOSPI1 DQ[3:0]
		true,						//CS# enabled
		OctoSPIManager::PORT_1,		//CS# from OCTOSPI1
		false,						//DQS disabled
		OctoSPIManager::PORT_1,
		true,						//Clock enabled
		OctoSPIManager::PORT_1);	//Clock from OCTOSPI1

	//Configure the I/O pins
	static GPIOPin qspi_cs_n(&GPIOG, 12, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 3);
	static GPIOPin qspi_sck(&GPIOF, 4, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 9);
	static GPIOPin qspi_dq0(&GPIOF, 0, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 9);
	static GPIOPin qspi_dq1(&GPIOF, 1, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 9);
	static GPIOPin qspi_dq2(&GPIOF, 2, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 9);
	static GPIOPin qspi_dq3(&GPIOF, 3, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 9);

	//Clock divider value
	//Default is for AHB3 bus clock to be used as kernel clock (250 MHz for us)
	//With 3.3V Vdd, we can go up to 140 MHz.
	//FPGA currently requires <= 62.5 MHz due to the RX oversampling used (4x in 250 MHz clock domain)
	//Dividing by 5 gives 50 MHz and a transfer rate of 200 Mbps
	//Dividing by 10, but DDR, gives the same throughput and works around an errata (which one??)
	uint8_t prescale = 10;

	//Configure the OCTOSPI itself
	//Original code used "instruction", but we want "address" to enable memory mapping
	static OctoSPI qspi(&OCTOSPI1, 0x02000000, prescale);
	qspi.SetDoubleRateMode(true);
	qspi.SetInstructionMode(OctoSPI::MODE_QUAD, 1);
	qspi.SetAddressMode(OctoSPI::MODE_QUAD, 3);
	qspi.SetAltBytesMode(OctoSPI::MODE_NONE);
	qspi.SetDataMode(OctoSPI::MODE_QUAD);
	qspi.SetDummyCycleCount(1);
	qspi.SetDQSEnable(false);
	qspi.SetDeselectTime(1);
	qspi.SetSampleDelay(false, true);

	//Poke MPU settings to disable caching etc on the QSPI memory range
	MPU::Configure(MPU::KEEP_DEFAULT_MAP, MPU::DISABLE_IN_FAULT_HANDLERS);
	MPU::ConfigureRegion(
		0,
		FPGA_MEM_BASE,
		MPU::SHARED_DEVICE,
		MPU::FULL_ACCESS,
		MPU::EXECUTE_NEVER,
		MPU::SIZE_16M);

	//Configure memory mapping mode
	qspi.SetMemoryMapMode(APBFPGAInterface::OP_APB_READ, APBFPGAInterface::OP_APB_WRITE);
	g_qspi = &qspi;
}

/**
	@brief Bring up the control interface to the FPGA
 */
void InitFPGA()
{
	/*
	g_log("Initializing FPGA\n");
	LogIndenter li(g_log);

	//Wait for the DONE signal to go high
	g_log("Waiting for FPGA boot\n");
	static GPIOPin fpgaDone(&GPIOF, 6, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
	while(!fpgaDone)
	{}

	//Read the FPGA IDCODE and serial number
	//Retry until we get a nonzero result indicating FPGA is up
	while(true)
	{
		uint32_t idcode = FDEVINFO.idcode;
		memcpy(g_fpgaSerial, (const void*)FDEVINFO.serial, 8);

		//If IDCODE is all zeroes, poll again
		if(idcode == 0)
			continue;

		//Print status
		switch(idcode & 0x0fffffff)
		{
			case 0x3647093:
				g_log("IDCODE: %08x (XC7K70T rev %d)\n", idcode, idcode >> 28);
				break;

			case 0x364c093:
				g_log("IDCODE: %08x (XC7K160T rev %d)\n", idcode, idcode >> 28);
				break;

			default:
				g_log("IDCODE: %08x (unknown device, rev %d)\n", idcode, idcode >> 28);
				break;
		}
		g_log("Serial: %02x%02x%02x%02x%02x%02x%02x%02x\n",
			g_fpgaSerial[7], g_fpgaSerial[6], g_fpgaSerial[5], g_fpgaSerial[4],
			g_fpgaSerial[3], g_fpgaSerial[2], g_fpgaSerial[1], g_fpgaSerial[0]);

		break;
	}

	//Read USERCODE
	g_usercode = FDEVINFO.usercode;
	g_log("Usercode: %08x\n", g_usercode);
	{
		LogIndenter li2(g_log);

		//Format per XAPP1232:
		//31:27 day
		//26:23 month
		//22:17 year
		//16:12 hr
		//11:6 min
		//5:0 sec
		int day = g_usercode >> 27;
		int mon = (g_usercode >> 23) & 0xf;
		int yr = 2000 + ((g_usercode >> 17) & 0x3f);
		int hr = (g_usercode >> 12) & 0x1f;
		int min = (g_usercode >> 6) & 0x3f;
		int sec = g_usercode & 0x3f;
		g_log("Bitstream timestamp: %04d-%02d-%02d %02d:%02d:%02d\n",
			yr, mon, day, hr, min, sec);
	}

	InitFPGAFlash();
	*/
}

void InitFPGAFlash()
{
	/*
	g_log("Initializing FPGA flash\n");
	LogIndenter li(g_log);

	static APB_SpiFlashInterface flash(&FSPI1, 64);
	g_fpgaFlash = &flash;
	*/
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Placeholders for bootloader or app to override

void __attribute__((weak)) OnEthernetLinkStateChanged()
{
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SFR access

/**
	@brief Block until the status register (mapped at two locations) matches the target
 */
void StatusRegisterMaskedWait(volatile uint32_t* a, volatile uint32_t* b, uint32_t mask, uint32_t target)
{
	asm("dmb st");

	while(true)
	{
		uint32_t va = *a;
		uint32_t vb = *b;
		asm("dmb");

		if( ( (va & mask) == target) && ( (vb & mask) == target) )
			return;
	}
}
