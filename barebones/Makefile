#Coremark makefile for BP

RISCV_GCC = riscv64-unknown-elf-gcc -mabi=lp64 -march=rv64ia -mcmodel=medany -fno-builtin-printf

RISCV_LINK = -O2 -static -nostdlib -nostartfiles -lm -lgcc -T test.ld

RISCV_TESTS_DIR = ../../riscv-tests/benchmarks

COMMON_FILES = -I$(RISCV_TESTS_DIR)/../env -I$(RISCV_TESTS_DIR)/common -I../ -I./ 
COMMON_FILES += $(RISCV_TESTS_DIR)/common/crt.S $(RISCV_TESTS_DIR)/common/syscalls.c 

RISCV_OBJDUMP  = riscv64-unknown-elf-objdump -D -M no-aliases,numeric


.PHONY: riscv

riscv:
	$(RISCV_GCC) $(COMMON_FILES) -o coremark.riscv $(wildcard *.c) $(wildcard ../*.c) $(RISCV_LINK)
	$(RISCV_OBJDUMP) coremark.riscv > coremark.dump

clean:
	rm -f *.riscv

