SRCDIR=$(CURDIR)
ROOTDIR=$(CURDIR)/../../../
CXXFLAGS=-g -O3 --std=c++20 -Wall -Wextra \
	-fno-threadsafe-statics \
	-I$(ROOTDIR) \
	-I$(SRCDIR) \
	-I$(ROOTDIR)/stm32-cpp/devices/inc \
	-I$(ROOTDIR)/stm32-cpp/src \
	-I$(ROOTDIR)/antikernel-ipcores/cpp-wrappers \
	-I$(ROOTDIR)/common-embedded-platform/ \
	-I$(SRCDIR)/../bsp-main/ \
	-DMICROKVS_WRITE_BLOCK_SIZE=32 \
	-DTEST_BANK_SIZE=131072 \
	-DMAX_TOKEN_LEN=96 \
	-DLOGGER_USE_RTC_TIMESTAMP \
	-Wl,--wrap=malloc \
	-Wl,--wrap=calloc \
	-Wl,--wrap=realloc \
	-Wl,--wrap=alloca \
	-Wl,--wrap=sbrk_aligned \
	-ffunction-sections
	#-DNO_CLEAR_SCREEN

LDFLAGS=-Wl,-T $(SRCDIR)/firmware.ld \
	 -L$(ROOTDIR)/stm32-cpp/devices/link/ \
	 -L$(SRCDIR) \
	 -Wl,--gc-sections

.ONESHELL:
.SILENT: all

all: CXX=arm-none-eabi-g++
all: CXXFLAGS += -DSTM32H735 -fno-rtti -fno-exceptions --specs nano.specs -mcpu=cortex-m7

all:
	mkdir -p output
	cd output/
	$(CXX) $(CXXFLAGS) -c $(SRCDIR)/*.cpp || exit 1
	#$(CXX) $(CXXFLAGS) -c $(SRCDIR)/net/*.cpp || exit 1
	#$(CXX) $(CXXFLAGS) -c $(SRCDIR)/ssh/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/common-embedded-platform/core/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/common-embedded-platform/services/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(SRCDIR)/../bsp-main/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/microkvs/kvs/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/microkvs/driver/STM32StorageBank.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/embedded-cli/*.cpp || exit 1
	#$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/cli/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/contrib/*.cpp -Wno-type-limits -Wno-implicit-fallthrough|| exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/crypt/*.cpp || exit 1
	#$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/dhcp/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/drivers/base/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/drivers/apb/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/drivers/stm32/STM32CryptoEngine.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/net/arp/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/net/ethernet/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/net/icmpv4/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/net/ipv4/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/net/tcp/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/net/udp/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/ntp/*.cpp || exit 1
	#$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/sftp/*.cpp || exit 1
	#$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/staticnet/ssh/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/stm32-cpp/src/cpu/*.* || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/stm32-cpp/src/cli/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/stm32-cpp/src/newlib-stubs/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/stm32-cpp/src/peripheral/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/embedded-utils/*.cpp || exit 1
	$(CXX) $(CXXFLAGS) -c $(ROOTDIR)/stm32-cpp/devices/src/stm32h735.cpp || exit 1
	$(CXX) $(CXXFLAGS) *.o $(LDFLAGS) -o ../firmware.elf
	cd ../
	arm-none-eabi-objcopy -O binary --only-section=.text --only-section=.rodata --only-section=.data firmware.elf firmware.bin
	./imagesize.sh
	arm-none-eabi-strip -s -o main-stripped.elf firmware.elf
