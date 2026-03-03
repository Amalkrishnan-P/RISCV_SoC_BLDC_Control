void bldc_interactive_test(void)
{
    char ch;
    unsigned char ha, hb, hc;

    uart_puts("\r\n=== BLDC Interactive Hall Sensor Test ===\r\n");
    uart_puts("Commands:\r\n");
    uart_puts("  1-6: Set Hall sensors for Sector 1-6\r\n");
    uart_puts("  h: Switch to Hardware Hall sensors\r\n");
    uart_puts("  s: Show current status\r\n");
    uart_puts("  q: Quit test\r\n\r\n");

    while (1) {
        uart_puts("Enter command: ");
        ch = uart_getchar();
        uart_putchar(ch);
        uart_puts("\r\n");

        switch(ch) {
            case '1':  // Sector 1: 001
                uart_puts("Sector 1: Hall=001, Gates should be g1,g4\r\n");
                bldc_set_hall_sensors(0, 0, 1);
                cdt_delay(1000000);
                bldc_print_status();
                break;

            case '2':  // Sector 2: 010
                uart_puts("Sector 2: Hall=010, Gates should be g3,g6\r\n");
                bldc_set_hall_sensors(0, 1, 0);
                cdt_delay(1000000);
                bldc_print_status();
                break;

            case '3':  // Sector 3: 011
                uart_puts("Sector 3: Hall=011, Gates should be g2,g3\r\n");
                bldc_set_hall_sensors(0, 1, 1);
                cdt_delay(1000000);
                bldc_print_status();
                break;

            case '4':  // Sector 4: 100
                uart_puts("Sector 4: Hall=100, Gates should be g2,g5\r\n");
                bldc_set_hall_sensors(1, 0, 0);
                cdt_delay(1000000);
                bldc_print_status();
                break;

            case '5':  // Sector 5: 101
                uart_puts("Sector 5: Hall=101, Gates should be g1,g6\r\n");
                bldc_set_hall_sensors(1, 0, 1);
                cdt_delay(1000000);
                bldc_print_status();
                break;

            case '6':  // Sector 6: 110
                uart_puts("Sector 6: Hall=110, Gates should be g4,g5\r\n");
                bldc_set_hall_sensors(1, 1, 0);
                cdt_delay(1000000);
                bldc_print_status();
                break;

            case 'h':
            case 'H':
                uart_puts("Switching to Hardware Hall sensors\r\n");
                bldc_use_hardware_hall();
                cdt_delay(1000000);
                bldc_print_status();
                break;

            case 's':
            case 'S':
                bldc_print_status();
                break;

            case 'q':
            case 'Q':
                uart_puts("Exiting BLDC test\r\n");
                return;

            default:
                uart_puts("Unknown command\r\n");
                break;
        }
        uart_puts("\r\n");
    }
}