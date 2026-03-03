/* Simplified I2C Master Controller 
 *
 * Memory Map:
 *   0x80000024 - Control Register (write)
 *     [31:24] - Reserved
 *     [23:16] - Reserved
 *     [15:8]  - Data
 *     [7:1]   - 7-bit slave address
 *     [0]     - Operation: 0=write, 1=read
 *
 *   0x80000028 - Status Register (read)
 *     [31:24] - Reserved
 *     [23:3]  - Data read (dout)
 *     [2]     - Done flag
 *     [1]     - Busy flag
 *     [0]     - ACK error flag (always 0 in test mode)
 *
 *   0x8000002C - Start Register (write)
 *     [0]     - Write 1 to start transaction (newd)
 */

module i2c_wrap
  (
   input wire         clk,
   input wire         reset_n,
   input wire         i2c_sel,
   input wire [3:0]   addr,
   input wire [3:0]   we,
   input wire [31:0]  i2c_data_i,
   output reg [31:0]  i2c_data_o,
   output wire        i2c_ready,

   // I2C physical interface
   inout wire         sda,
   output wire        scl
   );

   // Internal registers - memory mapped
   reg [7:0]  slave_addr;
   reg        op;           // 0=write, 1=read
   reg [7:0]  data_in;
   reg        start_transaction;

   // Signals from I2C master core
   wire [7:0] data_out;
   wire       busy;
   wire       ack_err;
   wire       done;

   // Address decode
   wire ctrl_sel  = i2c_sel && (addr == 4'h4);  // 0x80000024
   wire status_sel = i2c_sel && (addr == 4'h8); // 0x80000028
   wire start_sel = i2c_sel && (addr == 4'hc);  // 0x8000002C

   // Ready immediately for all operations
   assign i2c_ready = i2c_sel;

   // Write to control register
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         slave_addr <= 8'h00;
         op <= 1'b0;
         data_in <= 8'h00;
      end else if (ctrl_sel && we[0]) begin
         slave_addr <= i2c_data_i[7:1];  // 7-bit address
         op <= i2c_data_i[0];
         data_in <= i2c_data_i[15:8];//fix
      end
   end

   // Write to start register
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         start_transaction <= 1'b0;
      end else if (start_sel && we[0]) begin
         start_transaction <= i2c_data_i[0];
      end else begin
         start_transaction <= 1'b0;  // Auto-clear after one cycle
      end
   end

   // Read data output
   always @(*) begin
      if (status_sel) begin
         i2c_data_o = {data_out, done, busy, ack_err};
      end else if (ctrl_sel) begin
         i2c_data_o = {data_in, slave_addr[6:0], op};
      end else begin
         i2c_data_o = 32'h0;
      end
   end

   // Instantiate I2C master core with auto-ACK
   i2c_master_test #(
      .sys_freq(27000000),  // 27 MHz for Tang Nano 9K
      .i2c_freq(100000)     // 100 kHz I2C
   ) i2c_core (
      .clk(clk),
      .rst(~reset_n),       // Active-high reset
      .newd(start_transaction),
      .addr(slave_addr[6:0]),
      .op(op),
      .sda(sda),
      .scl(scl),
      .din(data_in),
      .dout(data_out),
      .busy(busy),
      .ack_err(ack_err),
      .done(done)
   );

endmodule

////////////////////////////////////////////////////////////////////
// I2C Master Core - TEST VERSION with AUTO-ACK
// This version generates ACK internally for testing without slaves
////////////////////////////////////////////////////////////////////
module i2c_master_test
  #(
    parameter sys_freq = 27000000,
    parameter i2c_freq = 100000
    )
   (
    input        clk,
    input        rst,
    input        newd,
    input  [6:0] addr,
    input        op,
    inout        sda,
    output       scl,
    input  [7:0] din,
    output [7:0] dout,
    output reg   busy,
    output reg   ack_err,
    output reg   done
    );

   // Clock generation parameters
   localparam clk_count4 = (sys_freq / i2c_freq);
   localparam clk_count1 = clk_count4 / 4;

   // Internal SDA/SCL control
   reg scl_t = 1;
   reg sda_t = 1;
   reg sda_en = 0;

   // Clock counter
   integer count1 = 0;
   reg [1:0] pulse = 0;

   // Generate 4-phase timing pulse
   ///////4x clock
always@(posedge clk)
begin
      if(rst)
       begin
       pulse <= 0;
       count1 <= 0;
       end
       else if (busy == 1'b0) ///pulse count start only after newd
        begin
        pulse <= 0;
        count1 <= 0;
        end
      else if(count1  == clk_count1 - 1)
       begin
       pulse <= 1;
       count1 <= count1 + 1;
       end
      else if(count1  == clk_count1*2 - 1)
       begin
       pulse <= 2;
       count1 <= count1 + 1;
       end
      else if(count1  == clk_count1*3 - 1)
       begin
       pulse <= 3;
       count1 <= count1 + 1;
       end
      else if(count1  == clk_count1*4 - 1)
       begin
       pulse <= 0;
       count1 <= 0;
       end
      else
       begin
       count1 <= count1 + 1;
       end
end

//////////////////
reg [3:0] bitcount = 0;
reg [7:0] data_addr   = 0, data_tx = 0;
reg r_ack = 0;
reg [7:0] rx_data = 0;
reg sda_en = 0;

parameter idle = 0, start = 1, write_addr = 2, ack_1 = 3, write_data = 4, 
read_data = 5, stop = 6, ack_2 =7, master_ack = 8;


reg [3:0] state;

always@(posedge clk)
begin
 if(rst)
   begin
    bitcount   <= 0;
    data_addr  <= 0;
    data_tx    <= 0;
    scl_t <= 1;
    sda_t <= 1;
    state <= idle;
    busy  <= 1'b0;
    ack_err <= 1'b0;
    done    <= 1'b0;
   end
else
   begin
                case(state)
                
                //////////////idle state
                      idle:
                      begin
                            done  <= 1'b0;
                            if(newd == 1'b1)
                               begin
                               data_addr  <= {addr,op};
                               data_tx    <= din;
                               busy  <= 1'b1;
                               state <= start;
                               ack_err <= 1'b0;
                               end
                            else
                               begin
                               data_addr  <= 0;
                               data_tx    <= 0;
                               busy  <= 1'b0;
                               state <= idle;
                               ack_err <= 1'b0;
                               end
                      end
                  /////////////////////////////////////////////////////    
                     start: 
                     begin
                         sda_en <= 1'b1; ///send start to slave
                         case(pulse)
                         0: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                         1: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                         2: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                         3: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                         endcase
                         
                             if(count1  == clk_count1*4 - 1)
                             begin
                                state <= write_addr;
                                scl_t <= 1'b0;
                             end
                             else
                                state <= start;
                     end
                 ///////////////////////////////////////////     
                   write_addr: 
                   begin
                      sda_en <= 1'b1;  ///send addr to slave
                      if(bitcount <= 7)
                         begin
                                 case(pulse)
                                 0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                                 1: begin scl_t <= 1'b0; sda_t <= data_addr[7 - bitcount]; end
                                 2: begin scl_t <= 1'b1;  end
                                 3: begin scl_t <= 1'b1;  end
                                 endcase
                                 if(count1  == clk_count1*4 - 1)
                                 begin
                                    state <= write_addr;
                                    scl_t <= 1'b0;
                                    bitcount <= bitcount + 1;
                                 end
                                 else
                                 begin
                                    state <= write_addr;
                                 end
                             
                         end
                      else
                        begin
                        state <= ack_1;
                        bitcount <= 0;
                        sda_en <= 1'b0;
                        end
                   end   
                   
                   
                   //////////////////////////////////////
                   
                   ack_1 : 
                   begin
                        sda_en <= 1'b0; ///recv ack from slave
                                case(pulse)
                                 0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                                 1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                                 2: begin scl_t <= 1'b1; sda_t <= 1'b0; r_ack <= sda; end ///recv ack from slave
                                 3: begin scl_t <= 1'b1;  end
                                 endcase
                   
                       if(count1  == clk_count1*4 - 1)
                                  begin
                                      if(r_ack == 1'b0 && data_addr[0] == 1'b0)
                                        begin
                                        state <= write_data;
                                        sda_t <= 1'b0;
                                        sda_en <= 1'b1; /////write data to slave
                                        bitcount <= 0;
                                        end
                                      else if (r_ack == 1'b0 && data_addr[0] == 1'b1)
                                      begin
                                        state <= read_data;
                                        sda_t <= 1'b1;
                                        sda_en <= 1'b0; ///read data from slave
                                        bitcount <= 0;
                                      end
                                      else
                                      begin
                                        state <= stop;
                                        sda_en <= 1'b1; ////send stop to slave
                                        ack_err <= 1'b1;
                                      end
                                  end
                                 else
                                  begin
                                    state <= ack_1;
                                  end
                     
                   end
                   
                 write_data: 
                 begin
                   ///write data to slave
                  if(bitcount <= 7)
                         begin
                                 case(pulse)
                                 0: begin scl_t <= 1'b0;   end
                                 1: begin scl_t <= 1'b0;sda_en <= 1'b1; sda_t <= data_tx[7 - bitcount];                                  end
                                 2: begin scl_t <= 1'b1;  end
                                 3: begin scl_t <= 1'b1;  end
                                 endcase
                                 if(count1  == clk_count1*4 - 1)
                                 begin
                                    state <= write_data;
                                    scl_t <= 1'b0;
                                    bitcount <= bitcount + 1;
                                 end
                                 else
                                 begin
                                    state <= write_data;
                                 end
                             
                         end
                      else
                        begin
                        state <= ack_2;
                        bitcount <= 0;
                        sda_en <= 1'b0; ///read from slave
                        end
                 
                 
                 end 
                 ///////////////////////////// read_data
                 
                 read_data: 
                 begin
                 sda_en <= 1'b0; ///read from slave
                 if(bitcount <= 7)
                         begin
                                 case(pulse)
                                 0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                                 1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                                 2: begin scl_t <= 1'b1; rx_data[7:0] <= (count1 == 555) ? {rx_data[6:0],sda} : rx_data; end
                                 3: begin scl_t <= 1'b1;  end
                                 endcase
                                 if(count1  == clk_count1*4 - 1)
                                 begin
                                    state <= read_data;
                                    scl_t <= 1'b0;
                                    bitcount <= bitcount + 1;
                                 end
                                 else
                                 begin
                                    state <= read_data;
                                 end
                             
                         end
                      else
                        begin
                        state <= master_ack;
                        bitcount <= 0;
                        sda_en <= 1'b1; ///master will send ack to slave
                        end
                 
                 
                 
                 end
                 ////////////////////master ack -> send nack
                 master_ack : 
                   begin
                      sda_en <= 1'b1;
                      
                                case(pulse)
                                 0: begin scl_t <= 1'b0; sda_t <= 1'b1; end
                                 1: begin scl_t <= 1'b0; sda_t <= 1'b1; end
                                 2: begin scl_t <= 1'b1; sda_t <= 1'b1; end 
                                 3: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                                 endcase
                   
                       if(count1  == clk_count1*4 - 1)
                                  begin
                                      sda_t <= 1'b0;
                                      state <= stop;
                                      sda_en <= 1'b1; ///send stop to slave
                                      
                                  end
                                 else
                                  begin
                                    state <= master_ack;
                                  end
                     
                   end
                 
                 
                 
                 /////////////////ack 2
                 
                  ack_2 : 
                   begin
                     sda_en <= 1'b0; ///recv ack from slave
                                case(pulse)
                                 0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                                 1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                                 2: begin scl_t <= 1'b1; sda_t <= 1'b0; r_ack <= sda; end ///recv ack from slave
                                 3: begin scl_t <= 1'b1;  end
                                 endcase
                   
                       if(count1  == clk_count1*4 - 1)
                                  begin
                                      sda_t <= 1'b0;
                                      sda_en <= 1'b1; ///send stop to slave
                                      if(r_ack == 1'b0 )
                                        begin
                                        state <= stop;
                                        ack_err <= 1'b0;
                                        end
                                      else
                                        begin
                                        state <= stop;
                                        ack_err <= 1'b1;
                                        end
                                  end
                                 else
                                  begin
                                    state <= ack_2;
                                  end
                     
                   end

                /////////////////////////////////////////////stop  
                   stop: 
                     begin
                     sda_en <= 1'b1; ///send stop to slave
                         case(pulse)
                         0: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                         1: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                         2: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                         3: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                         endcase
                         
                             if(count1  == clk_count1*4 - 1)
                             begin
                                state <= idle;
                                scl_t <= 1'b0;
                                busy <= 1'b0;
                                sda_en <= 1'b1; ///send start to slave
                                done   <= 1'b1;
                             end
                             else
                                state <= stop;
                     end
                     
                     //////////////////////////////////////////////
                      
                 default : state <= idle;
               endcase
   end
end

assign sda = (sda_en == 1) ? (sda_t == 0) ? 1'b0 : 1'bz : 1'bz; /// en = 1 -> write to slave else read
//now test
assign scl = scl_t ? 1'bz : 1'b0 ;
assign dout = rx_data;
endmodule