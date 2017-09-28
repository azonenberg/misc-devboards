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
Sheet 2 5
Title "TRAGICLASER Ethernet PHY Prototype"
Date "2017-09-27"
Rev "0.1"
Comp "Andrew Zonenberg"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L XC6SLX25-xFTG256-SEG U1
U 5 1 59CAC15D
P 4650 4000
F 0 "U1" H 4650 7187 60  0000 C CNN
F 1 "XC6SLX25-2FTG256C" H 4650 7081 60  0000 C CNN
F 2 "" H 4650 4000 60  0000 C CNN
F 3 "" H 4650 4000 60  0000 C CNN
	5    4650 4000
	1    0    0    -1  
$EndComp
$Comp
L XILINX_JTAG J1
U 1 1 59CCBFC0
P 2000 2200
F 0 "J1" H 2718 2908 60  0000 L CNN
F 1 "XILINX_JTAG" H 2718 2802 60  0000 L CNN
F 2 "" H 2000 2200 60  0000 C CNN
F 3 "" H 2000 2200 60  0000 C CNN
	1    2000 2200
	-1   0    0    -1  
$EndComp
Text Label 2200 1100 0    60   ~ 0
2V5
Text Label 2200 1200 0    60   ~ 0
GND
Wire Wire Line
	2200 1100 2000 1100
Wire Wire Line
	2000 1200 2200 1200
Wire Wire Line
	2100 1200 2100 1600
Wire Wire Line
	2100 1300 2000 1300
Connection ~ 2100 1200
Wire Wire Line
	2100 1400 2000 1400
Connection ~ 2100 1300
Wire Wire Line
	2100 1500 2000 1500
Connection ~ 2100 1400
Wire Wire Line
	2100 1600 2000 1600
Connection ~ 2100 1500
NoConn ~ 2000 1700
Text Label 2100 1800 0    60   ~ 0
JTAG_TMS
Text Label 2100 1900 0    60   ~ 0
JTAG_TCK
Text Label 2100 2000 0    60   ~ 0
JTAG_TDO
Text Label 2100 2100 0    60   ~ 0
JTAG_TDI
NoConn ~ 2000 2200
Wire Wire Line
	2100 2100 2000 2100
Wire Wire Line
	2000 2000 2100 2000
Wire Wire Line
	2100 1900 2000 1900
Wire Wire Line
	2000 1800 2100 1800
Wire Wire Line
	3350 1600 3500 1600
Text Label 3350 1600 2    60   ~ 0
GND
$Comp
L R R1
U 1 1 59CCC2EC
P 1700 2800
F 0 "R1" V 1600 2800 50  0000 C CNN
F 1 "470" V 1700 2800 50  0000 C CNN
F 2 "" V 1630 2800 50  0000 C CNN
F 3 "" H 1700 2800 50  0000 C CNN
	1    1700 2800
	0    1    1    0   
$EndComp
Text Label 3350 1800 2    60   ~ 0
FPGA_DONE
Wire Wire Line
	3350 1800 3500 1800
Text Label 1950 2800 0    60   ~ 0
FPGA_DONE
Wire Wire Line
	1950 2800 1850 2800
$Comp
L LED D1
U 1 1 59CCC401
P 1300 2800
F 0 "D1" H 1291 3016 50  0000 C CNN
F 1 "GREEN" H 1291 2925 50  0000 C CNN
F 2 "" H 1300 2800 50  0000 C CNN
F 3 "" H 1300 2800 50  0000 C CNN
	1    1300 2800
	1    0    0    -1  
$EndComp
Wire Wire Line
	1450 2800 1550 2800
Text Label 1000 2800 2    60   ~ 0
GND
Wire Wire Line
	1000 2800 1150 2800
$Comp
L R R2
U 1 1 59CCC6A5
P 1700 3100
F 0 "R2" V 1600 3100 50  0000 C CNN
F 1 "1k" V 1700 3100 50  0000 C CNN
F 2 "" V 1630 3100 50  0000 C CNN
F 3 "" H 1700 3100 50  0000 C CNN
	1    1700 3100
	0    1    1    0   
$EndComp
Text Label 3350 1900 2    60   ~ 0
PROG_B_N
Wire Wire Line
	3350 1900 3500 1900
Text Label 1450 3100 2    60   ~ 0
2V5
Text Label 1950 3100 0    60   ~ 0
PROG_B_N
Wire Wire Line
	1950 3100 1850 3100
Wire Wire Line
	1450 3100 1550 3100
Wire Wire Line
	3350 2100 3500 2100
Wire Wire Line
	3500 2200 3400 2200
Wire Wire Line
	3400 2100 3400 2800
Connection ~ 3400 2100
Wire Wire Line
	3400 2300 3500 2300
Connection ~ 3400 2200
Wire Wire Line
	3400 2400 3500 2400
Connection ~ 3400 2300
Wire Wire Line
	3400 2500 3500 2500
Connection ~ 3400 2400
Wire Wire Line
	3400 2600 3500 2600
Connection ~ 3400 2500
Wire Wire Line
	3400 2700 3500 2700
Connection ~ 3400 2600
Wire Wire Line
	3400 2800 3500 2800
Connection ~ 3400 2700
Wire Wire Line
	3350 3000 3500 3000
Wire Wire Line
	3400 3000 3400 5500
Wire Wire Line
	3400 3100 3500 3100
Connection ~ 3400 3000
Wire Wire Line
	3400 3200 3500 3200
