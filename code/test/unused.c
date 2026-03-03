/* The picorv32 core implements several counters and
   instructions to access them.  These are part of the
   risc-v specification.  Function readtime uses one
   of them.
*/

static inline unsigned int readtime(void)
{
  unsigned int val;
  unsigned long long jj;
  asm volatile("rdtime %0" : "=r" (val));
  return val;

}

// Tang Nano 9K Constraint File
// Generated for BLDC Motor Controller with I2C and CAN interface

// Clock Input (27MHz oscillator)
IO_LOC "clk" 52;
IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=NONE PCI_CLAMP=OFF BANK_VCCIO=3.3;

// Reset Button (Active Low)
IO_LOC "reset_button_n" 4;
IO_PORT "reset_button_n" PULL_MODE=UP PCI_CLAMP=OFF BANK_VCCIO=1.8;

// UART Interface
IO_LOC "uart_tx" 17;
IO_PORT "uart_tx" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;
IO_LOC "uart_rx" 18;
IO_PORT "uart_rx" IO_TYPE=LVCMOS33 PULL_MODE=NONE PCI_CLAMP=OFF BANK_VCCIO=3.3;

// Hall Sensors (3-bit input) - Using 1.8V pins 79-81
IO_LOC "hall_sensors[0]" 79;
IO_PORT "hall_sensors[0]" PULL_MODE=UP BANK_VCCIO=1.8;
IO_LOC "hall_sensors[1]" 80;
IO_PORT "hall_sensors[1]" PULL_MODE=UP BANK_VCCIO=1.8;
IO_LOC "hall_sensors[2]" 81;
IO_PORT "hall_sensors[2]" PULL_MODE=UP BANK_VCCIO=1.8;

// BLDC Gate Signals (6-bit output) - Using 3.3V pins 25-30
IO_LOC "gate_signals[0]" 25;
IO_PORT "gate_signals[0]" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;

//IO_LOC "pwm_out" 25;
//IO_PORT "pwm_out" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;

IO_LOC "gate_signals[1]" 26;
IO_PORT "gate_signals[1]" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;
IO_LOC "gate_signals[2]" 27;
IO_PORT "gate_signals[2]" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;
IO_LOC "gate_signals[3]" 28;
IO_PORT "gate_signals[3]" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;
IO_LOC "gate_signals[4]" 29;
IO_PORT "gate_signals[4]" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;
IO_LOC "gate_signals[5]" 30;
IO_PORT "gate_signals[5]" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8 BANK_VCCIO=3.3;

// I2C Interface - Using 1.8V pins 82-83
IO_LOC "sda" 82;
IO_PORT "sda" PULL_MODE=UP OPEN_DRAIN=ON DRIVE=8 BANK_VCCIO=1.8;
IO_LOC "scl" 83;
IO_PORT "scl" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;

// CAN Interface - Using 1.8V pins 84-85
IO_LOC "can_rx" 84;
IO_PORT "can_rx" PULL_MODE=UP BANK_VCCIO=1.8;
IO_LOC "can_tx" 85;
IO_PORT "can_tx" PULL_MODE=NONE DRIVE=8 BANK_VCCIO=1.8;

// Status LEDs (kept from original) - Using 1.8V pins 10-16
IO_LOC "leds[0]" 10;
IO_PORT "leds[0]" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;
IO_LOC "leds[1]" 11;
IO_PORT "leds[1]" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;
IO_LOC "leds[2]" 13;
IO_PORT "leds[2]" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;
IO_LOC "leds[3]" 14;
IO_PORT "leds[3]" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;
IO_LOC "leds[4]" 15;
IO_PORT "leds[4]" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;
IO_LOC "pwm_out" 16;
IO_PORT "pwm_out" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;

//IO_LOC "gate_signals[0]" 16;
//IO_PORT "gate_signals[0]" PULL_MODE=UP DRIVE=8 BANK_VCCIO=1.8;

// Unallocated 1.8V pins available: 86, 87, 88
// Unallocated 3.3V pins available: None (all used: 25-30) 19 20 55 56 57
void interactive_test_menu(void)
{
    char choice;

    while (1) {
        uart_puts("\n\r=== Test Menu ===\n\r");
        uart_puts("1. PWM Interactive Test\n\r");
        uart_puts("2. CDT Test\n\r");
        uart_puts("3. PWM Test\n\r");
        uart_puts("4. BLDC Interactive Test\n\r");
        uart_puts("5. I2C Interactive Test\n\r");
        uart_puts("6. CAN Test\n\r");
        uart_puts("7. UART RX Test\n\r");
        uart_puts("q. Quit\n\r");
        uart_puts("Select option: ");

        choice = uart_getchar();
        uart_putchar(choice);   // echo
        uart_puts("\n\r");

        switch (choice) {

        case '1':
            pwm_interactive_test();
            break;

        case '2':
            cdt_test();
            break;

        case '3':
            pwm_test();
            break;

        case '4':
            bldc_interactive_test();
            break;

        case '5':
            i2c_interactive_test();
            break;

        case '6':
            can_test();
            break;

        case '7':
            uart_rx_test();
            break;

        case 'q':
        case 'Q':
            uart_puts("Exiting menu...\n\r");
            return;

        default:
            uart_puts("Invalid option!\n\r");
            break;
        }
    }
}

// void i2c_test(void)
// {
//   unsigned char read_data;

//   uart_puts("\r\n=== I2C Master Controller Test ===\r\n");
// i2c_init();
// uart_puts("I2C controller initialized.\r\n");
// uart_puts("Clock: 100 kHz (standard mode)\r\n\r\n");


