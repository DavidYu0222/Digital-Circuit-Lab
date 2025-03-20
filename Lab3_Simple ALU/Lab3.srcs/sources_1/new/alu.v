`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/13 18:55:28
// Design Name: 
// Module Name: alu
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


module alu(
    input [2:0] opcode,
    input [7:0] data,
    input [7:0] accum,
    input clk,
    input reset,
    output reg [7:0] alu_out,
    output reg zero
    );
    
    always @(posedge clk or posedge reset)begin
        if(reset)begin
            alu_out <= 0;
            zero <= 1;
        end else begin
            if(accum != 0)begin
                zero <= 0;
            end
            case(opcode)
                3'b000: begin   //Pass accum
                    alu_out <= accum;
                end
                3'b001: begin   //accum + data
                    alu_out <= accum + data;                  
                end
                3'b010: begin   //accum - data
                    alu_out <= accum - data;
                end
                3'b011: begin   //accum AND data
                    alu_out <= accum & data;
                end
                3'b100: begin   //accum XOR data
                    alu_out <= accum ^ data;
                end
                3'b101: begin   //ABS(accum)
                    alu_out <= (accum[7] == 1'b1)? ~accum + 1 : accum;
                end
                3'b110: begin   //MUL
                    alu_out <= $signed(accum[3:0]) * $signed(data[3:0]);
                end
                3'b111: begin   //Pass data
                    alu_out <= data;
                end
                default: begin
                    alu_out <= 0;
                end
            endcase
        end
    end
endmodule







