/* 8-Pin GPIO Controller IP
   
   This module provides 8 bidirectional GPIO pins with individual direction control.
   
   Memory Map (base address 0x80000040):
     0x80000040: Direction Register (DIR)
                 [31:8] - Reserved
                 [7:0]  - Pin direction (1=output, 0=input)
     
     0x80000044: Set Register (SET)
                 [31:8] - Reserved
                 [7:0]  - Set output high (write 1 to set, write 0 for no change)
     
     0x80000048: Clear Register (CLR)
                 [31:8] - Reserved
                 [7:0]  - Clear output low (write 1 to clear, write 0 for no change)
     
     0x8000004C: Input Register (IN) - Read Only
                 [31:8] - Reserved
                 [7:0]  - Current pin input values
     
     0x80000050: Output Register (OUT) - Read Only
                 [31:8] - Reserved
                 [7:0]  - Current output register values
*/

module gpio_8pin (
    input wire        clk,
    input wire        reset_n,
    input wire        gpio_sel,         // Chip select
    input wire [4:0]  addr,             // Address bits [4:0]
    input wire [3:0]  gpio_wstrb,       // Write strobe
    input wire [31:0] gpio_data_i,      // Data input
    output reg [31:0] gpio_data_o,      // Data output
    output wire       gpio_ready,       // Ready signal
    
    // GPIO pins (bidirectional)
    inout wire        gpio_pin0,
    inout wire        gpio_pin1,
    inout wire        gpio_pin2,
    inout wire        gpio_pin3,
    inout wire        gpio_pin4,
    inout wire        gpio_pin5,
    inout wire        gpio_pin6,
    inout wire        gpio_pin7
);

    // Internal registers
    reg [7:0] dir;      // Direction: 1=output, 0=input
    reg [7:0] out;      // Output register
    reg [7:0] in_sync;  // Synchronized input
    
    // Address decoding
    localparam ADDR_DIR = 5'h00;   // 0x80000040
    localparam ADDR_SET = 5'h04;   // 0x80000044
    localparam ADDR_CLR = 5'h08;   // 0x80000048
    localparam ADDR_IN  = 5'h0C;   // 0x8000004C
    localparam ADDR_OUT = 5'h10;   // 0x80000050
    
    // Always ready
    assign gpio_ready = gpio_sel;
    
    // Bidirectional pin control
    assign gpio_pin0 = dir[0] ? out[0] : 1'bz;
    assign gpio_pin1 = dir[1] ? out[1] : 1'bz;
    assign gpio_pin2 = dir[2] ? out[2] : 1'bz;
    assign gpio_pin3 = dir[3] ? out[3] : 1'bz;
    assign gpio_pin4 = dir[4] ? out[4] : 1'bz;
    assign gpio_pin5 = dir[5] ? out[5] : 1'bz;
    assign gpio_pin6 = dir[6] ? out[6] : 1'bz;
    assign gpio_pin7 = dir[7] ? out[7] : 1'bz;
    
    // Input synchronization (double-flop for metastability)
    reg [7:0] in_async;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            in_async <= 8'h00;
            in_sync <= 8'h00;
        end else begin
            in_async <= {gpio_pin7, gpio_pin6, gpio_pin5, gpio_pin4,
                        gpio_pin3, gpio_pin2, gpio_pin1, gpio_pin0};
            in_sync <= in_async;
        end
    end
    
    // Register write logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dir <= 8'h00;  // All pins default to input
            out <= 8'h00;
        end else if (gpio_sel && |gpio_wstrb) begin
            case (addr[4:2])
                3'b000: begin  // ADDR_DIR
                    if (gpio_wstrb[0]) begin
                        dir <= gpio_data_i[7:0];
                    end
                end
                
                3'b001: begin  // ADDR_SET
                    if (gpio_wstrb[0]) begin
                        // Set bits high where both SET and DIR are 1
                        out <= out | (gpio_data_i[7:0] & dir);
                    end
                end
                
                3'b010: begin  // ADDR_CLR
                    if (gpio_wstrb[0]) begin
                        // Clear bits low where both CLR and DIR are 1
                        out <= out & ~(gpio_data_i[7:0] & dir);
                    end
                end
                
                // IN and OUT registers are read-only
            endcase
        end
    end
    
    // Register read logic
    always @(*) begin
        case (addr[4:2])
            3'b000: begin  // ADDR_DIR
                gpio_data_o = {24'h0, dir};
            end
            3'b001: begin  // ADDR_SET (read back as current out value)
                gpio_data_o = {24'h0, out & dir};
            end
            3'b010: begin  // ADDR_CLR (read back as inverted out value)
                gpio_data_o = {24'h0, (~out) & dir};
            end
            3'b011: begin  // ADDR_IN
                gpio_data_o = {24'h0, in_sync};
            end
            3'b100: begin  // ADDR_OUT
                gpio_data_o = {24'h0, out};
            end
            default: begin
                gpio_data_o = 32'h0;
            end
        endcase
    end

endmodule