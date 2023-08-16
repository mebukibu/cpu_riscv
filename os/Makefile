K = kernel

OBJS = \
	$K/main.o \
	$K/console.o \
	$K/printf.o \
	$K/uart.o

TOOLPREFIX = riscv64-unknown-elf-

CC = $(TOOLPREFIX)gcc
# AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb -gdwarf-2
# CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I.

$K/kernel: $(OBJS) $K/kernel.ld
	$(LD) -b elf32-littleriscv -T $K/kernel.ld -o $K/kernel $(OBJS)
	$(OBJCOPY) -O binary $K/kernel $K/kernel.bin
	od -An -tx4 -w4 -v $K/kernel.bin > ../hex/kernel/kernel.hex
	$(OBJDUMP) -b elf32-littleriscv -D $K/kernel > kernel.elf.dmp

%.o: %.c
	$(CC) $(CFLAGS) -march=rv32i -mabi=ilp32 -c -o $@ $<

clean:
	rm -f */*.o */*.d