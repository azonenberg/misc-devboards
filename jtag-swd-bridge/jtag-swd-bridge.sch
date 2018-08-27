EESchema Schematic File Version 4
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "Digilent 6-pin JTAG to 4-pin SWD"
Date "2018-08-27"
Rev "0.1"
Comp "Andrew D. Zonenberg"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L conn:CONN_01X06 J1
U 1 1 5B8430FC
P 1500 1600
F 0 "J1" H 1419 1125 50  0000 C CNN
F 1 "CONN_01X06" H 1419 1216 50  0000 C CNN
F 2 "azonenberg_pcb:CONN_HEADER_2.54MM_1x6" H 1500 1600 50  0001 C CNN
F 3 "" H 1500 1600 50  0001 C CNN
	1    1500 1600
	-1   0    0    1   
$EndComp
Text Label 1700 1450 0    50   ~ 0
TDI
Text Label 1700 1550 0    50   ~ 0
TDO
Text Label 1700 1650 0    50   ~ 0
TCK
Text Label 1700 1750 0    50   ~ 0
GND
Text Label 1700 1850 0    50   ~ 0
VDD
$Comp
L device:R R1
U 1 1 5B8431B6
P 2150 1450
F 0 "R1" V 2050 1450 50  0000 C CNN
F 1 "100" V 2150 1450 50  0000 C CNN
F 2 "azonenberg_pcb:EIA_0402_RES_NOSILK" V 2080 1450 50  0001 C CNN
F 3 "" H 2150 1450 50  0001 C CNN
	1    2150 1450
	0    1    1    0   
$EndComp
Wire Wire Line
	1700 1450 2000 1450
Wire Wire Line
	1700 1550 2400 1550
Wire Wire Line
	2300 1450 2400 1450
Wire Wire Line
	2400 1450 2400 1550
Connection ~ 2400 1550
Wire Wire Line
	2400 1550 2500 1550
Wire Wire Line
	1700 1650 2500 1650
Wire Wire Line
	2500 1750 1700 1750
Wire Wire Line
	1700 1850 2500 1850
NoConn ~ 1700 1350
Text Notes 1800 1350 0    50   ~ 0
TMS
$Comp
L conn:CONN_01X04 J2
U 1 1 5B8434D0
P 2700 1700
F 0 "J2" H 2778 1741 50  0000 L CNN
F 1 "CONN_01X04" H 2778 1650 50  0000 L CNN
F 2 "azonenberg_pcb:CONN_HEADER_2.54MM_1x4" H 2700 1700 50  0001 C CNN
F 3 "" H 2700 1700 50  0001 C CNN
	1    2700 1700
	1    0    0    -1  
$EndComp
$EndSCHEMATC
