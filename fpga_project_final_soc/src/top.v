/*
Top level module of SoC 

It includes:
     * An 8KB SRAM which is initialzed with the C program
     * An I2C module
     * A module to read/write to LEDs, to check core working
     * A UART module
     * A 32-bit count down timer.
     * A PWM generator with variable duty cycle.
     * A six-step BLDC commutation generator.
     * 8 GPIO pins
*/


module top (
            input wire        clk,
            input wire        reset_button_n,

            input wire        uart_rx,        // UART RX pin
            output wire       uart_tx,        // UART TX pin
            output wire       pwm_out,        // PWM output pin
            input wire [2:0]  hall_sensors,   // Hall sensor inputs {ha, hb, hc}
            output wire [5:0] gate_signals,   // BLDC gate outputs {g6, g5, g4, g3, g2, g1}
            inout wire        sda,            // I2C data line
            output wire       scl,            // I2C clock line

            // 8-Pin GPIO (bidirectional)
             inout wire        gpio_pin0,
             inout wire        gpio_pin1,
             inout wire        gpio_pin2,
             inout wire        gpio_pin3,
             inout wire        gpio_pin4,
             inout wire        gpio_pin5,
             inout wire        gpio_pin6,
             inout wire        gpio_pin7,
             // To check working
             output wire [4:0] leds
            );

   parameter [0:0] BARREL_SHIFTER = 1;              // Enabling to rotate data by multiple bits within a single clock cycle
   parameter [0:0] ENABLE_MUL = 0;
   parameter [0:0] ENABLE_DIV = 1;                  // Enabling hardware division
   parameter [0:0] ENABLE_FAST_MUL = 1;             // Enabling fast hardware multiplication
   parameter [0:0] ENABLE_COMPRESSED = 0;           // Disabling 16 bit instruction format
   parameter [0:0] ENABLE_IRQ_QREGS = 0;            // Disabling interrupts

   parameter integer MEMBYTES = 8192;                // Address max limit
   parameter [31:0] STACKADDR = (MEMBYTES);         // Stack Grows down. Software set
   parameter [31:0] PROGADDR_RESET = 32'h0000_0000; // Reset address
   parameter [31:0] PROGADDR_IRQ = 32'h0000_0000;

   wire                       reset_n;
   wire [31:0]                mem_addr;
   wire [31:0]                mem_wdata;
   wire [31:0]                mem_rdata;
   wire [3:0]                 mem_wstrb;
   wire                       mem_ready;
   wire                       mem_inst;
   wire                       leds_sel;
   wire                       leds_ready;
   wire [31:0]                leds_data_o;
   wire                       sram_sel;
   wire                       sram_ready;
   wire [31:0]                sram_data_o;
   wire                       cdt_sel;
   wire                       cdt_ready;
   wire [31:0]                cdt_data_o;
   wire                       uart_sel;
   wire [31:0]                uart_data_o;
   wire                       uart_ready;
   wire                       pwm_sel;
   wire                       pwm_ready;
   wire [31:0]                pwm_data_o;
   wire                       bldc_sel;
   wire                       bldc_ready;
   wire [31:0]                bldc_data_o;
   wire                       i2c_sel;
   wire                       i2c_ready;
   wire [31:0]                i2c_data_o;
   wire                       gpio_sel;
   wire [31:0]                gpio_data_o;
   wire                       gpio_ready;

   //   Memory map for all slaves:
   //   SRAM 00000000 - 0001ffff
   //   LED  80000000
   //   UART 80000008 - 8000000f
   //   CDT  80000010
   //   PWM  80000018
   //   BLDC 8000001C - 80000020
   //   I2C  80000024 - 8000002C // removed some pheripherals from here
   //   GPIO 80000040 - 80000050

   assign sram_sel = mem_valid && (mem_addr < 32'h00002000);
   assign leds_sel = mem_valid && (mem_addr == 32'h80000000);
   assign uart_sel = mem_valid && ((mem_addr & 32'hfffffff8) == 32'h80000008);
   assign cdt_sel = mem_valid && (mem_addr == 32'h80000010);
   assign pwm_sel = mem_valid && (mem_addr == 32'h80000018);
   assign bldc_sel = mem_valid && (mem_addr == 32'h8000001c || mem_addr == 32'h80000020);
   assign i2c_sel = mem_valid && (mem_addr == 32'h80000024 || mem_addr == 32'h80000028 || mem_addr == 32'h8000002c);
   assign gpio_sel = mem_valid && (mem_addr == 32'h80000040 || mem_addr == 32'h80000044 || mem_addr == 32'h80000048 || mem_addr == 32'h8000004C || mem_addr == 32'h80000050);
   
   // Core can proceed regardless of which slave was targetted and is now ready.
   assign mem_ready = mem_valid & (sram_ready | leds_ready | uart_ready | cdt_ready | pwm_ready | bldc_ready | i2c_ready| gpio_ready);

   // Select which slave's output data is to be fed to core.
   assign mem_rdata = sram_sel ? sram_data_o :
                      leds_sel ? leds_data_o :
                      uart_sel ? uart_data_o :
                      cdt_sel  ? cdt_data_o  :
                      pwm_sel  ? pwm_data_o  :
                      bldc_sel ? bldc_data_o :
                      i2c_sel  ? i2c_data_o  :
                      gpio_sel ? gpio_data_o : 32'h0;

   assign leds = ~leds_data_o[4:0]; // Connect to the LEDs off the FPGA

   reset_control reset_controller
     (
      .clk(clk),
      .reset_button_n(reset_button_n),
      .reset_n(reset_n)
      );

   uart_wrap uart
     (
      .clk(clk),
      .reset_n(reset_n),
      .uart_tx(uart_tx),
      .uart_rx(uart_rx),
      .uart_sel(uart_sel),
      .addr(mem_addr[3:0]),
      .uart_wstrb(mem_wstrb),
      .uart_di(mem_wdata),
      .uart_do(uart_data_o),
      .uart_ready(uart_ready)
      );

   countdown_timer cdt
     (
      .clk(clk),
      .reset_n(reset_n),
      .cdt_sel(cdt_sel),
      .cdt_data_i(mem_wdata),
      .we(mem_wstrb),
      .cdt_ready(cdt_ready),
      .cdt_data_o(cdt_data_o)
      );

   pwm_generator pwm
     (
      .clk(clk),
      .reset_n(reset_n),
      .pwm_sel(pwm_sel),
      .pwm_data_i(mem_wdata),
      .we(mem_wstrb),
      .pwm_ready(pwm_ready),
      .pwm_data_o(pwm_data_o),
      .pwm_out(pwm_out)
      );

   bldc_commutator bldc
     (
      .clk(clk),
      .reset_n(reset_n),
      .bldc_sel(bldc_sel),
      .bldc_data_i(mem_wdata),
      .we(mem_wstrb),
      .mem_addr(mem_addr),
      .bldc_ready(bldc_ready),
      .bldc_data_o(bldc_data_o),
      .hall_sensors(hall_sensors),
      .gate_signals(gate_signals)
      );

   i2c_wrap i2c
     (
      .clk(clk),
      .reset_n(reset_n),
      .i2c_sel(i2c_sel),
      .addr(mem_addr[3:0]),
      .we(mem_wstrb),
      .i2c_data_i(mem_wdata),
      .i2c_data_o(i2c_data_o),
      .i2c_ready(i2c_ready),
      .sda(sda),
      .scl(scl)
      );

      gpio_8pin gpio
     (
      .clk(clk),
      .reset_n(reset_n),
      .gpio_sel(gpio_sel),
      .addr(mem_addr[4:0]),
      .gpio_wstrb(mem_wstrb),
      .gpio_data_i(mem_wdata),
      .gpio_data_o(gpio_data_o),
      .gpio_ready(gpio_ready),

      .gpio_pin0(gpio_pin0),
      .gpio_pin1(gpio_pin1),
      .gpio_pin2(gpio_pin2),
      .gpio_pin3(gpio_pin3),
      .gpio_pin4(gpio_pin4),
      .gpio_pin5(gpio_pin5),
      .gpio_pin6(gpio_pin6),
      .gpio_pin7(gpio_pin7)
      );


   sram #(.ADDRWIDTH(13)) memory
     (
      .clk(clk),
      .resetn(reset_n),
      .sram_sel(sram_sel),
      .wstrb(mem_wstrb),
      .addr(mem_addr[12:0]),
      .sram_data_i(mem_wdata),
      .sram_ready(sram_ready),
      .sram_data_o(sram_data_o)
      );

  test_leds soc_leds
     (
      .clk(clk),
      .reset_n(reset_n),
      .leds_sel(leds_sel),
      .leds_data_i(mem_wdata[5:0]),
      .we(mem_wstrb[0]),
      .leds_ready(leds_ready),
      .leds_data_o(leds_data_o)
      );

   picorv32
     #(
       .STACKADDR(STACKADDR),
       .PROGADDR_RESET(PROGADDR_RESET),
       .PROGADDR_IRQ(PROGADDR_IRQ),
       .BARREL_SHIFTER(BARREL_SHIFTER),
       .COMPRESSED_ISA(ENABLE_COMPRESSED),
       .ENABLE_MUL(ENABLE_MUL),
       .ENABLE_DIV(ENABLE_DIV),
       .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
       .ENABLE_IRQ(1),
       .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
       ) cpu
       (
        .clk         (clk),
        .resetn      (reset_n),
        .mem_valid   (mem_valid),
        .mem_instr   (mem_instr),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata),
        .irq         ('b0)
        );

endmodule 
