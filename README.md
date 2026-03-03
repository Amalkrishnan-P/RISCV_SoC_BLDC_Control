RISC-V SoC for E-Rikshaws (BLDC Motor Control)
==============================================

This directory contains a simple RISC-V System-on-Chip (SoC) intended for
E-Rikshaw applications, implemented on an FPGA for testing purposes.

-----------------------------------------------------------------------

Repository Location 
-----------------------------
Main working directories:
RISCV_SoC/
├── code/                  # RISC-V software (main.c, Makefile, etc.)
├── fpga/                  # FPGA Verilog sources
├── fpga_test_1/           # FPGA test designs
└── openFPGALoader/        # openFPGALoader build directory

cd ~/Documents/RISCV_SoC/code/
cd ~/Documents/fpga/openFPGALoader/build/

-----------------------------------------------------------------------

FPGA Programming Commands 
----------------------------------------

Flash FPGA with bitstream:

sudo ./openFPGALoader -b tangnano9k -f $1 ../../blink/impl/pnr/fpga_project_2.fs

Load bitstream into SRAM:

./openFPGALoader -b tangnano9k -m $1 ../fpga_test_1/impl/pnr/fpga_test_1.fs

./openFPGALoader -b tangnano9k -f $1 ../../blink/impl/pnr/fpga_project_2.fs screen /dev/ttyUSB0 115200 ./../../fpga/openFPGALoader/build/openFPGALoader -b tangnano9k -m $1 ../fpga_test_1/impl/pnr/fpga_test_1.fs
-----------------------------------------------------------------------

Serial Console
--------------

screen /dev/ttyUSB0 115200

Used for UART output from the SoC.

-----------------------------------------------------------------------

Build Environment Limitations
-----------------------------

The build environment is very limited:

- BSS (uninitialized data) is NOT set to zero, it is fpga auto cleared
- No standard C library functions are available
- Some section types may be missing in the linker command file
- Only 8192 bytes of SRAM available
- Programs must be very small
- No provision for interrupt handlers
- Bare-metal execution only

-----------------------------------------------------------------------

Toolchain Requirements
----------------------

need the RISC-V GCC cross compiler.

On Ubuntu 22.04:

sudo apt install gcc-riscv64-unknown-elf \
                 binutils-riscv64-unknown-elf

-----------------------------------------------------------------------

Software Build Flow
-------------------

1. Edit main.c

2. Build the program:
   make

3. This generates:
   mem_init.v

   The file is created in the Verilog source directory.

4. Rebuild the FPGA bitfile.

5. Reload the FPGA using openFPGALoader.

NOTE:
Every software change requires rebuilding and reloading the FPGA.

-----------------------------------------------------------------------

Memory Initialization
---------------------

Program: conv_to_init

- Takes a binary image of the program
- Converts it into mem_init.v
- Used to initialize SRAM contents in the FPGA design

-----------------------------------------------------------------------

Debugging and Inspection
------------------------

Disassemble the program:

riscv64-unknown-elf-objdump -d prog.elf

Show sections and addresses:

riscv64-unknown-elf-objdump -x prog.elf

Show symbols sorted by address:

riscv64-unknown-elf-nm --numeric-sort prog.elf

-----------------------------------------------------------------------

Notes and Warnings
------------------

- code minimal
- Avoid large global or static variables, now testing
- Assume no automatic memory initialization
- No interrupts for now : use polling only
- Carefully inspect linker sections and memory addresses

-----------------------------------------------------------------------
