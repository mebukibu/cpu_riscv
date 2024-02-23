TOOLPREFIX = /opt/riscv/bin/riscv64-unknown-elf-

QEMU = qemu-system-riscv32

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)as
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -O2 -ffreestanding -nostdlib

kernel: kernel.o kernel.ld
	$(LD) -b elf32-littleriscv -T kernel.ld -o kernel kernel.o
	$(OBJDUMP) -b elf32-littleriscv -D kernel > kernel.elf.dmp

%.o: %.c
	$(CC) $(CFLAGS) -march=rv32i -mabi=ilp32 -c -o $@ $<

clean:
	rm -f *.o

QEMUOPT = -machine virt -bios none -nographic -serial mon:stdio --no-reboot

qemu: kernel
	$(QEMU) $(QEMUOPT) -kernel kernel