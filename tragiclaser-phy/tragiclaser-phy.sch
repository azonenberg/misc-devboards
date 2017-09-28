EESchema Schematic File Version 2
LIBS:analog-azonenberg
LIBS:cmos
LIBS:cypress-azonenberg
LIBS:hirose-azonenberg
LIBS:memory-azonenberg
LIBS:microchip-azonenberg
LIBS:osc-azonenberg
LIBS:passive-azonenberg
LIBS:power-azonenberg
LIBS:silego-azonenberg
LIBS:special-azonenberg
LIBS:xilinx-azonenberg
LIBS:device
LIBS:conn
LIBS:tragiclaser-phy-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 5
Title "TRAGICLASER Ethernet PHY Prototype"
Date "2017-09-27"
Rev "0.1"
Comp "Andrew Zonenberg"
Comment1 "Top level"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Sheet
S 750  800  1150 1750
U 59CABCCC
F0 "FPGA Support" 60
F1 "fpga-support.sch" 60
F2 "2V5" I R 1900 950 60 
F3 "GND" I R 1900 1150 60 
F4 "1V2" I R 1900 1050 60 
F5 "3V3" I R 1900 850 60 
$EndSheet
$Sheet
S 2950 800  1050 1750
U 59CABCD8
F0 "PHY" 60
F1 "phy.sch" 60
F2 "3V3" I L 2950 850 60 
F3 "GND" I L 2950 1150 60 
$EndSheet
$Sheet
S 5000 800  1100 1750
U 59CABCE0
F0 "Power Supply" 60
F1 "psu.sch" 60
F2 "3V3" O L 5000 850 60 
F3 "2V5" O L 5000 950 60 
F4 "1V2" O L 5000 1050 60 
F5 "GND" O L 5000 1150 60 
$EndSheet
Wire Wire Line
	1900 850  2950 850 
Wire Wire Line
	2950 1150 1900 1150
Text Label 2050 850  0    60   ~ 0
3V3
Text Label 2050 950  0    60   ~ 0
2V5
Text Label 2050 1050 0    60   ~ 0
1V2
Text Label 2050 1150 0    60   ~ 0
GND
Wire Wire Line
	2050 1050 1900 1050
Wire Wire Line
	1900 950  2050 950 
Text Label 4750 850  2    60   ~ 0
3V3
Wire Wire Line
	4750 850  5000 850 
Text Label 4750 950  2    60   ~ 0
2V5
Wire Wire Line
	4750 950  5000 950 
Text Label 4750 1050 2    60   ~ 0
1V2
Wire Wire Line
	4750 1050 5000 1050
Text Label 4750 1150 2    60   ~ 0
GND
Wire Wire Line
	4750 1150 5000 1150
$Sheet
S 7250 800  1250 1750
U 59CCF577
F0 "Boot/Config" 60
F1 "bootconfig.sch" 60
F2 "3V3" I L 7250 850 60 
F3 "GND" I L 7250 1150 60 
$EndSheet
Text Label 7000 1150 2    60   ~ 0
GND
Text Label 7000 850  2    60   ~ 0
3V3
Wire Wire Line
	7000 850  7250 850 
Wire Wire Line
	7250 1150 7000 1150
$EndSCHEMATC
