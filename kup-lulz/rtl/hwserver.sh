#!/bin/bash
source /opt/Xilinx/Vivado/2024.1/settings64.sh
hw_server -e "set jtag-port-filter Digilent/JTAG-HS2/210249A30457" -stcp::3140 -p 3060
