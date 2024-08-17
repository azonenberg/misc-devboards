/**
	@file
	@brief Configuration file for staticnet
 */

#ifndef staticnet_config_h
#define staticnet_config_h

///@brief Maximum size of an Ethernet frame (payload only, headers not included)
#define ETHERNET_PAYLOAD_MTU 1500

///@brief Define this to zeroize all frame buffers between uses
//#define ZEROIZE_BUFFERS_BEFORE_USE

///@brief Define this to enable performance counters
#define STATICNET_PERFORMANCE_COUNTERS

///@brief Number of ways of associativity for the ARP cache
#define ARP_CACHE_WAYS 4

///@brief Number of lines per set in the ARP cache
#define ARP_CACHE_LINES 256

///@brief Number of entries in the TCP socket table
#define TCP_TABLE_WAYS 2

///@brief Number of lines per set in the TCP socket table
#define TCP_TABLE_LINES 16

///@brief Maximum number of SSH connections supported
#define SSH_TABLE_SIZE 2

///@brief SSH socket RX buffer size
#define SSH_RX_BUFFER_SIZE 2048

///@brief CLI TX buffer size
#define CLI_TX_BUFFER_SIZE 1024

///@brief Maximum length of a SSH username
#define SSH_MAX_USERNAME	32

///@brief Max length of a CLI username
#define CLI_USERNAME_MAX SSH_MAX_USERNAME

///@brief Maximum length of a SSH password
#define SSH_MAX_PASSWORD	128

///@brief Max number of concurrent SCPI connections
#define MAX_SCPI_CONNS	2

///@brief SCPI socket RX buffer size
#define SCPI_RX_BUFFER_SIZE 2048

/**
	@brief Max pending (not ACKed) TCP segments for a given socket

	This is essentially a cap on window size in segments (vs bytes).
 */
#define TCP_MAX_UNACKED 4

///@brief Maximum age for a TCP segment before deciding to retransmit (in 100ms ticks)
#define TCP_RETRANSMIT_TIMEOUT 2

#endif
