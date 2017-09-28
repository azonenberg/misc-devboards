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
$Descr A3 16535 11693
encoding utf-8
Sheet 3 5
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
L BEL_FUSE_0826-1G1T-23-F J2
U 1 1 59CAC92C
P 13750 3500
F 0 "J2" H 13750 3300 60  0000 L CNN
F 1 "BEL_FUSE_0826-1G1T-23-F" H 13750 3200 60  0000 L CNN
F 2 "" H 13750 3500 60  0000 C CNN
F 3 "" H 13750 3500 60  0000 C CNN
	1    13750 3500
	1    0    0    -1  
$EndComp
$Comp
L XC6SLX25-xFTG256-SEG U?
U 1 1 59CB3C9C
P 1700 3800
AR Path="/59CABCCC/59CB3C9C" Ref="U?"  Part="5" 
AR Path="/59CABCD8/59CB3C9C" Ref="U1"  Part="1" 
F 0 "U1" H 1700 6987 60  0000 C CNN
F 1 "XC6SLX25-2FTG256C" H 1700 6881 60  0000 C CNN
F 2 "" H 1700 3800 60  0000 C CNN
F 3 "" H 1700 3800 60  0000 C CNN
	1    1700 3800
	-1   0    0    -1  
$EndComp
Text Label 13200 2900 2    60   ~ 0
TX_TAP
Text Label 13200 2800 2    60   ~ 0
TX_P
Text Label 13200 3000 2    60   ~ 0
TX_N
Text Label 13200 2400 2    60   ~ 0
RX_P
Text Label 13200 2600 2    60   ~ 0
RX_N
Text Label 13200 2500 2    60   ~ 0
RX_TAP
Text Notes 13450 1200 0    60   ~ 0
RJ45 pinout for 100baseT:\n* Pin 1/2 (rightmost on device end) = TX\n* Pin 3-6 (split) = RX\n* Pin 4-5 (middle) = unused\n* pin 7-9 (left) = unused
Text Notes 13750 4100 0    60   ~ 0
TODO: confirm correct pair\nassignments before layout
NoConn ~ 13450 2000
NoConn ~ 13450 2100
NoConn ~ 13450 2200
NoConn ~ 13450 3200
NoConn ~ 13450 3300
NoConn ~ 13450 3400
Text HLabel 13650 4450 0    60   Input ~ 0
3V3
Text HLabel 13650 5150 0    60   Input ~ 0
GND
$Comp
L R R15
U 1 1 59CB410F
P 13800 4600
F 0 "R15" H 13870 4646 50  0000 L CNN
F 1 "1k" H 13870 4555 50  0000 L CNN
F 2 "" V 13730 4600 50  0000 C CNN
F 3 "" H 13800 4600 50  0000 C CNN
	1    13800 4600
	1    0    0    -1  
$EndComp
$Comp
L R R16
U 1 1 59CB419E
P 13800 5000
F 0 "R16" H 13870 5046 50  0000 L CNN
F 1 "1k" H 13870 4955 50  0000 L CNN
F 2 "" V 13730 5000 50  0000 C CNN
F 3 "" H 13800 5000 50  0000 C CNN
	1    13800 5000
	1    0    0    -1  
$EndComp
Text Label 13650 4800 2    60   ~ 0
RX_TAP
Text Label 14550 4800 0    60   ~ 0
TX_TAP
$Comp
L R R17
U 1 1 59CB4294
P 14350 4600
F 0 "R17" H 14420 4646 50  0000 L CNN
F 1 "1k" H 14420 4555 50  0000 L CNN
F 2 "" V 14280 4600 50  0000 C CNN
F 3 "" H 14350 4600 50  0000 C CNN
	1    14350 4600
	1    0    0    -1  
$EndComp
$Comp
L R R18
U 1 1 59CB42C4
P 14350 5000
F 0 "R18" H 14420 5046 50  0000 L CNN
F 1 "1k" H 14420 4955 50  0000 L CNN
F 2 "" V 14280 5000 50  0000 C CNN
F 3 "" H 14350 5000 50  0000 C CNN
	1    14350 5000
	1    0    0    -1  
