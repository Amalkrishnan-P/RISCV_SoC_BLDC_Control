/* CAN Controller
 * Memory-mapped interface for basic CAN communication
 * 
 * Memory Map:
 *   0x80000030 - TX ID Register (write)
 *     [31:29] - Reserved
 *     [28:18] - 11-bit CAN ID (standard format)
 *     [17:4]  - Reserved
 *     [3:0]   - Data Length Code (DLC) - number of data bytes (0-8)
 *   
 *   0x80000034 - TX Data Register 0 (write)
 *     [31:24] - Data byte 3
 *     [23:16] - Data byte 2
 *     [15:8]  - Data byte 1
 *     [7:0]   - Data byte 0
 *   
 *   0x80000038 - TX Data Register 1 (write)
 *     [31:24] - Data byte 7
 *     [23:16] - Data byte 6
 *     [15:8]  - Data byte 5
 *     [7:0]   - Data byte 4
 *   
 *   0x8000003C - Control/Status Register
 *     Write:
 *       [0] - Start transmission (write 1)
 *     Read:
 *       [31:29] - Reserved
 *       [28:18] - RX CAN ID
 *       [17:4]  - Reserved
 *       [3:0]   - RX DLC
 *   
 *   0x80000040 - Status Register (read)
 *     [7:4]   - Reserved
 *     [3]     - RX Data Available
 *     [2]     - Error (bit error, stuff error, etc)
 *     [1]     - Busy (transmitting)
 *     [0]     - TX Complete
 *   
 *   0x80000044 - RX Data Register 0 (read)
 *     [31:24] - Data byte 3
 *     [23:16] - Data byte 2
 *     [15:8]  - Data byte 1
 *     [7:0]   - Data byte 0
 *   
 *   0x80000048 - RX Data Register 1 (read)
 *     [31:24] - Data byte 7
 *     [23:16] - Data byte 6
 *     [15:8]  - Data byte 5
 *     [7:0]   - Data byte 4
 */

module can_wrap
  (
   input wire         clk,
   input wire         reset_n,
   input wire         can_sel,
   input wire [4:0]   addr,
   input wire [3:0]   we,
   input wire [31:0]  can_data_i,
   output reg [31:0]  can_data_o,
   output wire        can_ready,
   
   // CAN physical interface
   input wire         can_rx,
   output wire        can_tx
   );

   // Internal registers - memory mapped
   reg [10:0] tx_id;
   reg [3:0]  tx_dlc;
   reg [63:0] tx_data;
   reg        start_tx;
   
   reg [10:0] rx_id;
   reg [3:0]  rx_dlc;
   reg [63:0] rx_data;
   
   // Signals from CAN controller core
   wire       tx_complete;
   wire       busy;
   wire       error;
   wire       rx_valid;
   wire [10:0] rx_id_wire;
   wire [3:0]  rx_dlc_wire;
   wire [63:0] rx_data_wire;
   
   // Address decode
   wire tx_id_sel     = can_sel && (addr == 5'h10);  // 0x80000030
   wire tx_data0_sel  = can_sel && (addr == 5'h14);  // 0x80000034
   wire tx_data1_sel  = can_sel && (addr == 5'h18);  // 0x80000038
   wire ctrl_sel      = can_sel && (addr == 5'h1c);  // 0x8000003C
   wire status_sel    = can_sel && (addr == 5'h10);  // 0x80000040
   wire rx_data0_sel  = can_sel && (addr == 5'h14);  // 0x80000044
   wire rx_data1_sel  = can_sel && (addr == 5'h18);  // 0x80000048
   
   // Ready immediately for all operations
   assign can_ready = can_sel;
   
   // Write to TX ID register
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         tx_id <= 11'h000;
         tx_dlc <= 4'h0;
      end else if (tx_id_sel && we[0]) begin
         tx_id <= can_data_i[28:18];
         tx_dlc <= can_data_i[3:0];
      end
   end
   
   // Write to TX Data Register 0
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         tx_data[31:0] <= 32'h0;
      end else if (tx_data0_sel && we[0]) begin
         tx_data[31:0] <= can_data_i;
      end
   end
   
   // Write to TX Data Register 1
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         tx_data[63:32] <= 32'h0;
      end else if (tx_data1_sel && we[0]) begin
         tx_data[63:32] <= can_data_i;
      end
   end
   
   // Write to control register (start transmission)
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         start_tx <= 1'b0;
      end else if (ctrl_sel && we[0]) begin
         start_tx <= can_data_i[0];
      end else begin
         start_tx <= 1'b0;  // Auto-clear after one cycle
      end
   end
   
   // Latch received data
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         rx_id <= 11'h000;
         rx_dlc <= 4'h0;
         rx_data <= 64'h0;
      end else if (rx_valid) begin
         rx_id <= rx_id_wire;
         rx_dlc <= rx_dlc_wire;
         rx_data <= rx_data_wire;
      end
   end
   
   // Read data output
   always @(*) begin
      case(1'b1)
         tx_id_sel: begin
            can_data_o = {3'b0, tx_id, 14'b0, tx_dlc};
         end
         tx_data0_sel: begin
            can_data_o = tx_data[31:0];
         end
         tx_data1_sel: begin
            can_data_o = tx_data[63:32];
         end
         ctrl_sel: begin
            can_data_o = {3'b0, rx_id, 14'b0, rx_dlc};
         end
         status_sel: begin
            can_data_o = {28'b0, rx_valid, error, busy, tx_complete};
         end
         rx_data0_sel: begin
            can_data_o = rx_data[31:0];
         end
         rx_data1_sel: begin
            can_data_o = rx_data[63:32];
         end
         default: begin
            can_data_o = 32'h0;
         end
      endcase
   end
   
   // Instantiate CAN controller core
   can_controller can_core (
      .clk(clk),
      .reset_n(reset_n),
      .tx_start(start_tx),
      .tx_id(tx_id),
      .tx_dlc(tx_dlc),
      .tx_data(tx_data),
      .tx_complete(tx_complete),
      .busy(busy),
      .error(error),
      .rx_valid(rx_valid),
      .rx_id(rx_id_wire),
      .rx_dlc(rx_dlc_wire),
      .rx_data(rx_data_wire),
      .can_rx(can_rx),
      .can_tx(can_tx)
   );

endmodule

////////////////////////////////////////////////////////////////////
// CAN Controller Core (Simplified Implementation)
// Supports basic CAN 2.0A (11-bit identifier, standard format)
////////////////////////////////////////////////////////////////////
module can_controller
  (
   input wire         clk,          // System clock (27 MHz)
   input wire         reset_n,      // Active-low reset
   
   // Transmit interface
   input wire         tx_start,     // Start transmission
   input wire [10:0]  tx_id,        // 11-bit CAN ID
   input wire [3:0]   tx_dlc,       // Data Length Code (0-8)
   input wire [63:0]  tx_data,      // Up to 8 bytes of data
   output reg         tx_complete,  // Transmission complete
   output reg         busy,         // Transmission in progress
   
   // Receive interface
   output reg         rx_valid,     // Valid frame received
   output reg [10:0]  rx_id,        // Received CAN ID
   output reg [3:0]   rx_dlc,       // Received DLC
   output reg [63:0]  rx_data,      // Received data
   
   // Error flag
   output reg         error,        // Error detected
   
   // CAN physical interface
   input wire         can_rx,       // CAN RX (recessive = 1, dominant = 0)
   output reg         can_tx        // CAN TX (recessive = 1, dominant = 0)
   );

   // CAN bit timing - 125 kHz CAN bit rate (for 27 MHz system clock)
   // One bit time = 27000000 / 125000 = 216 clock cycles
   parameter BIT_TIME = 216;
   parameter SAMPLE_POINT = BIT_TIME * 3 / 4;  // Sample at 75% of bit time
   
   // Bit timing counter
   reg [7:0] bit_counter;
   reg [7:0] bit_time_counter;
   
   // Bit stuffing
   reg [2:0] same_bit_count;
   reg last_bit;
   
   // TX State Machine
   localparam TX_IDLE        = 0,
              TX_SOF         = 1,
              TX_ID          = 2,
              TX_RTR         = 3,
              TX_IDE         = 4,
              TX_R0          = 5,
              TX_DLC         = 6,
              TX_DATA        = 7,
              TX_CRC         = 8,
              TX_CRC_DELIM   = 9,
              TX_ACK_SLOT    = 10,
              TX_ACK_DELIM   = 11,
              TX_EOF         = 12,
              TX_IFS         = 13;
   
   reg [3:0] tx_state;
   reg [3:0] bit_index;
   reg [2:0] byte_index;
   reg [14:0] crc_reg;
   
   // RX State Machine
   localparam RX_IDLE        = 0,
              RX_SOF         = 1,
              RX_ID          = 2,
              RX_RTR         = 3,
              RX_IDE         = 4,
              RX_R0          = 5,
              RX_DLC         = 6,
              RX_DATA        = 7,
              RX_CRC         = 8,
              RX_CRC_DELIM   = 9,
              RX_ACK_SLOT    = 10,
              RX_ACK_DELIM   = 11,
              RX_EOF         = 12;
   
   reg [3:0] rx_state;
   reg [3:0] rx_bit_index;
   reg [2:0] rx_byte_index;
   reg [14:0] rx_crc_reg;
   reg [10:0] rx_id_temp;
   reg [3:0] rx_dlc_temp;
   reg [63:0] rx_data_temp;
   
   // Synchronization
   reg can_rx_sync;
   always @(posedge clk) begin
      can_rx_sync <= can_rx;
   end
   
   // Bit timing generation
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         bit_time_counter <= 0;
      end else if (busy || rx_state != RX_IDLE) begin
         if (bit_time_counter >= BIT_TIME - 1) begin
            bit_time_counter <= 0;
         end else begin
            bit_time_counter <= bit_time_counter + 1;
         end
      end else begin
         bit_time_counter <= 0;
      end
   end
   
   wire bit_sample = (bit_time_counter == SAMPLE_POINT);
   wire bit_complete = (bit_time_counter == BIT_TIME - 1);
   
   // CRC calculation (CAN CRC-15)
   function [14:0] crc_next;
      input [14:0] crc;
      input bit_in;
      reg crc_msb;
      begin
         crc_msb = crc[14];
         crc_next = {crc[13:0], 1'b0} ^ (crc_msb ^ bit_in ? 15'h4599 : 15'h0);
      end
   endfunction
   
   // Transmitter
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         tx_state <= TX_IDLE;
         can_tx <= 1'b1;  // Recessive
         busy <= 1'b0;
         tx_complete <= 1'b0;
         error <= 1'b0;
         bit_index <= 0;
         byte_index <= 0;
         crc_reg <= 15'h0;
         same_bit_count <= 0;
         last_bit <= 1'b1;
      end else begin
         tx_complete <= 1'b0;
         
         case(tx_state)
            TX_IDLE: begin
               can_tx <= 1'b1;  // Recessive
               busy <= 1'b0;
               error <= 1'b0;
               if (tx_start) begin
                  tx_state <= TX_SOF;
                  busy <= 1'b1;
                  bit_index <= 0;
                  byte_index <= 0;
                  crc_reg <= 15'h0;
                  same_bit_count <= 0;
                  last_bit <= 1'b1;
               end
            end
            
            TX_SOF: begin
               if (bit_complete) begin
                  can_tx <= 1'b0;  // Dominant SOF
                  tx_state <= TX_ID;
                  bit_index <= 10;  // Start from MSB of ID
                  crc_reg <= crc_next(15'h0, 1'b0);
               end
            end
            
            TX_ID: begin
               if (bit_complete) begin
                  can_tx <= tx_id[bit_index];
                  crc_reg <= crc_next(crc_reg, tx_id[bit_index]);
                  if (bit_index == 0) begin
                     tx_state <= TX_RTR;
                  end else begin
                     bit_index <= bit_index - 1;
                  end
               end
            end
            
            TX_RTR: begin
               if (bit_complete) begin
                  can_tx <= 1'b0;  // Data frame (RTR=0)
                  crc_reg <= crc_next(crc_reg, 1'b0);
                  tx_state <= TX_IDE;
               end
            end
            
            TX_IDE: begin
               if (bit_complete) begin
                  can_tx <= 1'b0;  // Standard format (IDE=0)
                  crc_reg <= crc_next(crc_reg, 1'b0);
                  tx_state <= TX_R0;
               end
            end
            
            TX_R0: begin
               if (bit_complete) begin
                  can_tx <= 1'b0;  // Reserved bit (R0=0)
                  crc_reg <= crc_next(crc_reg, 1'b0);
                  tx_state <= TX_DLC;
                  bit_index <= 3;
               end
            end
            
            TX_DLC: begin
               if (bit_complete) begin
                  can_tx <= tx_dlc[bit_index];
                  crc_reg <= crc_next(crc_reg, tx_dlc[bit_index]);
                  if (bit_index == 0) begin
                     if (tx_dlc > 0) begin
                        tx_state <= TX_DATA;
                        bit_index <= 7;
                        byte_index <= 0;
                     end else begin
                        tx_state <= TX_CRC;
                        bit_index <= 14;
                     end
                  end else begin
                     bit_index <= bit_index - 1;
                  end
               end
            end
            
            TX_DATA: begin
               if (bit_complete) begin
                  can_tx <= tx_data[byte_index * 8 + bit_index];
                  crc_reg <= crc_next(crc_reg, tx_data[byte_index * 8 + bit_index]);
                  
                  if (bit_index == 0) begin
                     if (byte_index == tx_dlc - 1) begin
                        tx_state <= TX_CRC;
                        bit_index <= 14;
                     end else begin
                        byte_index <= byte_index + 1;
                        bit_index <= 7;
                     end
                  end else begin
                     bit_index <= bit_index - 1;
                  end
               end
            end
            
            TX_CRC: begin
               if (bit_complete) begin
                  can_tx <= crc_reg[bit_index];
                  if (bit_index == 0) begin
                     tx_state <= TX_CRC_DELIM;
                  end else begin
                     bit_index <= bit_index - 1;
                  end
               end
            end
            
            TX_CRC_DELIM: begin
               if (bit_complete) begin
                  can_tx <= 1'b1;  // Recessive delimiter
                  tx_state <= TX_ACK_SLOT;
               end
            end
            
            TX_ACK_SLOT: begin
               if (bit_complete) begin
                  can_tx <= 1'b1;  // Recessive (waiting for ACK)
                  // In real CAN, receiver would pull this low
                  tx_state <= TX_ACK_DELIM;
               end
            end
            
            TX_ACK_DELIM: begin
               if (bit_complete) begin
                  can_tx <= 1'b1;  // Recessive delimiter
                  tx_state <= TX_EOF;
                  bit_index <= 6;  // 7 recessive bits
               end
            end
            
            TX_EOF: begin
               if (bit_complete) begin
                  can_tx <= 1'b1;  // Recessive EOF
                  if (bit_index == 0) begin
                     tx_state <= TX_IFS;
                     bit_index <= 2;  // 3 recessive bits
                  end else begin
                     bit_index <= bit_index - 1;
                  end
               end
            end
            
            TX_IFS: begin
               if (bit_complete) begin
                  can_tx <= 1'b1;  // Recessive IFS
                  if (bit_index == 0) begin
                     tx_state <= TX_IDLE;
                     tx_complete <= 1'b1;
                     busy <= 1'b0;
                  end else begin
                     bit_index <= bit_index - 1;
                  end
               end
            end
            
            default: tx_state <= TX_IDLE;
         endcase
      end
   end
   
   // Receiver (simplified - detects SOF and receives frame)
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         rx_state <= RX_IDLE;
         rx_valid <= 1'b0;
         rx_id <= 11'h0;
         rx_dlc <= 4'h0;
         rx_data <= 64'h0;
         rx_bit_index <= 0;
         rx_byte_index <= 0;
         rx_id_temp <= 11'h0;
         rx_dlc_temp <= 4'h0;
         rx_data_temp <= 64'h0;
         rx_crc_reg <= 15'h0;
      end else begin
         rx_valid <= 1'b0;
         
         case(rx_state)
            RX_IDLE: begin
               if (can_rx_sync == 1'b0 && !busy) begin  // SOF detected
                  rx_state <= RX_SOF;
                  rx_crc_reg <= crc_next(15'h0, 1'b0);
               end
            end
            
            RX_SOF: begin
               if (bit_complete) begin
                  rx_state <= RX_ID;
                  rx_bit_index <= 10;
               end
            end
            
            RX_ID: begin
               if (bit_sample) begin
                  rx_id_temp[rx_bit_index] <= can_rx_sync;
                  rx_crc_reg <= crc_next(rx_crc_reg, can_rx_sync);
               end
               if (bit_complete) begin
                  if (rx_bit_index == 0) begin
                     rx_state <= RX_RTR;
                  end else begin
                     rx_bit_index <= rx_bit_index - 1;
                  end
               end
            end
            
            RX_RTR: begin
               if (bit_sample) begin
                  rx_crc_reg <= crc_next(rx_crc_reg, can_rx_sync);
               end
               if (bit_complete) begin
                  rx_state <= RX_IDE;
               end
            end
            
            RX_IDE: begin
               if (bit_sample) begin
                  rx_crc_reg <= crc_next(rx_crc_reg, can_rx_sync);
               end
               if (bit_complete) begin
                  rx_state <= RX_R0;
               end
            end
            
            RX_R0: begin
               if (bit_sample) begin
                  rx_crc_reg <= crc_next(rx_crc_reg, can_rx_sync);
               end
               if (bit_complete) begin
                  rx_state <= RX_DLC;
                  rx_bit_index <= 3;
               end
            end
            
            RX_DLC: begin
               if (bit_sample) begin
                  rx_dlc_temp[rx_bit_index] <= can_rx_sync;
                  rx_crc_reg <= crc_next(rx_crc_reg, can_rx_sync);
               end
               if (bit_complete) begin
                  if (rx_bit_index == 0) begin
                     if (rx_dlc_temp > 0) begin
                        rx_state <= RX_DATA;
                        rx_bit_index <= 7;
                        rx_byte_index <= 0;
                     end else begin
                        rx_state <= RX_CRC;
                        rx_bit_index <= 14;
                     end
                  end else begin
                     rx_bit_index <= rx_bit_index - 1;
                  end
               end
            end
            
            RX_DATA: begin
               if (bit_sample) begin
                  rx_data_temp[rx_byte_index * 8 + rx_bit_index] <= can_rx_sync;
                  rx_crc_reg <= crc_next(rx_crc_reg, can_rx_sync);
               end
               if (bit_complete) begin
                  if (rx_bit_index == 0) begin
                     if (rx_byte_index == rx_dlc_temp - 1) begin
                        rx_state <= RX_CRC;
                        rx_bit_index <= 14;
                     end else begin
                        rx_byte_index <= rx_byte_index + 1;
                        rx_bit_index <= 7;
                     end
                  end else begin
                     rx_bit_index <= rx_bit_index - 1;
                  end
               end
            end
            
            RX_CRC: begin
               if (bit_complete) begin
                  if (rx_bit_index == 0) begin
                     rx_state <= RX_CRC_DELIM;
                  end else begin
                     rx_bit_index <= rx_bit_index - 1;
                  end
               end
            end
            
            RX_CRC_DELIM: begin
               if (bit_complete) begin
                  rx_state <= RX_ACK_SLOT;
               end
            end
            
            RX_ACK_SLOT: begin
               if (bit_complete) begin
                  rx_state <= RX_ACK_DELIM;
               end
            end
            
            RX_ACK_DELIM: begin
               if (bit_complete) begin
                  rx_state <= RX_EOF;
                  rx_bit_index <= 6;
               end
            end
            
            RX_EOF: begin
               if (bit_complete) begin
                  if (rx_bit_index == 0) begin
                     // Frame complete - latch data
                     rx_id <= rx_id_temp;
                     rx_dlc <= rx_dlc_temp;
                     rx_data <= rx_data_temp;
                     rx_valid <= 1'b1;
                     rx_state <= RX_IDLE;
                  end else begin
                     rx_bit_index <= rx_bit_index - 1;
                  end
               end
            end
            
            default: rx_state <= RX_IDLE;
         endcase
      end
   end

endmodule
