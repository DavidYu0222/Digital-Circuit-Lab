`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,  //btn[3] for control
  output [3:0] usr_led,
  output LCD_RS,    //register select
  output LCD_RW,    //read / write
  output LCD_E,     //enable
  output [3:0] LCD_D    //data
);

// turn off all the LEDs
assign usr_led = 4'b0000;
//scroll control
wire slow_clk;
wire btn_level;
reg scroll = 1;
 //16 ASCII * 8bit
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [4:0] counter = 0;
reg [26:0] timer = 0;
//25 Fibonacci number (each 8 bits)
//integer i;
//reg [7:0] fibo[24:0];
reg [127:0] row [24:0];

LCD_module lcd0(
    .clk(clk),
    .reset(~reset_n),
    .row_A(row_A),
    .row_B(row_B),
    .LCD_E(LCD_E),
    .LCD_RS(LCD_RS),
    .LCD_RW(LCD_RW),
    .LCD_D(LCD_D)
);
//Debounce for botton 3
debounce btn_db0(
    .clk(clk),
    .btn_input(usr_btn[3]),
    .btn_output(btn_level)
);
//Slow clock for scroll control
clock_div clk_0(
    .clk_100M(clk),
    .slow_clk(slow_clk)
);
//Calculate and store the first 25 Fibonacci numbers in a register array
/*
initial begin
    fibo[0] = 0;
    fibo[1] = 1;
    for (i = 0; i < 25; i = i + 1) begin
        if (i >= 2)begin
            fibo[i] = fibo[i - 1] + fibo[i - 2];
        end
        row[i][16*8-1 : 10*8] = "Fibo #"; 
        $sformat(row[i][10*8-1 : 8*8], "%02X", i);
        row[i][8*8-1 : 4*8] = " is ";
        $sformat(row[i][4*8-1 : 0], "%04X", fibo[i]);
        
    end
end
*/
initial begin
    row[0] = "Fibo #01 is 0000";
    row[1] = "Fibo #02 is 0001";
    row[2] = "Fibo #03 is 0001";
    row[3] = "Fibo #04 is 0002";
    row[4] = "Fibo #05 is 0003";
    row[5] = "Fibo #06 is 0005";
    row[6] = "Fibo #07 is 0008";
    row[7] = "Fibo #08 is 000D";
    row[8] = "Fibo #09 is 0015";
    row[9] = "Fibo #0A is 0022";
    row[10] = "Fibo #0B is 0037";
    row[11] = "Fibo #0C is 0059";
    row[12] = "Fibo #0D is 0090";
    row[13] = "Fibo #0E is 00E9";
    row[14] = "Fibo #0F is 0179";
    row[15] = "Fibo #10 is 0262";
    row[16] = "Fibo #11 is 03DB";
    row[17] = "Fibo #12 is 063D";
    row[18] = "Fibo #13 is 0A18";
    row[19] = "Fibo #14 is 1055";
    row[20] = "Fibo #15 is 1A6D";
    row[21] = "Fibo #16 is 2AC2";
    row[22] = "Fibo #17 is 452F";
    row[23] = "Fibo #18 is 6FF1";
    row[24] = "Fibo #19 is B520";
end

//Control scroll direction
always @(posedge slow_clk or negedge reset_n) begin
  if (~reset_n)
    scroll <= 1;
  else begin
    scroll <= (btn_level == 1) ? ~scroll : scroll;
  end
end

always @(posedge clk or negedge reset_n) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    timer = 0;
    counter = 0;
    row_A = "                ";
    row_B = "                ";
  end else begin
    //timer for controlling scroll speed
    if (timer < 7000_0000) begin 
        timer <= timer + 1'b1;
    end else begin
        timer <= 0;
    end
    
    if (timer == 7000_0000) begin
        //Scroll up
        if (scroll) begin
            if (counter < 24) begin
                row_A = row[counter];
                counter = counter + 1;
                row_B = row[counter];
            end else begin
                row_A = row[counter];
                counter = 0;
                row_B = row[counter];
            end 
        //Scroll down
        end else begin
            if (counter > 0) begin
                row_B = row[counter];
                counter = counter - 1;
                row_A = row[counter];
            end else begin
                row_B = row[counter];
                counter = 24;
                row_A = row[counter];
            end
        end
        
    end
  end
end

endmodule

/*
module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    assign btn_output = btn_input;
endmodule
*/

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
wire slow_clk;
wire Q1,Q2,Q2_bar,Q0;

clock_div u1(clk,slow_clk);
dff d0(slow_clk, btn_input, Q0 );
dff d1(slow_clk, Q0, Q1 );
dff d2(slow_clk, Q1, Q2 );

assign Q2_bar = ~Q2;
assign btn_output = Q1 & Q2_bar;
endmodule

// Slow clock for debouncing 
module clock_div(input clk_100M, output reg slow_clk);
    reg [26:0]counter = 0;
    always @(posedge clk_100M) begin
        counter <= (counter >= 249999)?0:counter+1;
        slow_clk <= (counter < 125000)?1'b0:1'b1;
    end
endmodule

// D-flip-flop for debouncing module 
module dff(input DFF_CLOCK, D, output reg Q);
    always @ (posedge DFF_CLOCK) begin
        Q <= D;
    end
endmodule