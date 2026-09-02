EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Text Notes 2050 1800 0    50   ~ 0
Connect to GPIO18, GND  on pins 12,14 of pi IO header
$Comp
L Connector:Conn_01x02 J1
U 1 1 5E893C2B
P 2100 2100
F 0 "J1" H 2018 2317 50  0000 C CNN
F 1 "Conn_01x02" H 2018 2226 50  0000 C CNN
F 2 "azonenberg_pcb:CONN_HEADER_2.54MM_1x2" H 2100 2100 50  0001 C CNN
F 3 "~" H 2100 2100 50  0001 C CNN
	1    2100 2100
	-1   0    0    -1  
$EndComp
Text Label 2300 2100 0    50   ~ 0
GPIO18
Text Label 2300 2200 0    50   ~ 0
GND
$Comp
L special-azonenberg:SSM6N58NU_DUAL_NMOS Q1
U 1 1 5E894BBD
P 3000 2600
F 0 "Q1" H 3144 2706 60  0000 L CNN
F 1 "SSM6N58NU_DUAL_NMOS" H 3144 2600 60  0000 L CNN
F 2 "azonenberg_pcb:DFN_6_0.65MM_2x2MM_GDS" H 3000 2600 60  0001 C CNN
F 3 "transistors/mos/*.*" H 3144 2494 60  0000 L CNN
	1    3000 2600
	1    0    0    -1  
$EndComp
Text Label 3100 3050 2    50   ~ 0
GND
Wire Wire Line
	3100 3050 3100 2800
Text Label 2800 2600 2    50   ~ 0
GPIO18
$Comp
L Connector:Conn_01x02 J2
U 1 1 5E8951B8
P 3850 2100
F 0 "J2" H 3930 2092 50  0000 L CNN
F 1 "Conn_01x02" H 3930 2001 50  0000 L CNN
F 2 "azonenberg_pcb:CONN_HEADER_1.27MM_1X2" H 3850 2100 50  0001 C CNN
F 3 "~" H 3850 2100 50  0001 C CNN
	1    3850 2100
	1    0    0    -1  
$EndComp
Text Label 3650 2200 2    50   ~ 0
GND
Text Label 3650 2100 2    50   ~ 0
SWITCH
Wire Wire Line
	3650 2100 3100 2100
Wire Wire Line
	3100 2100 3100 2400
$EndSCHEMATC
