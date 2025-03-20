`timescale 1ns / 1ps

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] fish1_clock, fish2_clock, fish3_clock;
wire [9:0]  pos1, pos2, vpos2;
wire        fish1_region, fish2_region, fish3_region;

// declare SRAM control signals
wire [16:0] sram_addr_background, sram_addr_fish1, sram_addr_fish2, sram_addr_fish3;
wire [11:0] data_in;
wire [11:0] data_out_background, data_out_fish1, data_out_fish2, data_out_fish3;
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
reg  [17:0] pixel_addr_background, pixel_addr_fish1, pixel_addr_fish2, pixel_addr_fish3;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images

localparam FISH1_VPOS = 88;  // Vertical location of the fish in the sea image.
localparam FISH2_VPOS = 100; // Vertical location of the fish in the sea image.
localparam FISH3_VPOS = 128; // Vertical location of the fish in the sea image.
localparam FISH_W     = 64;   // Width of the fish.
localparam FISH_H1    = 32;  // Height of the fish.
localparam FISH_H2    = 44;  // Height of the fish.
localparam FISH_H3    = 72;  // Height of the fish.£»

reg [17:0] fish1_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish2_addr[0:8];
reg [17:0] fish3_addr[0:8];
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(

wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  state = 1; 

initial begin
  fish1_addr[0] = 18'b0;
  fish1_addr[1] = FISH_W*FISH_H1;
  fish1_addr[2] = FISH_W*FISH_H1*2;
  fish1_addr[3] = FISH_W*FISH_H1*3;
  fish1_addr[4] = FISH_W*FISH_H1*4;
  fish1_addr[5] = FISH_W*FISH_H1*5;
  fish1_addr[6] = FISH_W*FISH_H1*6;

  fish2_addr[0] = 18'b0;
  fish2_addr[1] = FISH_W*FISH_H2;
  fish2_addr[2] = FISH_W*FISH_H2*2;
  fish2_addr[3] = FISH_W*FISH_H2*3;
  fish2_addr[4] = FISH_W*FISH_H2*4;
  fish2_addr[5] = FISH_W*FISH_H2*5;
  fish2_addr[6] = FISH_W*FISH_H2*6;
  /*
  fish3_addr[0] = 18'b0;
  fish3_addr[1] = FISH_W*FISH_H3;
  fish3_addr[2] = FISH_W*FISH_H3*2;
  fish3_addr[3] = FISH_W*FISH_H3*3;
  fish3_addr[4] = FISH_W*FISH_H3*4;
  fish3_addr[5] = FISH_W*FISH_H3*5;
  fish3_addr[6] = FISH_W*FISH_H3*6;
  */
end
// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level)
);

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

always @(posedge clk) begin
  if (~reset_n)
    state <= 1;
  else if (btn_pressed)
    state <= !state;
end

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H), .FILE("images1.mem"))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_background), .data_i(data_in), .data_o(data_out_background));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(7*FISH_W*FISH_H1), .FILE("images2.mem"))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_fish1), .data_i(data_in), .data_o(data_out_fish1));
        
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(7*FISH_W*FISH_H2), .FILE("images3.mem"))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_fish2), .data_i(data_in), .data_o(data_out_fish2));
/*    
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(7*FISH_W*FISH_H3), .FILE("images4.mem"))
  ram4 (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr_fish3), .data_i(data_in), .data_o(data_out_fish3));
*/
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr_background  = pixel_addr_background;
assign sram_addr_fish1 = pixel_addr_fish1;
assign sram_addr_fish2 = pixel_addr_fish2;
assign sram_addr_fish3 = pixel_addr_fish3;
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
assign pos1 = fish1_clock[30:20]; // the x position of the right edge of the fish image
                             // in the 640x480 VGA screen
assign pos2 = fish2_clock[29:19];

assign vpos2 = FISH2_VPOS + (fish1_clock[27:24]*fish1_clock[27:24])/20;

always @(posedge clk) begin
  if (~reset_n) begin
    fish1_clock <= 0;
    fish2_clock <= 0;
    fish3_clock <= 0;
  end
  else begin
    if(fish1_clock[31:21] > VBUF_W + FISH_W)
        fish1_clock <= 0;
    else
        fish1_clock <= fish1_clock + ((state) ? 1 : 2);
        
    if(fish2_clock[30:20] > VBUF_W + FISH_W)
        fish2_clock <= 0;
    else
        fish2_clock <= fish2_clock + ((state)? 1 : 2);
    /*        
    if(fish3_clock[31:21] > VBUF_W + FISH_W)
        fish3_clock <= 0;
    else
        fish3_clock <= fish3_clock + 1;
    */
  end
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish1_region = pixel_y >= (FISH1_VPOS<<1) &&
                     pixel_y < (FISH1_VPOS+FISH_H1)<<1 &&
                    (pixel_x + 127) >= pos1 &&
                     pixel_x < pos1 + 1;

assign fish2_region = pixel_y >= (vpos2<<1) &&
                     pixel_y < (vpos2+FISH_H2)<<1 &&
                    (pixel_x + 127) >= pos2 &&
                     pixel_x < pos2 + 1;
/*
assign fish3_region = pixel_y >= (FISH3_VPOS<<1) &&
                     pixel_y < (FISH3_VPOS+FISH_H3)<<1 &&
                    (pixel_x + 127) >= pos3 &&
                     pixel_x < pos3 + 1;
*/
//control read address
always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr_background <= 0;
    pixel_addr_fish1 <= 0;
    pixel_addr_fish2 <= 0;
    //pixel_addr_fish3 <= 0;
  end
  else begin 
    pixel_addr_background <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    
    if (fish1_region)
        pixel_addr_fish1 <= fish1_addr[fish1_clock[25:23]] +
                    ((pixel_y>>1)-FISH1_VPOS)*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos1)>>1);
    else pixel_addr_fish1 <= fish1_addr[0];      //set it to green color (fish1_addr[0] is green)
    
    if (fish2_region)
        pixel_addr_fish2 <= fish2_addr[fish2_clock[25:23]] +
                    ((pixel_y>>1)-vpos2)*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos2)>>1);
    else pixel_addr_fish2 <= fish2_addr[0];      //set it to green color (fish2_addr[0] is green)
    /*
    if (fish3_region)
        pixel_addr_fish3 <= fish3_addr[fish3_clock[23]] +
                    ((pixel_y>>1)-FISH3_VPOS)*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos3)>>1);
    else pixel_addr_fish3 <= fish3_addr[0];      //set it to green color (fish3_addr[0] is green)
    */
    end
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
  else if (data_out_fish1 != 12'h0F0)   //is green or not
    rgb_next = data_out_fish1; // RGB value at (pixel_x, pixel_y)
  else if (data_out_fish2 != 12'h0F0)
    rgb_next = data_out_fish2;
  //else if (data_out_fish3 != 12'h0F0)
  //  rgb_next <= data_out_fish3;
  else
    rgb_next = data_out_background;
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
