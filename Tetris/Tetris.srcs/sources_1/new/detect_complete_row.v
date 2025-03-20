`timescale 1ns / 1ps

`include "define.vh"

module detect_complete_row(
    input clk,
    input enable,
    input  [0:(`ROWS * `COLS * 3)-1] board,
    output wire [7:0] remove_row,
    output wire remove_en
    );
    
    reg [7:0] row;
    
    initial begin
        row <= 0;
    end
    
    assign remove_en = !((board[3*(row*`COLS)   +: 3] == 3'b000) || (board[3*(row*`COLS+1) +: 3] == 3'b000) || (board[3*(row*`COLS+2) +: 3] == 3'b000)
                      || (board[3*(row*`COLS+3) +: 3] == 3'b000) || (board[3*(row*`COLS+4) +: 3] == 3'b000) || (board[3*(row*`COLS+5) +: 3] == 3'b000)
                      || (board[3*(row*`COLS+6) +: 3] == 3'b000) || (board[3*(row*`COLS+7) +: 3] == 3'b000) || (board[3*(row*`COLS+8) +: 3] == 3'b000)
                      || (board[3*(row*`COLS+9) +: 3] == 3'b000));
                    
    assign remove_row = row;

    always @ (posedge clk) begin
        if(enable) begin
            if(row == `ROWS - 1)
                row <= 0;
            else
                row <= row + 1;
        end
    end
endmodule