$EndComp
Text Label 9400 1750 0    60   ~ 0
TX_P
$Comp
L R R7
U 1 1 59CB47F1
P 9000 1550
F 0 "R7" H 9070 1596 50  0000 L CNN
F 1 "115" H 9070 1505 50  0000 L CNN
F 2 "" V 8930 1550 50  0000 C CNN
F 3 "" H 9000 1550 50  0000 C CNN
	1    9000 1550
	1    0    0    -1  
$EndComp
Text Label 9400 1400 0    60   ~ 0
TX_P_A
Text Label 9400 2800 0    60   ~ 0
TX_N
$Comp
L R R8
U 1 1 59CB7CAC
P 9000 3000
F 0 "R8" H 9070 3046 50  0000 L CNN
F 1 "115" H 9070 2955 50  0000 L CNN
F 2 "" V 8930 3000 50  0000 C CNN
F 3 "" H 9000 3000 50  0000 C CNN
	1    9000 3000
	1    0    0    -1  
$EndComp
Text Label 9400 3150 0    60   ~ 0
TX_N_A
Text Notes 5900 2800 0    60   ~ 0
For 10baseT we need to drive 2.5V\ndifferential into a 100 ohm load.\nThis is 25 mA output current. We probably\nneed to parallel 2 drivers.\n\nWith a 3.3V supply we need 132 ohm total loading\nThis is 16 ohms each above and below the 100.\n\nTX_P_B high, TX_N_B low:\n* TX_P = 2.9V\n* TX_N = 0.4V\n* Vd = 2.5V\n\nTX_P_B low, TX_N_B high:\n* TX_P = 0.4V\n* TX_N = 2.9V\n* Vd = -2.5V
Text Notes 10200 3200 0    60   ~ 0
For 100baseT we need to drive 1V\ndifferential into a 100 ohm load.\nThis is 10 mA output current.\n\nWith a 3.3V supply we need 330 ohm total loading\n100 of that is the differential terminator at the far end\n115 ohms above and below the 100\n\nTX_P_A high, TX_N_A low:\n* TX_P = 2.15V\n* TX_N = 1.15V\n* Vd = +1V\n\nTX_P_A low, TX_N_A high:\n* TX_P = 1.15V\n* TX_N = 2.15V\n* Vd = -1V\n\nTX_P_A and TX_N_A floating:\n* TX_P = 1.65V\n* TX_N = 1.65V\n* Vd = 0V
Text Notes 9100 2250 0    60   ~ 0
100
Text Notes 13750 5300 0    60   ~ 0
Vdd/2 bias on diffpairs
Text Label 8350 1400 2    60   ~ 0
TX_P_B
$Comp
L R R5
U 1 1 59CC3ADE
P 8500 1550
F 0 "R5" H 8570 1596 50  0000 L CNN
F 1 "16" H 8570 1505 50  0000 L CNN
F 2 "" V 8430 1550 50  0000 C CNN
F 3 "" H 8500 1550 50  0000 C CNN
	1    8500 1550
	1    0    0    -1  
$EndComp
$Comp
L R R6
U 1 1 59CC3B97
P 8500 3000
F 0 "R6" H 8570 3046 50  0000 L CNN
F 1 "16" H 8570 2955 50  0000 L CNN
F 2 "" V 8430 3000 50  0000 C CNN
F 3 "" H 8500 3000 50  0000 C CNN
	1    8500 3000
	1    0    0    -1  
$EndComp
Text Label 8350 3150 2    60   ~ 0
TX_N_B
Text Label 3150 1100 0    60   ~ 0
TX_P_B
Text Label 3150 1200 0    60   ~ 0
TX_N_B
Text Label 3150 1500 0    60   ~ 0
TX_P_A
Text Label 3150 2300 0    60   ~ 0
TX_N_A
Text Label 13200 1500 2    60   ~ 0
LED1_P
Text Label 13200 1600 2    60   ~ 0
LED1_N
Text Label 13200 1700 2    60   ~ 0
LED2_P
Text Label 13200 1800 2    60   ~ 0
LED2_N
Text Label 12900 3600 2    60   ~ 0
GND
$Comp
L R R14
U 1 1 59CC624C
P 13050 3600
F 0 "R14" V 12843 3600 50  0000 C CNN
F 1 "0" V 12934 3600 50  0000 C CNN
F 2 "" V 12980 3600 50  0000 C CNN
F 3 "" H 13050 3600 50  0000 C CNN
	1    13050 3600
	0    1    1    0   
