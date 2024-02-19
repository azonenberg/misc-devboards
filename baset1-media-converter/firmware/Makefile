SRCDIR=$(CURDIR)
ROOTDIR=$(CURDIR)/../../
INCLUDES=-I$(ROOTDIR) \
	-I$(SRCDIR) \
	-I$(ROOTDIR)/stm32-cpp/devices/inc \
	-I$(ROOTDIR)/stm32-cpp/src \

CXXFLAGS=-g -O2 --std=c++17 -mcpu=cortex-m0 -DSTM32F031 -fno-exceptions -fno-rtti -g --specs=nano.specs -Wall -Wextra \
	$(INCLUDES) \
	-fstack-usage
	# need bookworm for this it seems
	#-fcallgraph-info -fcallgraph-info=su

CXX=arm-none-eabi-g++

ASMSORUCES=$(ROOTDIR)/stm32-cpp/src/cpu/*.S
SOURCES=$(SRCDIR)/*.cpp \
	$(ROOTDIR)/stm32-cpp/src/newlib-stubs/*.cpp \
	$(ROOTDIR)/stm32-cpp/src/peripheral/*.cpp \
	$(ROOTDIR)/stm32-cpp/src/util/*.cpp \
	$(ROOTDIR)/stm32-cpp/devices/src/stm32f031.cpp

.ONESHELL:
.SILENT: all
all:
	mkdir -p build
	cd build
	$(CXX) $(ASMSOURCES) $(SOURCES) -c $(CXXFLAGS) || exit 1
	$(CXX) $(CXXFLAGS) *.o -Wl,-T $(ROOTDIR)/stm32-cpp/devices/link/stm32f031.ld -o ../firmware.elf
	cd ..
	arm-none-eabi-objcopy -O binary --only-section=.text --only-section=.data firmware.elf firmware.bin
	./imagesize.sh

.PHONY: clean
clean:
	rm build/*.o
