`timescale 1ns / 1ps

module displayboard( 
    input clk,
    input enable,
    input  [0:(`ROWS * `COLS * 3)-1] board,
    input wire [2:0] current,
    input wire [7:0] blk_1,
    input wire [7:0] blk_2,
    input wire [7:0] blk_3,
    input wire [7:0] blk_4,
    output reg [0:(`ROWS * `COLS * 3)-1] d_board
    );
    
always @(clk) begin
    d_board = board;
    if(enable) begin
        d_board[3*blk_1 +: 3] = current;
        d_board[3*blk_2 +: 3] = current;
        d_board[3*blk_3 +: 3] = current;
        d_board[3*blk_4 +: 3] = current;
    end
end
    
endmodule
