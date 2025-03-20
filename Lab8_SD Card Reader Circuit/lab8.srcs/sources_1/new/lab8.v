`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions:
// Description: The sample top module of lab 6: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_INIT = 3'b000,  S_MAIN_IDLE = 3'b001,
                 S_MAIN_WAIT = 3'b010,  S_MAIN_FIND = 3'b011,
                 S_MAIN_READ = 3'b100,  S_MAIN_SHOW = 3'b101;

// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [5:0] send_counter;
reg  [2:0] P, P_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  find_flag; // Signals the completion of reading one SD sector.
reg  [8*8-1:0] Register;
reg  [15:0] ans_cnt;
reg [8:0] counter;

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
assign usr_led = 4'h00;

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
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

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
  end
  else 
    P <= P_next;
end

always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_INIT) begin
         find_flag <= 0;
    end
    else begin
        if (P == S_MAIN_FIND && Register == "DLAB_TAG")
            find_flag <= 1;
        else
            find_flag <= find_flag;
    end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT: // issue a rd_req to the SD controller until it's ready
      if(~find_flag) P_next = S_MAIN_FIND;
      else P_next = S_MAIN_READ;
    S_MAIN_FIND: // find "DLAB_TAG"
      if (Register == "DLAB_TAG") P_next = S_MAIN_READ; //find target
      else if (sd_counter == 512) P_next = S_MAIN_WAIT; //scan done, go to next block
      else P_next = S_MAIN_FIND;
    S_MAIN_READ: //read until "DLAB_END"
      if (Register == "DLAB_END") P_next = S_MAIN_SHOW; //end read
      else if (sd_counter == 512) P_next = S_MAIN_WAIT; //read block done, go to next block
      else P_next = S_MAIN_READ;
    S_MAIN_SHOW:
      if (btn_pressed == 1) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P == S_MAIN_WAIT);
  rd_addr = blk_addr;
end

always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_IDLE) 
    blk_addr <= 32'h2000;
  else if (P == S_MAIN_WAIT) 
    blk_addr <= blk_addr + 1;      // In lab 8, change this line to scan all blocks
end

// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_WAIT)
    sd_counter <= 0;
  else if ((P == S_MAIN_FIND || P == S_MAIN_READ) && sd_valid)
    sd_counter <= sd_counter + 1;
end

always @(posedge clk) begin
  if (~reset_n || P == S_MAIN_IDLE)
    Register <= 64'h0;
  else if ((P == S_MAIN_FIND || P == S_MAIN_READ) && sd_valid)
    Register <= {Register[7*8-1:0], sd_dout};
end

always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_IDLE) begin
        ans_cnt <= 0;
        counter <= 0;
    end
    else if (P == S_MAIN_READ && sd_valid) begin
        if (!("a" <= (Register[7:0]|8'h20) && (Register[7:0]|8'h20) <= "z"))begin   // |8'h20 all word transfer to lowercase
            if(counter == 3) ans_cnt <= ans_cnt + 1; 
            counter <= 0;
        end
        else
            counter <= counter + 1;
    end
end
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
    if (~reset_n) begin
        row_A <= "SD card cannot  ";
        row_B <= "be initialized! ";
    end else if (P == S_MAIN_IDLE) begin
        row_A <= " Press BTN_2 to ";
        row_B <= " read SD card ..";
    end else if (P == S_MAIN_FIND) begin
        row_A <= "Find  \022DLAB_TAG\022";
        row_B <= {" Scan at 0x",
                 ((blk_addr[15:12] > 9) ? "7" : "0") + blk_addr[15:12],
                 ((blk_addr[11: 8] > 9) ? "7" : "0") + blk_addr[11: 8],
                 ((blk_addr[ 7: 4] > 9) ? "7" : "0") + blk_addr[ 7: 4],
                 ((blk_addr[ 3: 0] > 9) ? "7" : "0") + blk_addr[ 3: 0],
                 " "};
    end else if (P == S_MAIN_SHOW) begin
        row_A <= {"Found ",
                 ((ans_cnt[15:12] > 9)? "7" : "0") + ans_cnt[15:12],
                 ((ans_cnt[11: 8] > 9)? "7" : "0") + ans_cnt[11: 8],
                 ((ans_cnt[ 7: 4] > 9)? "7" : "0") + ans_cnt[ 7: 4],
                 ((ans_cnt[ 3: 0] > 9)? "7" : "0") + ans_cnt[ 3: 0],
                  " words"};
        row_B <= "in the text file";
    end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule