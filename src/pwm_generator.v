/* PWM Generator Module with Memory-Mapped Interface
 *
 * Memory Map:
 *   0x80000018 - PWM Control/Duty Cycle Register
 *                bits [3:0] - duty cycle (0-10, where 10 = 100%)
 *                bits [4]   - enable PWM output
 */

module pwm_generator (
    input wire clk,
    input wire reset_n,
    input wire pwm_sel,
    input wire [31:0] pwm_data_i,
    input wire [3:0] we,
    output reg pwm_ready,
    output reg [31:0] pwm_data_o,
    output wire pwm_out
);

    reg [3:0] duty_cycle;      // 0-10 representing 0%-100% duty cycle
    reg pwm_enable;            // Enable bit for PWM output
    reg [3:0] counter_pwm;     // Counter for creating PWM signal
    reg [11:0] counter_freq;   // Counter for Fixing Frequency


    always @(posedge clk or negedge reset_n)// To generate 100Khz freq
    begin
        if(counter_freq == 12'd270 || !reset_n) 
            counter_freq <= 0;
        else 
            counter_freq <= counter_freq + 1'b1;
    end

    // Memory-mapped register interface
    always @(posedge clk) begin
        if (!reset_n) begin
            duty_cycle <= 4'd5;
            pwm_enable <= 1'b0;
            pwm_ready <= 1'b0;
        end else begin
            pwm_ready <= 1'b0;
            
            if (pwm_sel) begin
                pwm_ready <= 1'b1;
                
                // Write operation
                if (we[0]) begin
                    duty_cycle <= pwm_data_i[3:0];
                    pwm_enable <= pwm_data_i[4];
                end
                
                // Read operation
                pwm_data_o <= {27'b0, pwm_enable, duty_cycle};
            end
        end
    end

    // PWM counter (10KHz PWM frequency from 27MHz clock )
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter_pwm <= 4'd0;
        end else if(counter_freq == 12'd135 ) begin
            counter_pwm <= counter_pwm + 4'd1;
            if (counter_pwm >= 4'd9)
                counter_pwm <= 4'd0;
        end
    end

    // PWM output generation
    assign pwm_out = pwm_enable ? (counter_pwm < duty_cycle) : 1'b0;

endmodule
