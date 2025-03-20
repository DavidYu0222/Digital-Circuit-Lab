`timescale 1ns / 1ps
//The system clock of Arty board is 100MHz ( 100,000,000 clock per second)
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);


reg [3:0] counter;
reg [3:0] bright;
wire [3:0] btn;
wire pwm_signal;
wire slow_clk;

clock_div c0(clk, slow_clk);
debounce d0(usr_btn[0], clk, btn[0]);
debounce d1(usr_btn[1], clk, btn[1]);
debounce d2(usr_btn[2], clk, btn[2]);
debounce d3(usr_btn[3], clk, btn[3]);
pwm p0(clk, bright, pwm_signal); 

assign usr_led = (pwm_signal) ? counter : 4'b0000;
//assign usr_led = counter;

initial begin
    counter = 4'b0000;
    bright = 4'b0010;
end

always @ (posedge slow_clk or negedge reset_n) begin
    if(reset_n == 0)begin
        counter <=  0;
        bright <=  2;
    end 
    else begin
        if(btn[0] == 1 && $signed(counter) > -8) begin
            counter <= counter - 1;
        end
        if(btn[1] == 1 && $signed(counter) < 7) begin
            counter <= counter + 1;
        end
        if(btn[2] == 1 && bright > 0) begin
            bright <= bright - 1;
        end
         if(btn[3] == 1 && bright < 4) begin
            bright <= bright + 1;
        end
    end
end

endmodule

module pwm (input clk, [3:0]control, output pwm_output);

reg [26:0] counter = 0;
reg pwm_signal;
reg [26:0] duty_cycle;

assign pwm_output = pwm_signal;

always@(*)begin
    case(control)
        4'b0000:
            duty_cycle <= 50000;    //  duty cycle of 5%
        4'b0001:
            duty_cycle <= 250000;   //  duty cycle of 25%
        4'b0010:
            duty_cycle <= 500000;   //  duty cycle of 50%
        4'b0011: 
            duty_cycle <= 750000;   //  duty cycle of 75%
        4'b0100:
            duty_cycle <= 1000000;
        default:
            duty_cycle <= 1000000;
    endcase
end

always @(posedge clk) begin
    counter <= (counter >= 1000000)? 0 : counter + 1'b1;
    pwm_signal <= (counter < duty_cycle)? 1'b1 : 1'b0;
end

endmodule

module debounce(input pb_1,clk,output pb_out);
wire slow_clk;
wire Q1,Q2,Q2_bar,Q0;

clock_div u1(clk,slow_clk);
my_dff d0(slow_clk, pb_1,Q0 );
my_dff d1(slow_clk, Q0,Q1 );
my_dff d2(slow_clk, Q1,Q2 );

assign Q2_bar = ~Q2;
assign pb_out = Q1 & Q2_bar;
endmodule
// Slow clock for debouncing 
module clock_div(input Clk_100M, output reg slow_clk);
    reg [26:0]counter = 0;
    always @(posedge Clk_100M)
    begin
        counter <= (counter >= 2499999)?0:counter+1;
        slow_clk <= (counter < 1250000)?1'b0:1'b1;
    end
endmodule
// D-flip-flop for debouncing module 
module my_dff(input DFF_CLOCK, D, output reg Q);
    always @ (posedge DFF_CLOCK) begin
        Q <= D;
    end
endmodule
