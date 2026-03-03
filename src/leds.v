/* It is a peripheral that allows software on the
 core to write to a register that controls the LEDs on the
 Fpga board.  It can also read this register.
*/ 

module test_leds
  (
   input wire         clk,
   input wire         reset_n,
   input wire         leds_sel,
   input wire [4:0]   leds_data_i,
   input wire         we,
   output wire        leds_ready,
   output wire [31:0] leds_data_o
   );

   reg [4:0]          leds = 'b0;
   assign leds_data_o = {27'b000000000000000000000000000, leds};
   assign leds_ready = leds_sel;

   always @(posedge clk or negedge reset_n)
     if (!reset_n) 
       leds <= 'b0;
     else if (leds_sel)
       if (we) leds <= leds_data_i;

endmodule