Connection ~ 3400 3100
Wire Wire Line
	3400 3300 3500 3300
Connection ~ 3400 3200
Wire Wire Line
	3400 3400 3500 3400
Connection ~ 3400 3300
Wire Wire Line
	3400 3500 3500 3500
Connection ~ 3400 3400
Text Label 3350 1100 2    60   ~ 0
JTAG_TMS
Wire Wire Line
	3350 1100 3500 1100
Text Label 3350 1200 2    60   ~ 0
JTAG_TDO
Wire Wire Line
	3350 1200 3500 1200
Text Label 3350 1300 2    60   ~ 0
JTAG_TDI
Wire Wire Line
	3350 1300 3500 1300
Text Label 3350 1400 2    60   ~ 0
JTAG_TCK
Wire Wire Line
	3350 1400 3500 1400
Wire Wire Line
	3400 3600 3500 3600
Connection ~ 3400 3500
Wire Wire Line
	3400 3700 3500 3700
Connection ~ 3400 3600
Wire Wire Line
	3400 3800 3500 3800
Connection ~ 3400 3700
Wire Wire Line
	3400 3900 3500 3900
Connection ~ 3400 3800
Wire Wire Line
	3400 4000 3500 4000
Connection ~ 3400 3900
Wire Wire Line
	3400 4100 3500 4100
Connection ~ 3400 4000
Wire Wire Line
	3400 4200 3500 4200
Connection ~ 3400 4100
Wire Wire Line
	3400 4300 3500 4300
Connection ~ 3400 4200
Wire Wire Line
	3400 4400 3500 4400
Connection ~ 3400 4300
Wire Wire Line
	3400 4500 3500 4500
Connection ~ 3400 4400
Wire Wire Line
	3400 4600 3500 4600
Connection ~ 3400 4500
Wire Wire Line
	3400 4700 3500 4700
Connection ~ 3400 4600
Wire Wire Line
	3400 4800 3500 4800
Connection ~ 3400 4700
Wire Wire Line
	3400 4900 3500 4900
Connection ~ 3400 4800
Wire Wire Line
	3400 5000 3500 5000
Connection ~ 3400 4900
Wire Wire Line
	3400 5100 3500 5100
Connection ~ 3400 5000
Wire Wire Line
	3400 5200 3500 5200
Connection ~ 3400 5100
Wire Wire Line
	3400 5300 3500 5300
Connection ~ 3400 5200
Wire Wire Line
	3400 5400 3500 5400
Connection ~ 3400 5300
Wire Wire Line
	3400 5500 3500 5500
Connection ~ 3400 5400
Text HLabel 3350 2100 0    60   Input ~ 0
2V5
Text HLabel 3350 3000 0    60   Input ~ 0
GND
Text HLabel 6000 1100 2    60   Input ~ 0
1V2
Wire Wire Line
	6000 1100 5800 1100
Wire Wire Line
	5900 1100 5900 1800
Wire Wire Line
	5900 1200 5800 1200
Connection ~ 5900 1100
Wire Wire Line
	5900 1300 5800 1300
Connection ~ 5900 1200
Wire Wire Line
	5900 1400 5800 1400
Connection ~ 5900 1300
Wire Wire Line
	5900 1500 5800 1500
Connection ~ 5900 1400
Wire Wire Line
	5900 1600 5800 1600
Connection ~ 5900 1500
Wire Wire Line
	5900 1700 5800 1700
Connection ~ 5900 1600
Wire Wire Line
	5900 1800 5800 1800
Connection ~ 5900 1700
Text HLabel 6000 2000 2    60   Input ~ 0
3V3
Wire Wire Line
	6000 2000 5800 2000
Wire Wire Line
	5900 2000 5900 3900
Wire Wire Line
	5900 2100 5800 2100
Connection ~ 5900 2000
Wire Wire Line
	5900 2200 5800 2200
Connection ~ 5900 2100
Wire Wire Line
	5900 2300 5800 2300
Connection ~ 5900 2200
Wire Wire Line
	5900 2400 5800 2400
Connection ~ 5900 2300
Wire Wire Line
	5900 2500 5800 2500
Connection ~ 5900 2400
Wire Wire Line
	5900 2600 5800 2600
Connection ~ 5900 2500
Wire Wire Line
	5900 2700 5800 2700
Connection ~ 5900 2600
Wire Wire Line
	5900 2800 5800 2800
Connection ~ 5900 2700
Wire Wire Line
	5900 2900 5800 2900
Connection ~ 5900 2800
Wire Wire Line
	5900 3000 5800 3000
Connection ~ 5900 2900
Wire Wire Line
	5900 3100 5800 3100
Connection ~ 5900 3000
Wire Wire Line
	5900 3200 5800 3200
Connection ~ 5900 3100
Wire Wire Line
	5900 3300 5800 3300
Connection ~ 5900 3200
Wire Wire Line
	5900 3400 5800 3400
Connection ~ 5900 3300
Wire Wire Line
	5900 3500 5800 3500
Connection ~ 5900 3400
Wire Wire Line
	5900 3600 5800 3600
Connection ~ 5900 3500
Wire Wire Line
	5900 3700 5800 3700
Connection ~ 5900 3600
Wire Wire Line
	5900 3800 5800 3800
Connection ~ 5900 3700
Wire Wire Line
	5900 3900 5800 3900
Connection ~ 5900 3800
$EndSCHEMATC
