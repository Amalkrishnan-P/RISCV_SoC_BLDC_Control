# run "make" to create the generate the sram file

CFLAGS = -mno-save-restore -march=rv32im2p0 -mabi=ilp32 -nostartfiles -nostdlib -static -O1
LIBS = /usr/lib/gcc/riscv64-unknown-elf/13.2.0/rv32im/ilp32/libgcc.a

CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

# Object files
OBJS = main.o countdown_timer.o pwm_generator.o uart.o leds.o bldc.o i2c.o gpio.o

all: mem_init.v prog.hex conv_to_init

conv_to_init: conv_to_init.c
	gcc -o conv_to_init conv_to_init.c

mem_init.v: prog.bin conv_to_init
	rm -f ../src/mem_init.v
	./conv_to_init prog.bin > ../src/mem_init.v

main.o: main.c
	$(CC) $(CFLAGS) -c main.c

countdown_timer.o: countdown_timer.c
	$(CC) $(CFLAGS) -c countdown_timer.c

pwm_generator.o: pwm_generator.c
	$(CC) $(CFLAGS) -c pwm_generator.c

uart.o: uart.c
	$(CC) $(CFLAGS) -c uart.c

leds.o: leds.c
	$(CC) $(CFLAGS) -c leds.c

bldc.o: bldc.c
	$(CC) $(CFLAGS) -c bldc.c

i2c.o: i2c.c
	$(CC) $(CFLAGS) -c i2c.c

gpio.o: gpio.c
	$(CC) $(CFLAGS) -c gpio.c

prog.elf: startup.s $(OBJS)
	$(CC) $(CFLAGS) -Tlink_cmd.ld -o prog.elf startup.s $(OBJS) $(LIBS)

prog.bin: prog.elf
	$(OBJCOPY) prog.elf -O binary prog.bin
#	$(OBJCOPY) -j .text prog -O binary prog.bin

prog.hex: prog.bin
	od -v -Ax -t x4 prog.bin > prog.hex

clean:
	rm -f prog.elf prog.hex prog.bin conv_to_init main.o countdown_timer.o pwm_generator.o uart.o leds.o bldc.o i2c.o gpio.o

.PHONY: all clean

