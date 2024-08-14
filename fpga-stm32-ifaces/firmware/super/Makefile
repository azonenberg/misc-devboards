SRCDIR=$(CURDIR)
ROOTDIR=$(CURDIR)/../../../
CXXFLAGS=-g -Og --std=c++20 -Wall -Wextra \
	-mcpu=cortex-m4 -march=armv7e-m+fp -mfpu=fpv4-sp-d16 -mfloat-abi=hard \
	-DSTM32L431 \
	-fno-exceptions -fno-rtti -g --specs=nano.specs -fno-threadsafe-statics \
	-I$(ROOTDIR) \
	-I$(SRCDIR) \
	-I$(ROOTDIR)/stm32-cpp/devices/inc \
	-I$(ROOTDIR)/stm32-cpp/src \
	-I$(ROOTDIR)/common-embedded-platform/ \
	-DMICROKVS_WRITE_BLOCK_SIZE=8 \
	-DKVS_NAMELEN=32 \
	-Wl,--wrap=malloc \
	-Wl,--wrap=calloc \
	-Wl,--wrap=realloc \
	-Wl,--wrap=alloca \
	-Wl,--wrap=sbrk_aligned \
	-Wl,--wrap=free \
	-ffunction-sections
	#-DNO_CLEAR_SCREEN

LDFLAGS=-Wl,-T $(ROOTDIR)/stm32-cpp/devices/link/stm32l431.ld \
	 -L$(ROOTDIR)/stm32-cpp/devices/link/ \
	 -Wl,--gc-sections

CXX=arm-none-eabi-g++

.ONESHELL:
.SILENT: all
all:
	mkdir -p build
	cd build
	$(CXX) $(CXXFLAGS) -c $(SRCDIR)/*.cpp || exit 1
	$(CXX) $(ROOTDIR)/common-embedded-platform/core/*.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/common-embedded-platform/supervisor/*.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/embedded-utils/CharacterDevice.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/embedded-utils/Logger.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/embedded-utils/StringHelpers.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/fpga-stm32-ifaces/firmware/bsp-super/*.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/microkvs/kvs/*.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/microkvs/driver/STM32StorageBank.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/stm32-cpp/devices/src/stm32l431.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/stm32-cpp/src/newlib-stubs/*.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/stm32-cpp/src/peripheral/*.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/stm32-cpp/src/cpu/*.* -c $(CXXFLAGS) || exit 1
	$(CXX) $(ROOTDIR)/stm32-cpp/src/helpers/*.cpp -c $(CXXFLAGS) || exit 1
	$(CXX) $(CXXFLAGS) *.o $(LDFLAGS) -o ../firmware.elf
	cd ..
	arm-none-eabi-objcopy -O binary --only-section=.text --only-section=.data firmware.elf firmware.bin
	./imagesize.sh
	arm-none-eabi-strip -s -o front-stripped.elf firmware.elf

.PHONY: clean
clean:
	rm build/*.o
