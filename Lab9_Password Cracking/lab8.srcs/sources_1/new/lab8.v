`timescale 1ns / 1ps

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_INIT = 2'b00, S_MAIN_CRAC = 2'b01,
                            S_MAIN_SHOW = 2'b10, S_MAIN_CHEC = 2'b11;

// Declare system variables
reg  [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;   //53589793
wire btn_level, btn;
reg  prev_btn_level;
reg  [1:0] P, P_next;

reg  [127:0] row_A;
reg  [127:0] row_B;
reg  [0:63]  txt  [0:3];
wire [0:127] hash0, hash1, hash2, hash3;
wire [0:63]  ans0, ans1, ans2, ans3;
reg  [63:0]  ans_reg;
//reg  en [0:2];
//reg check[0:2];
//wire hash_valid0, hash_valid1, hash_valid2, hash_valid3;

wire slow_clk;
wire double_slow_clk;
reg  [31:0]   counter;
reg  [55:0]  timer;
reg  done = 0;

assign usr_led = 4'h00;

clk_div#(20) clk_divider0(.clk(clk), .reset(~reset_n), .clk_out( slow_clk));
clk_div#(40) clk_divider1(.clk(clk), .reset(~reset_n), .clk_out(double_slow_clk));

debounce btn_db0(
  .clk(slow_clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

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

md5 m0(.clk(double_slow_clk), .in_txt(txt[0]), .hash(hash0), .out_txt(ans0));
md5 m1(.clk(double_slow_clk), .in_txt(txt[1]), .hash(hash1), .out_txt(ans1));
md5 m2(.clk(double_slow_clk), .in_txt(txt[2]), .hash(hash2), .out_txt(ans2));
//md5 m3(.clk(double_slow_clk), .in_txt(txt[3]), .hash(hash3), .out_txt(ans3));

// Enable one cycle of btn_pressed per each button hit
always @(posedge slow_clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
//FSM Main Driver
always @(posedge  slow_clk) begin
    if (~reset_n) P <= S_MAIN_INIT;
    else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT:
        if (btn_pressed) P_next <= S_MAIN_CRAC;
        else P_next <= S_MAIN_INIT;
    S_MAIN_CRAC:
        P_next <= S_MAIN_CHEC;
    S_MAIN_CHEC:
        if (done) P_next <= S_MAIN_SHOW;
        else P_next <= S_MAIN_CRAC;
    S_MAIN_SHOW:
        if (btn_pressed) P_next <= S_MAIN_INIT;
        else P_next <= S_MAIN_SHOW;
    default:
        P_next <= S_MAIN_INIT;
  endcase
end
// ------------------------------------------------------------------------

//timer (ms)
always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_INIT)
      timer <= "0000000";
  else if (P == S_MAIN_CRAC || P == S_MAIN_CHEC) begin
      if(counter >= 100_000) begin
            if (timer[ 0 +: 4] == 4'h9) begin timer[ 0 +: 4] <= 4'h0;
            if (timer[ 8 +: 4] == 4'h9) begin timer[ 8 +: 4] <= 4'h0;
            if (timer[16 +: 4] == 4'h9) begin timer[16 +: 4] <= 4'h0;
            if (timer[24 +: 4] == 4'h9) begin timer[24 +: 4] <= 4'h0;
            if (timer[32 +: 4] == 4'h9) begin timer[32 +: 4] <= 4'h0;
            if (timer[40 +: 4] == 4'h9) begin timer[40 +: 4] <= 4'h0;
            if (timer[48 +: 4] == 4'h9) begin timer[48 +: 4] <= 4'h0;
            end else timer[48 +: 4] <= timer[48 +: 4] + 1;
            end else timer[40 +: 4] <= timer[40 +: 4] + 1;
            end else timer[32 +: 4] <= timer[32 +: 4] + 1;
            end else timer[24 +: 4] <= timer[24 +: 4] + 1;
            end else timer[16 +: 4] <= timer[16 +: 4] + 1;
            end else timer[ 8 +: 4] <= timer[ 8 +: 4] + 1;
            end else timer[ 0 +: 4] <= timer[ 0 +: 4] + 1; 
            counter <= 0;
      end 
      else
        counter <= counter + 1;
  end
end

integer idx;
always @(posedge  slow_clk) begin
  if (~reset_n || P == S_MAIN_INIT) begin
    txt[0] <= "00000000";
    txt[1] <= "33333333";
    txt[2] <= "66666666";
    //txt[3] <= "75000000";
    done <= 0;
  end  
  //guess code control
  else if (P == S_MAIN_CRAC) begin
    for(idx=0; idx <= 2; idx = idx + 1) begin
            if (txt[idx][60 :63] == 4'h9) begin txt[idx][ 60 :63] <= 4'h0;
            if (txt[idx][52 : 55] == 4'h9) begin txt[idx][52 : 55] <= 4'h0;
            if (txt[idx][44 : 47] == 4'h9) begin txt[idx][44 : 47] <= 4'h0;
            if (txt[idx][36 : 39] == 4'h9) begin txt[idx][36 : 39] <= 4'h0;
            if (txt[idx][28 : 31] == 4'h9) begin txt[idx][28 : 31] <= 4'h0;
            if (txt[idx][20 : 23] == 4'h9) begin txt[idx][20 : 23] <= 4'h0;
            if (txt[idx][12 : 15] == 4'h9) begin txt[idx][12 : 15] <= 4'h0;
            if (txt[idx][4 : 7] == 4'h9) begin txt[idx][4 : 7] <= 4'h0;
            end else txt[idx][4 : 7] <= txt[idx][4 : 7] + 1;
            end else txt[idx][12 : 15] <= txt[idx][12 : 15] + 1;
            end else txt[idx][20 : 23] <= txt[idx][20 : 23] + 1;
            end else txt[idx][28 : 31] <= txt[idx][28 : 31] + 1;
            end else txt[idx][36 : 39] <= txt[idx][36 : 39] + 1;
            end else txt[idx][44 : 47] <= txt[idx][44 : 47] + 1;
            end else txt[idx][52 : 55] <= txt[idx][52 : 55] + 1;
            end else txt[idx][60 :63] <= txt[idx][60 :63] + 1; 
    end 
  end
  // Check md5 output
  else if(P == S_MAIN_CHEC) begin
        if (hash0 == passwd_hash) begin done <= 1; ans_reg <= ans0; end
        else if (hash1 == passwd_hash) begin done <= 1; ans_reg <= ans1; end
        else if (hash2 == passwd_hash) begin done <= 1; ans_reg <= ans2; end
        //else if (hash3 == passwd_hash) begin done <= 1; ans_reg <= ans3; end
    end
end       

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge  slow_clk) begin
    if (~reset_n) begin
        row_A <= "reset_n pressed!";
        row_B <= "intialize system";
    end else if(P== S_MAIN_INIT) begin
        row_A <= " Press the BTN3 ";
        row_B <= "   to start!!   ";
    end else if (P == S_MAIN_CHEC) begin
        //row_A <= " crack the code ";
        row_A <= {txt[0], txt[1]};
        row_B <= {txt[2], "T", timer};
        //row_B <= {"Time: ", timer, " ms"};
    end else if (P == S_MAIN_SHOW) begin
        row_A <= {"Passwd: ", ans_reg};
        row_B <= {"Time: ", timer, " ms"};
    end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule