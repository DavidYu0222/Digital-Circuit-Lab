`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  /*
  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  */
  //uart
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_READ = 3'b001,
                 S_MAIN_MUL = 3'b010, S_MAIN_SHOW = 3'b011,
                 S_MAIN_WAIT = 3'b100;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam FIRST_STR = 0;  // starting index of the prompt message
localparam FIRST_LEN = 40; // length of the prompt message
localparam SECOND_LEN = 32;
localparam THIRD_LEN = 33;
localparam MEM_SIZE  = FIRST_LEN + 3*SECOND_LEN + THIRD_LEN;

// declare system variables
wire btn_level, btn_pressed;
reg prev_btn_level;
reg  [2:0]  P, P_next;
reg  [11:0] user_addr;


reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;

//declare matrix register
reg read_done = 0;
reg A_OR_B = 0;
reg [5:0] counter = 0;
reg compute_done = 0;
reg [7:0] A [15:0];
reg [7:0] B [15:0];
reg [18:0] tmp [3:0];
reg [18:0] result [15:0]; 

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

reg [1:0] Q, Q_next;
wire print_enable, print_done;
reg [7:0] data[0:MEM_SIZE-1];
reg [$clog2(MEM_SIZE):0] send_counter;
reg  [0:FIRST_LEN*8-1]  msg1 = {"\015\012The matrix multiplication result is:\015\012"};
reg  [0:SECOND_LEN*8-1] msg2 = {"[ 00000, 00000, 00000, 00000 ]\015\012"};
reg  [0:SECOND_LEN*8-1] msg3 = {"[ 00000, 00000, 00000, 00000 ]\015\012"};
reg  [0:SECOND_LEN*8-1] msg4 = {"[ 00000, 00000, 00000, 00000 ]\015\012"};
reg  [0:THIRD_LEN*8-1]  msg5 = {"[ 00000, 00000, 00000, 00000 ]\015\012", 8'h00};

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

/*
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
*/

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level)
);

assign usr_led = 4'h0;

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we(write enable)' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_INIT || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = user_addr[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

integer idx;
integer a, b;
always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_INIT) begin
    for (idx = 0; idx < FIRST_LEN; idx = idx + 1)  data[idx] = msg1[idx*8 +: 8];
    for (idx = 0; idx < SECOND_LEN; idx = idx + 1) data[idx + FIRST_LEN] = msg2[idx*8 +: 8];
    for (idx = 0; idx < SECOND_LEN; idx = idx + 1) data[idx + FIRST_LEN + 1*SECOND_LEN] = msg3[idx*8 +: 8];
    for (idx = 0; idx < SECOND_LEN; idx = idx + 1) data[idx + FIRST_LEN + 2*SECOND_LEN] = msg4[idx*8 +: 8];
    for (idx = 0; idx < THIRD_LEN; idx = idx + 1)  data[idx + FIRST_LEN + 3*SECOND_LEN] = msg5[idx*8 +: 8];
  end
  else if (P == S_MAIN_SHOW) begin
    for(a = 0; a < 4; a = a + 1) begin
        for(b = 0 ; b < 4; b = b + 1)begin
            data[FIRST_LEN + a*SECOND_LEN + 7*b+2] <= "0" + result[4*a + b][17:16];
            data[FIRST_LEN + a*SECOND_LEN + 7*b+3] <= ((result[4*a + b][15:12] > 9)? "7" : "0") + result[4*a + b][15:12];
            data[FIRST_LEN + a*SECOND_LEN + 7*b+4] <= ((result[4*a + b][11: 8] > 9)? "7" : "0") + result[4*a + b][11: 8];
            data[FIRST_LEN + a*SECOND_LEN + 7*b+5] <= ((result[4*a + b][ 7: 4] > 9)? "7" : "0") + result[4*a + b][ 7: 4];
            data[FIRST_LEN + a*SECOND_LEN + 7*b+6] <= ((result[4*a + b][ 3: 0] > 9)? "7" : "0") + result[4*a + b][ 3: 0];
         end
    end
  end
end

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: if (btn_pressed == 1) P_next = S_MAIN_READ;// send an address to the SRAM 
     else P_next = S_MAIN_INIT;
    S_MAIN_READ:  if(read_done) P_next = S_MAIN_MUL;    // fetch the sample from the SRAM
     else P_next = S_MAIN_READ;
    S_MAIN_MUL: if(compute_done) P_next = S_MAIN_SHOW;   
     else P_next = S_MAIN_MUL;
    S_MAIN_SHOW: if(print_done) P_next = S_MAIN_WAIT;
     else P_next = S_MAIN_SHOW;
    S_MAIN_WAIT: P_next = S_MAIN_INIT; 
  endcase
end

//FSM read logic
always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_INIT) begin
     A_OR_B <= 0;
     read_done <= 0;
     counter <= 0;
     user_addr <= 12'h000;
    end
    else if(P == S_MAIN_READ) begin
        case(A_OR_B) 
            1'b0: begin
                user_addr <= user_addr + 1;
                A_OR_B <= 1;
                end
            1'b1: begin
                if(counter < 16) begin
                    A[counter] = data_out;
                    counter = counter + 1;     
                end else if(counter < 32)begin
                    B[counter - 16] = data_out;
                    counter = (counter == 31)? 32:counter + 1;                   
                end else begin
                    read_done <= 1;
                    end
                A_OR_B <= 0;
                end
        endcase
    end
end

integer i, j;
reg state = 0;
always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_INIT) begin
    compute_done <= 0;
    i <= 0;
    j <= 0;
    state <= 0;
  end
  else if(P == S_MAIN_MUL) begin
    case(state)
        0: begin
           tmp[0] <= A[4*i + 0] * B[0 + j];
           tmp[1] <= A[4*i + 1] * B[4 + j];
           tmp[2] <= A[4*i + 2] * B[8 + j];
           tmp[3] <= A[4*i + 3] * B[12 + j];
           state <= 1;
           end
         1: begin
            result[4*i + j] = tmp[0] + tmp[1] + tmp[2] + tmp[3];
            if(i == 3 && j == 3)
                compute_done <= 1;
            else begin
                i = (j == 3) ? i + 1 : i;
                j = (j == 3) ? 0 : j + 1;
                state <= 0;
                end
            end
    endcase
  end
end

// FSM output logics: print string control signals.
assign print_enable = (P != S_MAIN_SHOW && P_next == S_MAIN_SHOW);
assign print_done = (tx_byte == 8'h0);
// End of the main controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT ||
                  (P == S_MAIN_SHOW && received) ||
                   print_enable);
assign tx_byte  = ((P == S_MAIN_SHOW) && received)? 0 : data[send_counter];

// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= FIRST_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
/*
reg LCDstate = 0;
always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "                ";
    row_B <= "                ";
  end
  else if (P == S_MAIN_WAIT) begin
    case(LCDstate)
    0:begin
      row_A[8*16-1: 8*15] <= ((A[0][7:4] > 9)? "7" : "0") + A[0][7:4];
      row_A[8*15-1: 8*14] <= ((A[0][3:0] > 9)? "7" : "0") + A[0][3:0];
      row_A[8*14-1: 8*13] <= ((A[1][7:4] > 9)? "7" : "0") + A[1][7:4];
      row_A[8*13-1: 8*12] <= ((A[1][3:0] > 9)? "7" : "0") + A[1][3:0];
      row_A[8*12-1: 8*11] <= ((A[2][7:4] > 9)? "7" : "0") + A[2][7:4];
      row_A[8*11-1: 8*10] <= ((A[2][3:0] > 9)? "7" : "0") + A[2][3:0];
      row_A[8*10-1: 8*9] <= ((A[3][7:4] > 9)? "7" : "0") + A[3][7:4];
      row_A[8*9-1: 8*8] <= ((A[3][3:0] > 9)? "7" : "0") + A[3][3:0];
      row_A[8*8-1: 8*7] <= ((A[4][7:4] > 9)? "7" : "0") + A[4][7:4];
      row_A[8*7-1: 8*6] <= ((A[4][3:0] > 9)? "7" : "0") + A[4][3:0];
      row_A[8*6-1: 8*5] <= ((A[5][7:4] > 9)? "7" : "0") + A[5][7:4];
      row_A[8*5-1: 8*4] <= ((A[5][3:0] > 9)? "7" : "0") + A[5][3:0];
      row_A[8*4-1: 8*3] <= ((A[6][7:4] > 9)? "7" : "0") + A[6][7:4];
      row_A[8*3-1: 8*2] <= ((A[6][3:0] > 9)? "7" : "0") + A[6][3:0];
      row_A[8*2-1: 8*1] <= ((A[7][7:4] > 9)? "7" : "0") + A[7][7:4];
      row_A[8*1-1: 0] <= ((A[7][3:0] > 9)? "7" : "0") + A[7][3:0];
      row_B[8*16-1: 8*15] <= ((A[8][7:4] > 9)? "7" : "0") + A[8][7:4];
      row_B[8*15-1: 8*14] <= ((A[8][3:0] > 9)? "7" : "0") + A[8][3:0];
      row_B[8*14-1: 8*13] <= ((A[9][7:4] > 9)? "7" : "0") + A[9][7:4];
      row_B[8*13-1: 8*12] <= ((A[9][3:0] > 9)? "7" : "0") + A[9][3:0];
      row_B[8*12-1: 8*11] <= ((A[10][7:4] > 9)? "7" : "0") + A[10][7:4];
      row_B[8*11-1: 8*10] <= ((A[10][3:0] > 9)? "7" : "0") + A[10][3:0];
      row_B[8*10-1: 8*9] <= ((A[11][7:4] > 9)? "7" : "0") + A[11][7:4];
      row_B[8*9-1: 8*8] <= ((A[11][3:0] > 9)? "7" : "0") + A[11][3:0];
      row_B[8*8-1: 8*7] <= ((A[12][7:4] > 9)? "7" : "0") + A[12][7:4];
      row_B[8*7-1: 8*6] <= ((A[12][3:0] > 9)? "7" : "0") + A[12][3:0];
      row_B[8*6-1: 8*5] <= ((A[13][7:4] > 9)? "7" : "0") + A[13][7:4];
      row_B[8*5-1: 8*4] <= ((A[13][3:0] > 9)? "7" : "0") + A[13][3:0];
      row_B[8*4-1: 8*3] <= ((A[14][7:4] > 9)? "7" : "0") + A[14][7:4];
      row_B[8*3-1: 8*2] <= ((A[14][3:0] > 9)? "7" : "0") + A[14][3:0];
      row_B[8*2-1: 8*1] <= ((A[15][7:4] > 9)? "7" : "0") + A[15][7:4];
      row_B[8*1-1: 0] <= ((A[15][3:0] > 9)? "7" : "0") + A[15][3:0];
      end
    1:begin
      row_A[8*16-1: 8*15] <= ((B[0][7:4] > 9)? "7" : "0") + B[0][7:4];
      row_A[8*15-1: 8*14] <= ((B[0][3:0] > 9)? "7" : "0") + B[0][3:0];
      row_A[8*14-1: 8*13] <= ((B[1][7:4] > 9)? "7" : "0") + B[1][7:4];
      row_A[8*13-1: 8*12] <= ((B[1][3:0] > 9)? "7" : "0") + B[1][3:0];
      row_A[8*12-1: 8*11] <= ((B[2][7:4] > 9)? "7" : "0") + B[2][7:4];
      row_A[8*11-1: 8*10] <= ((B[2][3:0] > 9)? "7" : "0") + B[2][3:0];
      row_A[8*10-1: 8*9] <= ((B[3][7:4] > 9)? "7" : "0") + B[3][7:4];
      row_A[8*9-1: 8*8] <= ((B[3][3:0] > 9)? "7" : "0") + B[3][3:0];
      row_A[8*8-1: 8*7] <= ((B[4][7:4] > 9)? "7" : "0") + B[4][7:4];
      row_A[8*7-1: 8*6] <= ((B[4][3:0] > 9)? "7" : "0") + B[4][3:0];
      row_A[8*6-1: 8*5] <= ((B[5][7:4] > 9)? "7" : "0") + B[5][7:4];
      row_A[8*5-1: 8*4] <= ((B[5][3:0] > 9)? "7" : "0") + B[5][3:0];
      row_A[8*4-1: 8*3] <= ((B[6][7:4] > 9)? "7" : "0") + B[6][7:4];
      row_A[8*3-1: 8*2] <= ((B[6][3:0] > 9)? "7" : "0") + B[6][3:0];
      row_A[8*2-1: 8*1] <= ((B[7][7:4] > 9)? "7" : "0") + B[7][7:4];
      row_A[8*1-1: 0] <= ((B[7][3:0] > 9)? "7" : "0") + B[7][3:0];
      row_B[8*16-1: 8*15] <= ((B[8][7:4] > 9)? "7" : "0") + B[8][7:4];
      row_B[8*15-1: 8*14] <= ((B[8][3:0] > 9)? "7" : "0") + B[8][3:0];
      row_B[8*14-1: 8*13] <= ((B[9][7:4] > 9)? "7" : "0") + B[9][7:4];
      row_B[8*13-1: 8*12] <= ((B[9][3:0] > 9)? "7" : "0") + B[9][3:0];
      row_B[8*12-1: 8*11] <= ((B[10][7:4] > 9)? "7" : "0") + B[10][7:4];
      row_B[8*11-1: 8*10] <= ((B[10][3:0] > 9)? "7" : "0") + B[10][3:0];
      row_B[8*10-1: 8*9] <= ((B[11][7:4] > 9)? "7" : "0") + B[11][7:4];
      row_B[8*9-1: 8*8] <= ((B[11][3:0] > 9)? "7" : "0") + B[11][3:0];
      row_B[8*8-1: 8*7] <= ((B[12][7:4] > 9)? "7" : "0") + B[12][7:4];
      row_B[8*7-1: 8*6] <= ((B[12][3:0] > 9)? "7" : "0") + B[12][3:0];
      row_B[8*6-1: 8*5] <= ((B[13][7:4] > 9)? "7" : "0") + B[13][7:4];
      row_B[8*5-1: 8*4] <= ((B[13][3:0] > 9)? "7" : "0") + B[13][3:0];
      row_B[8*4-1: 8*3] <= ((B[14][7:4] > 9)? "7" : "0") + B[14][7:4];
      row_B[8*3-1: 8*2] <= ((B[14][3:0] > 9)? "7" : "0") + B[14][3:0];
      row_B[8*2-1: 8*1] <= ((B[15][7:4] > 9)? "7" : "0") + B[15][7:4];
      row_B[8*1-1: 0] <= ((B[15][3:0] > 9)? "7" : "0") + B[15][3:0];
      end
    endcase
  end
end
reg [31:0] c = 0;
always @(posedge clk) begin
    if(~reset_n)
        LCDstate <= 0;
    else if(c > 25000000)
        LCDstate <= ~LCDstate;
end

always @(posedge clk) begin
    if(~reset_n)
        c <= 0;
    else 
        c <= (c >= 50000000) ? 0 : c + 1;
end
*/
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------


endmodule
