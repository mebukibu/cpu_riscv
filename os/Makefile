K = kernel

OBJS = \
	$K/entry.o \
	$K/start.o \
	$K/console.o \
	$K/printf.o \
	$K/uart.o \
	$K/main.o

TOOLPREFIX = riscv64-unknown-elf-

QEMU = qemu-system-riscv32

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)as
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb -gdwarf-2
# CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I.

# Entry point is 0x8000=32768. Word's bit is 32bit(4Byte). So 0x8000/4=8192 zeros filled.
$K/kernel: $(OBJS) $K/kernel.ld
	$(LD) -b elf32-littleriscv -T $K/kernel.ld -o $K/kernel $(OBJS)
	$(OBJCOPY) -O binary $K/kernel $K/kernel.bin
	od -An -tx4 -w4 -v $K/kernel.bin > kernel.hex
	(yes " 00000000" | head -n 8192 && cat kernel.hex) > ../hex/kernel/kernel.hex
	$(OBJDUMP) -b elf32-littleriscv -D $K/kernel > kernel.elf.dmp

$K/kernel_qemu: $(OBJS) $K/kernel_qemu.ld
	$(LD) -b elf32-littleriscv -T $K/kernel_qemu.ld -o $K/kernel_qemu $(OBJS)
	$(OBJDUMP) -b elf32-littleriscv -D $K/kernel_qemu > kernel_qemu.elf.dmp

%.o: %.c
	$(CC) $(CFLAGS) -march=rv32i -mabi=ilp32 -c -o $@ $<

%.o: %.S
	$(AS) -march=rv32i -o $@ $<

clean:
	rm -f */*.o */*.d

QEMUOPTS = -machine virt,aclint=on -bios none -kernel $K/kernel_qemu -m 128M -smp 1 -nographic
# QEMUOPTS += -d in_asm
# QEMUOPTS += -global virtio-mmio.force-legacy=false
# QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
# QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

# define QEMU -> set UART0 = 10000000L in memlayout.h.
qemu: CFLAGS += -DQEMU
qemu: $K/kernel_qemu
	$(QEMU) $(QEMUOPTS)