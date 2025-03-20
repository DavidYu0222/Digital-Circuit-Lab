`timescale 1ns / 1ps

`include "define.vh"

module display(
    input  clk,
    input  reset_n,
    input  [3:0] usr_sw,
    input  [0:(`ROWS * `COLS * 3)-1]board,
    input  [0:23] h_board,
    input  [0:23] n1_board,
    input  [0:23] n2_board,
    input  [0:23] n3_board,
    input  [0:23] n4_board,
    input  enable,      
    input  [9:0] score,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
wire [7:0] which_block;
wire [7:0] which_hold;
wire [7:0] which_n1;
wire [7:0] which_n2;
wire [7:0] which_n3;
wire [7:0] which_n4;
wire is_block;
wire is_hold;
wire is_n1;
wire is_n2;
wire is_n3;
wire is_n4;

// declare SRAM control signals
wire [16:0] sram_addr;
wire [10:0] sram1_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;

wire digit_data;
wire in_digit0, in_digit1, in_digit2;
wire [0:10] digit_pos;


// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam BLOCK_VPOS   = 11; 
localparam BLOCK_HPOS   = 91;
localparam BLOCK_SIZE   = 10;
localparam BLOCK_INVL   = 1 ;

//////////////////////////////////revise here
/*
integer index;
reg [2:0] board [199:0];
initial begin
    for( index = 0 ; index < 200 ; index = index + 1)
        board [index] = index % 7 + 1;
end
*/
/////////////////////////////////////////////

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_div#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H), .FILE("images.mem"))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
sram #(.DATA_WIDTH(1), .ADDR_WIDTH(11), .RAM_SIZE(1530), .FILE("number_table.mem"))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(digit_pos), .data_i(data_in), .data_o(digit_data));

assign sram_we = usr_sw[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec

assign is_hold     = pixel_x < (( 20 + (BLOCK_SIZE + BLOCK_INVL)*4 )<<1) && pixel_x >= ( 20 <<1 ) &&
                     pixel_y < (( 40 + (BLOCK_SIZE + BLOCK_INVL)*2 )<<1) && pixel_y >= ( 40 <<1 ) &&
                     (( pixel_x >> 1 ) - 20) % (BLOCK_SIZE + BLOCK_INVL) != 10 && 
                     (( pixel_y >> 1 ) - 40) % (BLOCK_SIZE + BLOCK_INVL) != 10 ;

assign which_hold  = (~is_hold) ? 0 :  ((( pixel_x >> 1 ) - 20) / (BLOCK_SIZE + BLOCK_INVL)) +
                                       ((( pixel_y >> 1 ) - 40) / (BLOCK_SIZE + BLOCK_INVL)) * 4;

assign is_n1       = pixel_x < (( 230 + (BLOCK_SIZE + BLOCK_INVL)*4 )<<1) && pixel_x >= ( 230 <<1 ) &&
                     pixel_y < (( 40 + (BLOCK_SIZE + BLOCK_INVL)*2 )<<1) && pixel_y >= ( 40 <<1 ) &&
                     (( pixel_x >> 1 ) - 230) % (BLOCK_SIZE + BLOCK_INVL) != 10 && 
                     (( pixel_y >> 1 ) - 40) % (BLOCK_SIZE + BLOCK_INVL) != 10 ;

assign which_n1    = (~is_n1) ? 0 :  ((( pixel_x >> 1 ) - 230) / (BLOCK_SIZE + BLOCK_INVL)) +
                                     ((( pixel_y >> 1 ) - 40) / (BLOCK_SIZE + BLOCK_INVL)) * 4;

assign is_n2       = pixel_x < (( 230 + (BLOCK_SIZE + BLOCK_INVL)*4 )<<1) && pixel_x >= ( 230 <<1 ) &&
                     pixel_y < (( 70 + (BLOCK_SIZE + BLOCK_INVL)*2 )<<1) && pixel_y >= ( 70 <<1 ) &&
                     (( pixel_x >> 1 ) - 230) % (BLOCK_SIZE + BLOCK_INVL) != 10 && 
                     (( pixel_y >> 1 ) - 70) % (BLOCK_SIZE + BLOCK_INVL) != 10 ;

assign which_n2    = (~is_n2) ? 0 :  ((( pixel_x >> 1 ) - 230) / (BLOCK_SIZE + BLOCK_INVL)) +
                                     ((( pixel_y >> 1 ) - 70) / (BLOCK_SIZE + BLOCK_INVL)) * 4;

assign is_n3       = pixel_x < (( 230 + (BLOCK_SIZE + BLOCK_INVL)*4 )<<1) && pixel_x >= ( 230 <<1 ) &&
                     pixel_y < (( 100 + (BLOCK_SIZE + BLOCK_INVL)*2 )<<1) && pixel_y >= ( 100 <<1 ) &&
                     (( pixel_x >> 1 ) - 230) % (BLOCK_SIZE + BLOCK_INVL) != 10 && 
                     (( pixel_y >> 1 ) - 100) % (BLOCK_SIZE + BLOCK_INVL) != 10 ;

assign which_n3    = (~is_n3) ? 0 :  ((( pixel_x >> 1 ) - 230) / (BLOCK_SIZE + BLOCK_INVL)) +
                                     ((( pixel_y >> 1 ) - 100) / (BLOCK_SIZE + BLOCK_INVL)) * 4;
                                     
assign is_n4       = pixel_x < (( 230 + (BLOCK_SIZE + BLOCK_INVL)*4 )<<1) && pixel_x >= ( 230 <<1 ) &&
                     pixel_y < (( 130 + (BLOCK_SIZE + BLOCK_INVL)*2 )<<1) && pixel_y >= ( 130 <<1 ) &&
                     (( pixel_x >> 1 ) - 230) % (BLOCK_SIZE + BLOCK_INVL) != 10 && 
                     (( pixel_y >> 1 ) - 130) % (BLOCK_SIZE + BLOCK_INVL) != 10 ;

assign which_n4    = (~is_n4) ? 0 :  ((( pixel_x >> 1 ) - 230) / (BLOCK_SIZE + BLOCK_INVL)) +
                                     ((( pixel_y >> 1 ) - 130) / (BLOCK_SIZE + BLOCK_INVL)) * 4;                                                                        

assign is_block    = pixel_x < (( BLOCK_HPOS + (BLOCK_SIZE + BLOCK_INVL)*10 )<<1) && pixel_x >= ( BLOCK_HPOS <<1 ) &&
                     pixel_y < (( BLOCK_VPOS + (BLOCK_SIZE + BLOCK_INVL)*20 )<<1) && pixel_y >= ( BLOCK_VPOS <<1 ) &&
                     (( pixel_x >> 1 ) - BLOCK_HPOS) % (BLOCK_SIZE + BLOCK_INVL) != 10 && 
                     (( pixel_y >> 1 ) - BLOCK_VPOS) % (BLOCK_SIZE + BLOCK_INVL) != 10 ;

assign which_block = (~is_block) ? 0 :  ((( pixel_x >> 1 ) - BLOCK_HPOS) / (BLOCK_SIZE + BLOCK_INVL)) +
                                        ((( pixel_y >> 1 ) - BLOCK_VPOS) / (BLOCK_SIZE + BLOCK_INVL)) * 10 ;

assign in_digit2 = (pixel_x>>1) < 239 && (pixel_x>>1) >= 230 && (pixel_y>>1) < 207 && (pixel_y>>1) >= 190;
assign in_digit1 = (pixel_x>>1) < 250 && (pixel_x>>1) >= 241 && (pixel_y>>1) < 207 && (pixel_y>>1) >= 190;
assign in_digit0 = (pixel_x>>1) < 261 && (pixel_x>>1) >= 252 && (pixel_y>>1) < 207 && (pixel_y>>1) >= 190;

assign digit_pos =  (in_digit2) ? ( ((pixel_x>>1)-230) + (((pixel_y>>1)-190)*9) + (score/100)*153 ) :
                    (in_digit1) ? ( ((pixel_x>>1)-241) + (((pixel_y>>1)-190)*9) + ((score/10)%10)*153 ) :
                    (in_digit0) ? ( ((pixel_x>>1)-252) + (((pixel_y>>1)-190)*9) + (score%10)*153 ) :
                    0;

// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr <= 0;
  else
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(is_block && enable) begin
    case(board[3*which_block +: 3])
      1: rgb_next = 12'hf00;//red
      2: rgb_next = 12'h9dd;//
      3: rgb_next = 12'h39c;
      4: rgb_next = 12'hfe0;
      5: rgb_next = 12'hc8c;
      6: rgb_next = 12'h7a7;//green
      7: rgb_next = 12'hfb0;
      default: rgb_next = data_out;
    endcase
  end
  else if(is_hold && enable) begin
    case(h_board[3*which_hold +: 3])
      1: rgb_next = 12'hf00;//red
      2: rgb_next = 12'h9dd;//
      3: rgb_next = 12'h39c;
      4: rgb_next = 12'hfe0;
      5: rgb_next = 12'hc8c;
      6: rgb_next = 12'h7a7;//green
      7: rgb_next = 12'hfb0;
      default: rgb_next = data_out;
    endcase
  end 
  else if(is_n1 && enable) begin
    case(n1_board[3*which_n1 +: 3])
      1: rgb_next = 12'hf00;//red
      2: rgb_next = 12'h9dd;//
      3: rgb_next = 12'h39c;
      4: rgb_next = 12'hfe0;
      5: rgb_next = 12'hc8c;
      6: rgb_next = 12'h7a7;//green
      7: rgb_next = 12'hfb0;
      default: rgb_next = data_out;
    endcase
  end 
  else if(is_n2 && enable) begin
    case(n2_board[3*which_n2 +: 3])
      1: rgb_next = 12'hf00;//red
      2: rgb_next = 12'h9dd;//
      3: rgb_next = 12'h39c;
      4: rgb_next = 12'hfe0;
      5: rgb_next = 12'hc8c;
      6: rgb_next = 12'h7a7;//green
      7: rgb_next = 12'hfb0;
      default: rgb_next = data_out;
    endcase
  end 
  else if(is_n3 && enable) begin
    case(n3_board[3*which_n3 +: 3])
      1: rgb_next = 12'hf00;//red
      2: rgb_next = 12'h9dd;//
      3: rgb_next = 12'h39c;
      4: rgb_next = 12'hfe0;
      5: rgb_next = 12'hc8c;
      6: rgb_next = 12'h7a7;//green
      7: rgb_next = 12'hfb0;
      default: rgb_next = data_out;
    endcase
  end 
  else if(is_n4 && enable) begin
    case(n4_board[3*which_n4 +: 3])
      1: rgb_next = 12'hf00;//red
      2: rgb_next = 12'h9dd;//
      3: rgb_next = 12'h39c;
      4: rgb_next = 12'hfe0;
      5: rgb_next = 12'hc8c;
      6: rgb_next = 12'h7a7;//green
      7: rgb_next = 12'hfb0;
      default: rgb_next = data_out;
    endcase
  end
  else if ( (in_digit2 || in_digit1 || in_digit0) && digit_data==1)
    rgb_next = 12'hfff;
  else
    rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
