/* Six-Step BLDC Commutation Generator with GPIO Hall Sensor Control
 * FIXED VERSION - Corrected address decoding
 * 
 * Memory-mapped interface:
 *   Address 0x8000001C - Status Register (Read-Only)
 *     Bits [11:9]: Current sector (0-6)
 *     Bits [8:6]:  Hall sensor values {ha, hb, hc}
 *     Bits [5:0]:  Gate signals {g6, g5, g4, g3, g2, g1}
 * 
 *   Address 0x80000020 - Hall Control Register (Read/Write)
 *     Bit [3]:     USE_GPIO_HALL (1=use GPIO, 0=use hardware pins)
 *     Bit [2]:     Hall A value (when USE_GPIO_HALL=1)
 *     Bit [1]:     Hall B value (when USE_GPIO_HALL=1)
 *     Bit [0]:     Hall C value (when USE_GPIO_HALL=1)
 */

module bldc_commutator
  (
   input wire         clk,
   input wire         reset_n,
   input wire         bldc_sel,
   input wire [31:0]  bldc_data_i,
   input wire [3:0]   we,
   input wire [31:0]  mem_addr,        // Address input
   output wire        bldc_ready,
   output reg [31:0]  bldc_data_o,
   input wire [2:0]   hall_sensors,    // {ha, hb, hc} from hardware pins
   output wire [5:0]  gate_signals     // {g6, g5, g4, g3, g2, g1}
   );

   // Internal registers
   reg [5:0]          gates;
   reg [2:0]          sector;
   reg [2:0]          hall_sync;
   reg [3:0]          hall_ctrl_reg;   // Hall control register
   reg [2:0]          hall_muxed;      // Multiplexed hall sensor value

   // Gate outputs
   assign gate_signals = gates;
   
   // Ready immediately
   assign bldc_ready = bldc_sel;

   // FIXED: Determine which address is being accessed
   // 0x8000001C has bit[2] = 1 (binary: ...011100)
   // 0x80000020 has bit[2] = 0 (binary: ...100000)
   // But we should use a higher bit to distinguish!
   // Actually, let's use the full address comparison for clarity
   wire addr_status = (mem_addr == 32'h8000001C);
   wire addr_hall_ctrl = (mem_addr == 32'h80000020);

   // Synchronize hardware hall sensor inputs (avoid metastability)
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         hall_sync <= 3'b000;
      end else begin
         hall_sync <= hall_sensors;
      end
   end

   // Hall Control Register - Written by software
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         hall_ctrl_reg <= 4'b0000;  // Default: use hardware hall sensors
      end else if (bldc_sel && |we && addr_hall_ctrl) begin
         // Write to hall control register (0x80000020)
         if (we[0]) begin
            hall_ctrl_reg <= bldc_data_i[3:0];
         end
      end
   end

   // Multiplex between hardware and GPIO hall sensors
   always @(*) begin
      if (hall_ctrl_reg[3]) begin
         // Use GPIO (software-controlled) hall sensors
         hall_muxed = hall_ctrl_reg[2:0];
      end else begin
         // Use hardware hall sensor pins
         hall_muxed = hall_sync;
      end
   end

   // Six-step commutation logic based on Algorithm 1
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         gates <= 6'b000000;
         sector <= 3'd0;
      end else begin
         case (hall_muxed)
           3'b101: begin  // {ha, hb, hc} = {1, 0, 1}
              sector <= 3'd5;
              gates <= 6'b100001;  // g6=1, g5=0, g4=0, g3=0, g2=0, g1=1
           end
           
           3'b001: begin  // {ha, hb, hc} = {0, 0, 1}
              sector <= 3'd1;
              gates <= 6'b001001;  // g6=0, g5=0, g4=1, g3=0, g2=0, g1=1
           end
           
           3'b011: begin  // {ha, hb, hc} = {0, 1, 1}
              sector <= 3'd3;
              gates <= 6'b000110;  // g6=0, g5=0, g4=0, g3=1, g2=1, g1=0
           end
           
           3'b010: begin  // {ha, hb, hc} = {0, 1, 0}
              sector <= 3'd2;
              gates <= 6'b100100;  // g6=1, g5=0, g4=0, g3=1, g2=0, g1=0
           end
           
           3'b110: begin  // {ha, hb, hc} = {1, 1, 0}
              sector <= 3'd6;
              gates <= 6'b011000;  // g6=0, g5=1, g4=1, g3=0, g2=0, g1=0
           end
           
           3'b100: begin  // {ha, hb, hc} = {1, 0, 0}
              sector <= 3'd4;
              gates <= 6'b010010;  // g6=0, g5=1, g4=0, g3=0, g2=1, g1=0
           end
           
           default: begin  // Invalid hall sensor combination
              sector <= 3'd0;
              gates <= 6'b000000;  // All gates off for safety
           end
         endcase
      end
   end

   // Read data output - depends on which register is accessed
   always @(*) begin
      if (addr_status) begin
         // Reading status register (0x8000001C)
         // Bits [11:9]: sector, [8:6]: hall sensors, [5:0]: gates
         bldc_data_o = {20'b0, sector, 1'b0, hall_muxed, gates};
      end else begin
         // Reading hall control register (0x80000020)
         bldc_data_o = {28'b0, hall_ctrl_reg};
      end
   end

endmodule