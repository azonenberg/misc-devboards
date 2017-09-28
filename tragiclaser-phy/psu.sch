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
Sheet 4 5
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
L ADP322 U2
U 1 1 59CAC42E
P 3800 1750
F 0 "U2" H 3775 2497 60  0000 C CNN
F 1 "ADP322ACPZ-145-R7" H 3775 2391 60  0000 C CNN
F 2 "" H 3800 1750 60  0000 C CNN
F 3 "" H 3800 1750 60  0000 C CNN
	1    3800 1750
	1    0    0    -1  
$EndComp
Text HLabel 4750 1250 2    60   Output ~ 0
3V3
Text HLabel 4750 1350 2    60   Output ~ 0
2V5
Text HLabel 4750 1450 2    60   Output ~ 0
1V2
Text HLabel 7150 1500 2    60   Output ~ 0
GND
$Comp
L CONN_3_PWROUT K1
U 1 1 59CD2A85
P 1300 850
F 0 "K1" H 1428 878 50  0000 L CNN
F 1 "CONN_3_PWROUT" H 1428 794 40  0000 L CNN
F 2 "" H 1300 850 60  0000 C CNN
F 3 "" H 1300 850 60  0000 C CNN
	1    1300 850 
	-1   0    0    -1  
$EndComp
NoConn ~ 1650 950 
Text Label 1900 850  0    60   ~ 0
GND
Wire Wire Line
	1900 850  1650 850 
Text Label 1900 750  0    60   ~ 0
5V0
Wire Wire Line
	1900 750  1650 750 
Text Label 2800 1250 2    60   ~ 0
5V0
Wire Wire Line
	2800 1250 3000 1250
Wire Wire Line
	3000 1350 2900 1350
Wire Wire Line
	2900 1250 2900 1450
Connection ~ 2900 1250
Wire Wire Line
	2900 1450 3000 1450
Connection ~ 2900 1350
Text Label 2800 1650 2    60   ~ 0
5V0
Wire Wire Line
	1850 1650 3000 1650
Wire Wire Line
	2900 1650 2900 1850
Wire Wire Line
	2900 1750 3000 1750
Connection ~ 2900 1650
Wire Wire Line
	2900 1850 3000 1850
Connection ~ 2900 1750
$Comp
L C C5
U 1 1 59CD2F8F
P 5700 1350
F 0 "C5" H 5815 1396 50  0000 L CNN
F 1 "4.7 uF" H 5815 1305 50  0000 L CNN
F 2 "" H 5738 1200 50  0000 C CNN
F 3 "" H 5700 1350 50  0000 C CNN
	1    5700 1350
	1    0    0    -1  
$EndComp
$Comp
L C C6
U 1 1 59CD3040
P 6250 1350
F 0 "C6" H 6365 1396 50  0000 L CNN
F 1 "4.7 uF" H 6365 1305 50  0000 L CNN
F 2 "" H 6288 1200 50  0000 C CNN
F 3 "" H 6250 1350 50  0000 C CNN
	1    6250 1350
	1    0    0    -1  
$EndComp
$Comp
L C C7
U 1 1 59CD306A
P 6750 1350
F 0 "C7" H 6865 1396 50  0000 L CNN
F 1 "4.7 uF" H 6865 1305 50  0000 L CNN
F 2 "" H 6788 1200 50  0000 C CNN
F 3 "" H 6750 1350 50  0000 C CNN
	1    6750 1350
	1    0    0    -1  
$EndComp
Wire Wire Line
	5700 1500 7150 1500
Connection ~ 6750 1500
Connection ~ 6250 1500
Text Label 2800 2200 2    60   ~ 0
GND
Wire Wire Line
	2800 2200 3000 2200
Wire Wire Line
	2900 1950 2900 2300
Wire Wire Line
	2900 2300 3000 2300
Connection ~ 2900 2200
$Comp
L C C4
U 1 1 59CD320F
P 2350 1800
F 0 "C4" H 2465 1846 50  0000 L CNN
F 1 "4.7 uF" H 2465 1755 50  0000 L CNN
F 2 "" H 2388 1650 50  0000 C CNN
F 3 "" H 2350 1800 50  0000 C CNN
	1    2350 1800
	1    0    0    -1  
$EndComp
$Comp
L C C3
U 1 1 59CD33C7
P 1850 1800
F 0 "C3" H 1965 1846 50  0000 L CNN
F 1 "4.7 uF" H 1965 1755 50  0000 L CNN
F 2 "" H 1888 1650 50  0000 C CNN
F 3 "" H 1850 1800 50  0000 C CNN
	1    1850 1800
	1    0    0    -1  
$EndComp
Connection ~ 2350 1650
Wire Wire Line
	1850 1950 2900 1950
Connection ~ 2350 1950
Wire Wire Line
	4550 1250 4750 1250
Wire Wire Line
	4750 1350 4550 1350
Wire Wire Line
	4550 1450 4750 1450
Text Label 5550 1200 2    60   ~ 0
3V3
Wire Wire Line
	5550 1200 5700 1200
Text Label 6150 1200 2    60   ~ 0
2V5
Wire Wire Line
	6150 1200 6250 1200
Text Label 6650 1200 2    60   ~ 0
1V2
Wire Wire Line
	6650 1200 6750 1200
$EndSCHEMATC