$EndComp
Text Notes 4700 6750 0    60   ~ 0
RX side: \nWe expect the following voltages (ideal, w/ no cable loss):\n* P=2.9, N=0.4 (10bT differential 1)\n* P=2.15, N=1.15 (100bT differential 1)\n* P = 1.65, N=1.65 (differential 0)\n* P=1.15, N=2.15 (100bT differential -1)\n* P=0.4, N=2.9 (10bT differential -1)\n\nWe do not care about distinguishing the 10M\nand 100M high or low states.\nSet decision points at 1.8 and 1.5V\n(+/- 150 mV from center, or 300 mV differential)\n\n* Above 1.8: differential 1\n* Above 1.5, below 1.8: differential 0\n* Below 1.5: differential -1\n\nNominal decision point values w/ 1% resistors:\n* 1.495V\n* 1.805V\n\nAlthough only RX_P is required for this receiver,\nhooking up RX_N allows a "second opinion" which\nmight end up being useful for noise or baseline\nwander reduction.
$Comp
L R R3
U 1 1 59CC6B3F
P 3300 900
F 0 "R3" V 3200 850 50  0000 C CNN
F 1 "1k" V 3300 900 50  0000 C CNN
F 2 "" V 3230 900 50  0000 C CNN
F 3 "" H 3300 900 50  0000 C CNN
	1    3300 900 
	0    1    1    0   
$EndComp
Text Label 3650 900  0    60   ~ 0
3V3
NoConn ~ 2850 1000
NoConn ~ 2850 4800
NoConn ~ 2850 4700
NoConn ~ 2850 4400
NoConn ~ 2850 4300
NoConn ~ 2850 3800
NoConn ~ 2850 3700
NoConn ~ 2850 3200
NoConn ~ 2850 3100
NoConn ~ 2850 3000
NoConn ~ 2850 2900
NoConn ~ 2850 1800
NoConn ~ 2850 1700
$Comp
L R R4
U 1 1 59CC7521
P 8300 4850
F 0 "R4" H 8370 4896 50  0000 L CNN
F 1 "100" H 8370 4805 50  0000 L CNN
F 2 "" V 8230 4850 50  0000 C CNN
F 3 "" H 8300 4850 50  0000 C CNN
	1    8300 4850
	1    0    0    -1  
$EndComp
Text Label 8050 4450 2    60   ~ 0
RX_P
Text Label 8050 5300 2    60   ~ 0
RX_N
$Comp
L R R9
U 1 1 59CC839A
P 9050 4600
F 0 "R9" H 9120 4646 50  0000 L CNN
F 1 "2.26k" H 9120 4555 50  0000 L CNN
F 2 "" V 8980 4600 50  0000 C CNN
F 3 "" H 9050 4600 50  0000 C CNN
	1    9050 4600
	1    0    0    -1  
$EndComp
Text Label 8850 4450 2    60   ~ 0
3V3
$Comp
L R R11
U 1 1 59CC84BA
P 9050 5400
F 0 "R11" H 9120 5446 50  0000 L CNN
F 1 "2.26k" H 9120 5355 50  0000 L CNN
F 2 "" V 8980 5400 50  0000 C CNN
F 3 "" H 9050 5400 50  0000 C CNN
	1    9050 5400
	1    0    0    -1  
$EndComp
$Comp
L R R10
U 1 1 59CC8559
P 9050 5000
F 0 "R10" H 9120 5046 50  0000 L CNN
F 1 "470" H 9120 4955 50  0000 L CNN
F 2 "" V 8980 5000 50  0000 C CNN
F 3 "" H 9050 5000 50  0000 C CNN
	1    9050 5000
	1    0    0    -1  
