# Makefile for CoreESP8266
# written by Christian Hammacher
#
# Licensed under the terms of the GNU Public License v3
# see http://www.gnu.org/licenses/gpl-3.0.html
#

# Referenced component versions
ARDUINO_VERSION := 1.6.12
GCC_VERSION := 1.20.0-26-gb404fb9-2

# Workspace paths
BUILD_PATH := $(PWD)/Release/obj
OUTPUT_PATH := $(PWD)/Release

# Compiler options
OPTIMIZATION := -Os

# ================================ Prerequisites ====================================

# Determine Arduino path
UNAME := $(shell uname -s)
ifeq ($(UNAME),Linux)
  ARDUINO_PATH := $(HOME)/.arduino15
endif
ifeq ($(UNAME),Darwin)
  ARDUINO_PATH := $(HOME)/Library/Arduino15
endif
ifeq (,$(wildcard $(ARDUINO_PATH)/.))
  $(error Arduino directory not found!)
endif

# Detect GCC path
GCC_PATH := $(ARDUINO_PATH)/packages/esp8266/tools/xtensa-lx106-elf-gcc/$(GCC_VERSION)
ifeq (,$(wildcard $(GCC_PATH)/.))
  $(error GCC toolchain not found!)
endif


# ================================ GCC Options ======================================

CROSS_COMPILE := xtensa-lx106-elf-
CC := $(GCC_PATH)/bin/$(CROSS_COMPILE)gcc
CXX := $(GCC_PATH)/bin/$(CROSS_COMPILE)g++
S := $(GCC_PATH)/bin/$(CROSS_COMPILE)gcc
AR := $(GCC_PATH)/bin/$(CROSS_COMPILE)ar

INCLUDES := $(PWD)/tools/sdk/include $(PWD)/tools/sdk/lwip/include
INCLUDES += $(PWD)/cores/esp8266 $(PWD)/variants/nodemcu
INCLUDES += $(PWD)/libraries/DNSServer/src $(PWD)/libraries/ESP8266WiFi/src $(PWD)/libraries/ESP8266mDNS $(PWD)/libraries/DNSServer/src $(PWD)/libraries/EEPROM $(PWD)/libraries/ESP8266SSDP


CFLAGS := -D__ets__ -DICACHE_FLASH -U__STRICT_ANSI__ -c -w -Wextra $(OPTIMIZATION) -g -Wpointer-arith -Wno-implicit-function-declaration -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals -falign-functions=4 -MMD -std=gnu99 -ffunction-sections -fdata-sections -DF_CPU=80000000L -DLWIP_OPEN_SRC -DARDUINO=10612 -DARDUINO_ESP8266_NODEMCU -DARDUINO_ARCH_ESP8266 -DARDUINO_BOARD=\"ESP8266_NODEMCU\" -DESP8266

CPPFLAGS := -D__ets__ -DICACHE_FLASH -U__STRICT_ANSI__ -c -w -Wextra $(OPTIMIZATION) -g -mlongcalls -mtext-section-literals -fno-exceptions -fno-rtti -falign-functions=4 -std=c++11 -MMD -ffunction-sections -fdata-sections -DF_CPU=80000000L -DLWIP_OPEN_SRC -DARDUINO=10612 -DARDUINO_ESP8266_NODEMCU -DARDUINO_ARCH_ESP8266 -DARDUINO_BOARD=\"ESP8266_NODEMCU\" -DESP8266

SFLAGS := -D__ets__ -DICACHE_FLASH -U__STRICT_ANSI__ -c -g -x assembler-with-cpp -MMD -mlongcalls -DF_CPU=80000000L -DLWIP_OPEN_SRC -DARDUINO=10612 -DARDUINO_ESP8266_NODEMCU -DARDUINO_ARCH_ESP8266 -DARDUINO_BOARD=\"ESP8266_NODEMCU\" -DESP8266

CFLAGS += $(foreach dir,$(INCLUDES),-I$(dir))
CPPFLAGS += $(foreach dir,$(INCLUDES),-I$(dir))
SFLAGS += $(foreach dir,$(INCLUDES),-I$(dir))


# Unfortunately make doesn't support directory wildcards in targets, so instead we must explicitly specify the source paths by using VPATH
VPATH := $(PWD)/cores/esp8266 $(PWD)/cores/esp8266/libb64 $(PWD)/cores/esp8266/spiffs $(PWD)/cores/esp8266/umm_malloc
VPATH += $(PWD)/tools/sdk/lwip/src/api $(PWD)/tools/sdk/lwip/src/app $(PWD)/tools/sdk/lwip/src/core $(PWD)/tools/sdk/lwip/src/core/ipv4 $(PWD)/tools/sdk/lwip/src/netif
VPATH += $(PWD)/libraries/DNSServer/src $(PWD)/libraries/ESP8266WiFi/src $(PWD)/libraries/ESP8266mDNS $(PWD)/libraries/DNSServer $(PWD)/libraries/EEPROM $(PWD)/libraries/ESP8266SSDP

C_SOURCES += $(foreach dir,$(VPATH),$(wildcard $(dir)/*.c))
CPP_SOURCES := $(foreach dir,$(VPATH),$(wildcard $(dir)/*.cpp))
S_SOURCES := $(foreach dir,$(VPATH),$(wildcard $(dir)/*.S))

C_OBJS := $(foreach src,$(C_SOURCES),$(BUILD_PATH)/$(notdir $(src:.c=.c.o)))
CPP_OBJS := $(foreach src,$(CPP_SOURCES),$(BUILD_PATH)/$(notdir $(src:.cpp=.cpp.o)))
S_OBJS := $(foreach src,$(S_SOURCES),$(BUILD_PATH)/$(notdir $(src:.S=.S.o)))

DEPS := $(C_OBJS:%.o=%.d) $(CPP_OBJS:%.o=%.d) $(S_OBJS:%.o=%.d)


# ================================= Target all ======================================
.PHONY += all
all: $(OUTPUT_PATH)/libCoreESP8266.a
$(OUTPUT_PATH)/libCoreESP8266.a: $(BUILD_PATH) $(OUTPUT_PATH) $(C_OBJS) $(CPP_OBJS) $(S_OBJS)
	@echo "  AR      libCoreESP8266.a"
	@$(AR) -r "$(OUTPUT_PATH)/libCoreESP8266.a" $(C_OBJS) $(CPP_OBJS) $(S_OBJS)
-include $(DEPS)

$(BUILD_PATH)/%.c.o: %.c
	@echo "  CC      $(subst $(PWD)/,,$<)"
	@$(CC) $(CFLAGS) $< -o $@

$(BUILD_PATH)/%.cpp.o: %.cpp
	@echo "  CC      $(subst $(PWD)/,,$<)"
	@$(CXX) $(CPPFLAGS) $< -o $@

$(BUILD_PATH)/%.S.o: %.S
	@echo "  CC      $(subst $(PWD)/,,$<)"
	@$(S) $(SFLAGS) $< -o $@

$(BUILD_PATH):
	@mkdir -p $(BUILD_PATH)

$(OUTPUT_PATH):
	@mkdir -p $(OUTPUT_PATH)


# ================================= Target clean ====================================
.PHONY += clean
clean:
	@rm -rf $(BUILD_PATH) $(OUTPUT_PATH)
	$(info Build files removed.)

