#!/bin/bash
LINE=`ls -lh firmware.bin | cut -d ' ' -f 5`
echo "Flash memory usage:     $LINE";

ITCMSTART=$(arm-none-eabi-objdump -t firmware.elf  | grep __itcm_start | cut -d ' ' -f 1);
ITCMEND=$(arm-none-eabi-objdump -t firmware.elf  | grep __itcm_end | cut -d ' ' -f 1);
TCMSTART=$(arm-none-eabi-objdump -t firmware.elf  | grep __tcmstart | cut -d ' ' -f 1);
STACKSTART=$(arm-none-eabi-objdump -t firmware.elf  | grep __end | cut -d ' ' -f 1);
STACKEND=$(arm-none-eabi-objdump -t firmware.elf  | grep __stack | cut -d ' ' -f 1);
DTCMSTART=$(echo "obase=10;ibase=16;${TCMSTART^^}" | bc);
XITCMSTART=$(echo "obase=10;ibase=16;${ITCMSTART^^}" | bc);
XITCMEND=$(echo "obase=10;ibase=16;${ITCMEND^^}" | bc);
DSTACKSTART=$(echo "obase=10;ibase=16;${STACKSTART^^}" | bc);
DSTACKEND=$(echo "obase=10;ibase=16;${STACKEND^^}" | bc);
STACKSIZE=$(expr $DSTACKEND - $DSTACKSTART);
STACKKB=$(expr $STACKSIZE / 1024);
echo "Stack size:             $STACKKB kB";

DATASTART=$(arm-none-eabi-objdump -t firmware.elf  | grep __data_start | cut -d ' ' -f 1);
DATAEND=$(arm-none-eabi-objdump -t firmware.elf  | grep __data_end | cut -d ' ' -f 1);
DDATASTART=$(echo "obase=10;ibase=16;${DATASTART^^}" | bc);
DDATAEND=$(echo "obase=10;ibase=16;${DATAEND^^}" | bc);
DATASIZE=$(expr $DDATAEND - $DDATASTART);
DATAKB=$(expr $DATASIZE / 1024);
echo "Global AXI data size:   $DATASIZE bytes";

BSSSTART=$(arm-none-eabi-objdump -t firmware.elf  | grep __bss_start | cut -d ' ' -f 1);
BSSEND=$(arm-none-eabi-objdump -t firmware.elf  | grep __bss_end | cut -d ' ' -f 1);
DBSSSTART=$(echo "obase=10;ibase=16;${BSSSTART^^}" | bc);
DBSSEND=$(echo "obase=10;ibase=16;${BSSEND^^}" | bc);
BSSSIZE=$(expr $DBSSEND - $DBSSSTART);
BSSKB=$(expr $BSSSIZE / 1024);
echo "Global AXI BSS size:    $BSSSIZE bytes";

TCMSIZE=$(expr $DSTACKSTART - $DTCMSTART);
echo "Global TCM BSS size:    $TCMSIZE bytes";

GLOBALSIZE=$(expr $DATASIZE + $BSSSIZE + $TCMSIZE);
GLOBALKB=$(expr $GLOBALSIZE / 1024);
echo "Total global size:      $GLOBALSIZE bytes";

ITCMSIZE=$(expr $XITCMEND - $XITCMSTART);
echo "ITCM usage:             $ITCMSIZE bytes";