// uart_puts("Example: Writing 0xAA to slave 0x50\r\n");
// i2c_write_byte(0x50, 0xAA);
// i2c_print_status();
// // i2c_wait_done();


// if (i2c_has_error()) {
// uart_puts("Write failed - ACK error (no device at 0x50?)\r\n");
// } else {
// uart_puts("Write successful!\r\n");
// }


// i2c_print_status();
// uart_puts("\r\n");


// uart_puts("Example: Reading from slave 0x50\r\n");
// read_data = i2c_read_byte(0x50);
//
//
// if (i2c_has_error()) {
// uart_puts("Read failed - ACK error (no device at 0x50?)\r\n");
// } else {
// uart_puts("Read successful! Data: 0x");
// uart_print_hex((unsigned int)read_data);
// uart_puts("\r\n");
// }
//
//
// i2c_print_status();
// uart_puts("\r\n");


// uart_puts("Note: Connect I2C devices to SDA/SCL pins.\r\n");
// uart_puts("Use 'i' command in main loop to test I2C.\r\n\r\n");
// }
// }
// void i2c_interactive_test(void)
// {
//     char ch;
//     unsigned char addr, data;

//     uart_puts("\r\n=== Interactive I2C Test ===\r\n");
//     uart_puts("Commands:\r\n");
//     uart_puts("  '1' = Write 0xAA to 0x50\r\n");
//     uart_puts("  '2' = Write 0x55 to 0x50\r\n");
//     uart_puts("  '3' = Write 0xFF to 0x3C\r\n");
//     uart_puts("  's' = Show status\r\n");
//     uart_puts("  'q' = Quit\r\n\r\n");

//     while (1) {
//         uart_puts("I2C> ");
//         ch = uart_getchar();
//         uart_putchar(ch);
//         uart_puts("\r\n");

//         switch(ch) {
//             case '1':
//                 uart_puts("Writing 0xAA to 0x51...\r\n");
//                 i2c_write_byte(0xAA,0xAA);
//                 // i2c_read_byte((unsigned char)slave_addr)
//                 cdt_delay(5700000);
//                 uart_print_hex((unsigned int)i2c_get_status);
//                 i2c_print_status();
//                 break;

//             case '2':
//                 uart_puts("Writing 0x55 to 0x50...\r\n");
//                 i2c_write_byte(0x50, 0x55);
//                 uart_print_hex((unsigned int)i2c_get_status);
//                 uart_puts("...\r\n");
//                 cdt_delay(5700000);
//                 uart_print_hex((unsigned int)i2c_get_status);
//                 uart_puts("...\r\n");
//                 i2c_print_status();
//                 break;

//             case '3':
//                 uart_puts("Writing 0xFF to 0x3C...\r\n");
//                 i2c_write_byte(0x3C, 0xFF);
//                 cdt_delay(5700000);
//                 i2c_print_status();
//                 break;

//             case 's':
//             case 'S':
//                 i2c_print_status();
//                 break;

//             case 'q':
//             case 'Q':
//                 uart_puts("Exiting I2C test\r\n");
//                 return;

//             default:
//                 uart_puts("Unknown command\r\n");
//                 break;
//         }
//         uart_puts("\r\n");
//     }
// }
// void can_test(void)
// {
//   can_frame_t tx_frame, rx_frame;
//   int i;
//
//   uart_puts("\r\n=== CAN Controller Test ===\r\n");
//
//   // Initialize CAN
//   can_init();
//
//   uart_puts("CAN controller initialized.\r\n");
//   uart_puts("Bit Rate: 125 kHz\r\n");
//   uart_puts("Format: CAN 2.0A (11-bit identifier)\r\n\r\n");
//
//   // Prepare test frame
//   tx_frame.id = 0x123;
//   tx_frame.dlc = 8;
//   for (i = 0; i < 8; i++) {
//     tx_frame.data[i] = 0x10 + i;
//   }
//
//   uart_puts("Sending test frame:\r\n");
//   can_print_frame(&tx_frame);
//
//   can_send_frame(tx_frame.id, tx_frame.dlc, tx_frame.data);
//   can_wait_tx_complete();
//
//   if (can_has_error()) {
//     uart_puts("Transmission failed!\r\n");
//   } else {
//     uart_puts("Transmission successful!\r\n");
//   }
//
//   can_print_status();
//   uart_puts("\r\n");
//
//   // // Check for received frames
//   // uart_puts("Checking for received frames...\r\n");
//   // if (can_receive_frame(&rx_frame)) {
//   //   uart_puts("Frame received:\r\n");
//   //   can_print_frame(&rx_frame);
//   // } else {
//   //   uart_puts("No frames received.\r\n");
//   // }
//
//   uart_puts("\r\nNote: Connect CAN transceiver to CAN_RX/CAN_TX pins.\r\n");
//   uart_puts("Use 'c' command in main loop to test CAN.\r\n\r\n");
// }
/* 
   Startup sequence for PicoRV32 with compressed instruction support
*/

// .section .text
// .global _start
// .align 2                    /* CRITICAL: 4-byte alignment */

// _start:
//     # Set stack pointer to top of 8KB RAM
//     li sp, 0x2000
    
//     # Clear BSS section (uninitialized variables)
//     la a0, _bss_start
//     la a1, _bss_end
// clear_bss:
//     bgeu a0, a1, bss_done
//     sw zero, 0(a0)
//     addi a0, a0, 4
//     blt a0, a1, clear_bss
// bss_done:
    
//     # Call main function
// 	li x2, 8192
// 	call main
    
//     # If main returns, loop forever
// infinite_loop:
//     j infinite_loop
