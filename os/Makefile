OBJS = \
	common.o \
	kernel.o \
	shell.o \
	uart.o \
	user.o

TOOLPREFIX = /opt/riscv/bin/riscv64-unknown-elf-

QEMU = qemu-system-riscv32

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)as
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -O2 -ffreestanding -nostdlib

kernel_elf 			= kernel.elf
kernel_qemu_elf = kernel_qemu.elf

$(kernel_qemu_elf): $(OBJS) kernel_qemu.ld user_qemu.ld
	$(LD) -b elf32-littleriscv -T user_qemu.ld -o shell.elf shell.o user.o common.o
	$(OBJDUMP) -b elf32-littleriscv -D shell.elf > shell_qemu.elf.dmp
	$(OBJCOPY) --set-section-flags .bss=alloc,contents -O binary shell.elf shell.bin
	$(OBJCOPY) -I binary -O elf32-littleriscv shell.bin shell.bin.o
	$(LD) -b elf32-littleriscv -T kernel_qemu.ld -o $(kernel_qemu_elf) kernel.o common.o uart.o shell.bin.o
	$(OBJDUMP) -b elf32-littleriscv -D $(kernel_qemu_elf) > kernel_qemu.elf.dmp

%.o: %.c
	$(CC) $(CFLAGS) -march=rv32i_zicsr -mabi=ilp32 -c -o $@ $<

clean:
	rm -f *.o *.bin *.elf *.dmp

QEMUOPTS = -machine virt -bios none -nographic -serial mon:stdio --no-reboot

qemu: $(kernel_qemu_elf)
	$(QEMU) $(QEMUOPTS) -kernel $(kernel_qemu_elf)