$EndComp
Text Label 9450 4800 0    60   ~ 0
VREF_1V8
Text Label 9450 5200 0    60   ~ 0
VREF_1V5
Text Label 8850 5550 2    60   ~ 0
GND
Text Label 3150 2500 0    60   ~ 0
RX_P
Text Label 3150 2600 0    60   ~ 0
VREF_1V8
Text Notes 2550 750  0    60   ~ 0
Outputs are LVCMOS33 24 mA drive.\nInputs are LVDS_33
Text Label 3150 2800 0    60   ~ 0
VREF_1V5
Text Label 3150 2700 0    60   ~ 0
RX_P
Text Label 3150 1900 0    60   ~ 0
RX_N
Text Label 3150 2000 0    60   ~ 0
VREF_1V8
Text Label 3150 2200 0    60   ~ 0
VREF_1V5
Text Label 3150 2100 0    60   ~ 0
RX_N
NoConn ~ 2850 1300
NoConn ~ 2850 1400
$Comp
L CONN_01X10 P1
U 1 1 59CC9B39
P 1300 7150
F 0 "P1" H 1378 7191 50  0000 L CNN
F 1 "CONN_01X10" H 1378 7100 50  0000 L CNN
F 2 "" H 1300 7150 50  0000 C CNN
F 3 "" H 1300 7150 50  0000 C CNN
	1    1300 7150
	-1   0    0    -1  
$EndComp
Text Label 1650 7600 0    60   ~ 0
GND
Text Label 1650 7500 0    60   ~ 0
3V3
Text Label 12150 4850 0    60   ~ 0
LED1_N
Text Label 11750 4850 2    60   ~ 0
LED2_N
$Comp
L R R12
U 1 1 59CCA011
P 11750 5000
F 0 "R12" H 11820 5046 50  0000 L CNN
F 1 "470" H 11820 4955 50  0000 L CNN
F 2 "" V 11680 5000 50  0000 C CNN
F 3 "" H 11750 5000 50  0000 C CNN
	1    11750 5000
	1    0    0    -1  
$EndComp
Text Label 11550 5150 2    60   ~ 0
GND
$Comp
L R R13
U 1 1 59CCA227
P 12150 5000
F 0 "R13" H 12220 5046 50  0000 L CNN
F 1 "470" H 12220 4955 50  0000 L CNN
F 2 "" V 12080 5000 50  0000 C CNN
F 3 "" H 12150 5000 50  0000 C CNN
	1    12150 5000
	1    0    0    -1  
$EndComp
Text Label 3150 3500 0    60   ~ 0
LED1_P
Text Label 3150 3600 0    60   ~ 0
LED2_P
Text Label 1650 6700 0    60   ~ 0
GPIO0
Text Label 1650 6800 0    60   ~ 0
GPIO1
Text Label 1650 6900 0    60   ~ 0
GPIO2
Text Label 1650 7000 0    60   ~ 0
GPIO3
Text Label 1650 7100 0    60   ~ 0
GPIO4
Text Label 1650 7200 0    60   ~ 0
GPIO5
Text Label 1650 7300 0    60   ~ 0
GPIO6
Text Label 1650 7400 0    60   ~ 0
GPIO7
Text Label 3150 3900 0    60   ~ 0
GPIO0
Text Label 3150 4000 0    60   ~ 0
GPIO1
Text Label 3150 4100 0    60   ~ 0
GPIO2
Text Label 3150 4200 0    60   ~ 0
GPIO3
Text Label 3150 4500 0    60   ~ 0
GPIO4
Text Label 3150 4600 0    60   ~ 0
GPIO5
Text Label 3150 3300 0    60   ~ 0
GPIO6
Text Label 3150 3400 0    60   ~ 0
GPIO7
Wire Wire Line
	13200 2800 13450 2800
Wire Wire Line
	13450 2900 13200 2900
Wire Wire Line
	13200 3000 13450 3000
Wire Wire Line
	13450 2600 13200 2600
Wire Wire Line
	13200 2500 13450 2500
Wire Wire Line
	13450 2400 13200 2400
Wire Wire Line
	13650 4450 14350 4450
Wire Wire Line
	13800 4750 13800 4850
Wire Wire Line
	13650 5150 14350 5150
Wire Wire Line
	13650 4800 13800 4800
Connection ~ 13800 4800
Wire Wire Line
	14550 4800 14350 4800
Wire Wire Line
	14350 4750 14350 4850
Connection ~ 14350 4800
Connection ~ 13800 4450
Connection ~ 13800 5150
Wire Wire Line
	9400 1400 9000 1400
Wire Wire Line
	9400 3150 9000 3150
Wire Wire Line
	9000 1700 9000 1750
