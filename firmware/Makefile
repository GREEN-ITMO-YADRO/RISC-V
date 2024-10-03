TOOLCHAIN_BIN_DIR ?= ~/src/riscv32-unknown-elf/bin
TARGET_PREFIX := $(TOOLCHAIN_BIN_DIR)/riscv32-unknown-elf-

CC ?= $(TARGET_PREFIX)gcc
OBJCOPY ?= $(TARGET_PREFIX)objcopy

CFLAGS ?= -g -std=c2x -Werror -Wpedantic -Wall -Wextra -march=rv32i -mabi=ilp32 -mbig-endian -mstrict-align -mbranch-cost=1 -nostartfiles -specs=nosys.specs -Iboot
LDFLAGS ?= -T ./rv32.ld -Wl,-melf32briscv -lc
OBJCOPY_FLAGS ?= --change-addresses '-0x80000000' -I elf32-bigriscv -O verilog

ASM_FLAGS ?=

BUILD_DIR ?= ./build
DEP_DIR := $(BUILD_DIR)/.deps
DEP_FLAGS = -MMD -MT $@ -MP -MF $(DEP_DIR)/$<.d

SRC_DIR ?= ./app
BOOT_DIR ?= ./boot

SRCS_C := $(shell find '$(SRC_DIR)' '$(BOOT_DIR)' -type f -name '*.c')
SRCS_ASM := $(shell find '$(SRC_DIR)' '$(BOOT_DIR)' -type f -name '*.S')
SRCS := $(SRCS_C) $(SRCS_ASM)
OBJS_C := $(SRCS_C:%.c=$(BUILD_DIR)/%.o)
OBJS_ASM := $(SRCS_ASM:%.S=$(BUILD_DIR)/%.o)
OBJS := $(OBJS_C) $(OBJS_ASM)

DEP_FILES := $(SRCS:%=$(DEP_DIR)/%.d)

.PHONY: clean

$(BUILD_DIR)/app.mem: $(BUILD_DIR)/app.elf ./rv32.ld
	$(OBJCOPY) $(OBJCOPY_FLAGS) $< $@

$(BUILD_DIR)/app.elf: $(OBJS) | ./rv32.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

%.o: %.c
$(OBJS_C): $(BUILD_DIR)/%.o: %.c $(DEP_DIR)/%.c.d ./Makefile | $(DEP_DIR)
	@mkdir -p $(dir $(DEP_DIR)/$*.d)
	@mkdir -p $(dir $@)
	$(CC) $(DEP_FLAGS) $(CFLAGS) -c $< -o $@

$(OBJS_ASM): $(BUILD_DIR)/%.o: %.S $(DEP_DIR)/%.S.d ./Makefile | $(DEP_DIR)
	@mkdir -p $(dir $(DEP_DIR)/$*.d)
	@mkdir -p $(dir $@)
	$(CC) $(DEP_FLAGS) $(CFLAGS) $(ASM_FLAGS) -c $< -o $@

$(DEP_DIR):
	mkdir -p $@

$(DEP_FILES):

include $(wildcard $(DEP_FILES))

clean:
	rm -rf $(BUILD_DIR)
