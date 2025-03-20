`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/02 15:00:26
// Design Name: 
// Module Name: clk_div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_div#(parameter divider = 16)(input clk, input reset, output reg clk_out);

localparam half_divider = divider/2;
localparam divider_minus_one = divider-1;

reg [7:0] counter;

always @(posedge clk)begin
  if (reset)
    clk_out <= 0;
  else
    clk_out <= (counter < half_divider)? 1 : 0;
end

always @(posedge clk)begin
  if (reset)
    counter <= 0;
  else
    counter <= (counter == divider_minus_one)? 0 : counter + 1;
end

endmodule