Wire Wire Line
	9000 2850 9000 2800
Wire Notes Line
	9000 1850 9000 2150
Wire Notes Line
	8950 2150 9050 2150
Wire Notes Line
	8950 2150 8950 2350
Wire Notes Line
	8950 2350 9050 2350
Wire Notes Line
	9000 2350 9000 2650
Wire Notes Line
	9050 2350 9050 2150
Wire Wire Line
	8500 1750 9400 1750
Wire Wire Line
	8500 2800 9400 2800
Wire Wire Line
	8350 1400 8500 1400
Wire Wire Line
	8500 1750 8500 1700
Connection ~ 9000 1750
Wire Wire Line
	8350 3150 8500 3150
Wire Wire Line
	8500 2850 8500 2800
Connection ~ 9000 2800
Wire Wire Line
	3150 1100 2850 1100
Wire Wire Line
	2850 1200 3150 1200
Wire Wire Line
	3150 1500 2850 1500
Wire Wire Line
	2850 1600 2950 1600
Wire Wire Line
	2950 1600 2950 1500
Connection ~ 2950 1500
Wire Wire Line
	3150 2300 2850 2300
Wire Wire Line
	2950 2300 2950 2400
Wire Wire Line
	2950 2400 2850 2400
Connection ~ 2950 2300
Wire Wire Line
	13200 1500 13450 1500
Wire Wire Line
	13200 1600 13450 1600
Wire Wire Line
	13200 1700 13450 1700
Wire Wire Line
	13200 1800 13450 1800
Wire Wire Line
	13200 3600 13450 3600
Wire Wire Line
	3150 900  2850 900 
Wire Wire Line
	3650 900  3450 900 
Wire Wire Line
	8050 4450 8300 4450
Wire Wire Line
	8300 4450 8300 4700
Wire Wire Line
	8300 5000 8300 5300
Wire Wire Line
	8300 5300 8050 5300
Wire Wire Line
	8850 4450 9050 4450
Wire Wire Line
	8850 5550 9050 5550
Wire Wire Line
	9450 5200 9050 5200
Connection ~ 9050 5200
Wire Wire Line
	9050 5150 9050 5250
Wire Wire Line
	9050 4850 9050 4750
Wire Wire Line
	9450 4800 9050 4800
Connection ~ 9050 4800
Wire Wire Line
	3150 2500 2850 2500
Wire Wire Line
	3150 2600 2850 2600
Wire Wire Line
	3150 2700 2850 2700
Wire Wire Line
	2850 2800 3150 2800
Wire Wire Line
	3150 1900 2850 1900
Wire Wire Line
	3150 2000 2850 2000
Wire Wire Line
	3150 2100 2850 2100
Wire Wire Line
	2850 2200 3150 2200
Wire Wire Line
	1650 7600 1500 7600
Wire Wire Line
	1650 7500 1500 7500
Wire Wire Line
	11550 5150 12150 5150
Connection ~ 11750 5150
Wire Wire Line
	3150 3600 2850 3600
Wire Wire Line
	2850 3500 3150 3500
Wire Wire Line
	1650 7400 1500 7400
Wire Wire Line
	1500 7300 1650 7300
Wire Wire Line
	1650 7200 1500 7200
Wire Wire Line
	1500 7100 1650 7100
Wire Wire Line
	1650 7000 1500 7000
Wire Wire Line
	1500 6900 1650 6900
Wire Wire Line
	1650 6800 1500 6800
Wire Wire Line
	1500 6700 1650 6700
Wire Wire Line
	2850 3400 3150 3400
Wire Wire Line
	2850 3300 3150 3300
Wire Wire Line
	2850 4500 3150 4500
Wire Wire Line
	2850 4200 3150 4200
Wire Wire Line
	2850 4100 3150 4100
Wire Wire Line
	2850 4000 3150 4000
Wire Wire Line
	2850 3900 3150 3900
Wire Wire Line
	2850 4600 3150 4600
$Comp
L BEL_FUSE_0826-1G1T-23-F J3
U 1 1 59CD49F0
P 13800 9100
F 0 "J3" H 14278 10128 60  0000 L CNN
F 1 "BEL_FUSE_0826-1G1T-23-F" H 14278 10022 60  0000 L CNN
F 2 "" H 13800 9100 60  0000 C CNN
F 3 "" H 13800 9100 60  0000 C CNN
	1    13800 9100
	1    0    0    -1  
$EndComp
NoConn ~ 13500 7100
NoConn ~ 13500 7200
NoConn ~ 13500 7300
NoConn ~ 13500 7400
Text Notes 13800 9350 0    60   ~ 0
Second RJ45 for easy scope probing
NoConn ~ 13500 8400
NoConn ~ 13500 8500
NoConn ~ 13500 8600
NoConn ~ 13500 8800
NoConn ~ 13500 8900
NoConn ~ 13500 9000
NoConn ~ 13500 7800
NoConn ~ 13500 7700
NoConn ~ 13500 7600
$Comp
L R R31
U 1 1 59CD4FC3
P 12100 8250
F 0 "R31" H 12170 8296 50  0000 L CNN
F 1 "1k" H 12170 8205 50  0000 L CNN
F 2 "" V 12030 8250 50  0000 C CNN
F 3 "" H 12100 8250 50  0000 C CNN
	1    12100 8250
	1    0    0    -1  
$EndComp
$Comp
L R R30
U 1 1 59CD50E1
P 12100 7950
F 0 "R30" H 12170 7996 50  0000 L CNN
F 1 "1k" H 12170 7905 50  0000 L CNN
F 2 "" V 12030 7950 50  0000 C CNN
F 3 "" H 12100 7950 50  0000 C CNN
	1    12100 7950
	1    0    0    -1  
$EndComp
Wire Wire Line
	12100 8100 13500 8100
Text Label 11900 7800 2    60   ~ 0
3V3
Wire Wire Line
	11900 7800 12100 7800
Text Label 11900 8400 2    60   ~ 0
GND
Wire Wire Line
	11900 8400 12100 8400
Text Label 12950 9200 2    60   ~ 0
GND
$Comp
L R R32
U 1 1 59CD5805
P 13100 9200
F 0 "R32" V 12893 9200 50  0000 C CNN
F 1 "0" V 12984 9200 50  0000 C CNN
F 2 "" V 13030 9200 50  0000 C CNN
F 3 "" H 13100 9200 50  0000 C CNN
	1    13100 9200
	0    1    1    0   
$EndComp
Wire Wire Line
	13250 9200 13500 9200
Text Label 13050 8000 2    60   ~ 0
TAP_RX_P
Wire Wire Line
	13050 8000 13500 8000
Text Label 11300 8250 2    60   ~ 0
TAP_RX_N
Wire Wire Line
	13050 8200 13500 8200
$Comp
L BNC P2
U 1 1 59CD5D74
P 13250 7850
F 0 "P2" V 13251 7951 50  0000 L CNN
F 1 "SMA" V 13160 7951 50  0000 L CNN
F 2 "" H 13250 7850 50  0000 C CNN
F 3 "" H 13250 7850 50  0000 C CNN
	1    13250 7850
	0    1    -1   0   
$EndComp
Connection ~ 13250 8000
$Comp
L BNC P3
U 1 1 59CD6248
P 13250 8350
F 0 "P3" V 13159 8451 50  0000 L CNN
F 1 "SMA" V 13250 8451 50  0000 L CNN
F 2 "" H 13250 8350 50  0000 C CNN
F 3 "" H 13250 8350 50  0000 C CNN
	1    13250 8350
	0    1    1    0   
$EndComp
Connection ~ 13250 8200
Text Label 13050 7850 2    60   ~ 0
GND
Text Label 13050 8350 2    60   ~ 0
GND
Text Label 11300 7950 2    60   ~ 0
TAP_RX_P
$Comp
L R R29
U 1 1 59CD678C
P 11450 8100
F 0 "R29" H 11520 8146 50  0000 L CNN
F 1 "100" H 11520 8055 50  0000 L CNN
F 2 "" V 11380 8100 50  0000 C CNN
F 3 "" H 11450 8100 50  0000 C CNN
	1    11450 8100
	1    0    0    -1  
$EndComp
Wire Wire Line
	11300 7950 11450 7950
Wire Wire Line
	11300 8250 11450 8250
Text Label 13050 8200 2    60   ~ 0
TAP_RX_N
$EndSCHEMATC
