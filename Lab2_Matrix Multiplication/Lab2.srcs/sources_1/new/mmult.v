`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/28 13:00:57
// Design Name: 
// Module Name: mmult
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
module mmult(
    input clk,                  // Clock signal.
    input reset_n,              // Reset signal (negative logic).
    input enable,               // Activation signal for matrix multiplication (tells the circuit that A and B are ready for use).
    input [0:9*8-1] A_mat,      // A matrix.
    input [0:9*8-1] B_mat,      // B matrix.
    output valid,               // Signals that the output is valid to read.
    output reg [0:9*17-1] C_mat // The result of A x B.
    );
    
    integer i, j, stage;
    reg val;
    reg [0:7] A [0:2][0:2];
    reg [0:7] B [0:2][0:2];
    reg [0:17] Res [0:2][0:2]; 
    
    assign valid = val;

    always @(posedge clk or negedge reset_n) begin
       if (!reset_n) begin
          for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
              A[i][j] <= 0;
              B[i][j] <= 0;
              Res[i][j] <= 0;
            end
          end
          C_mat <= 0;
          val <= 0;
        end else begin
            if(enable) begin
               case(stage)
                0: begin    // load data
                     for (i = 0; i < 3; i = i + 1) begin
                      for (j = 0; j < 3; j = j + 1) begin
                        A[i][j] <= A_mat[(i*3 + j)*8 +: 8];
                        B[i][j] <= B_mat[(i*3 + j)*8 +: 8];
                      end
                     end
                    end
                1: begin    // matrix multiplication
                     for (i = 0; i < 3; i = i + 1) begin
                      for (j = 0; j < 3; j = j + 1) begin
                        Res[i][j] <= A[i][0] * B[0][j] + A[i][1] * B[1][j] + A[i][2] * B[2][j];
                      end
                     end
                    end
                2: begin    // output result
                     for (i = 0; i < 3; i = i + 1) begin
                      for (j = 0; j < 3; j = j + 1) begin
                        C_mat[(i*3 + j)*17 +: 17] <= Res[i][j];
                      end
                     end
                    val <= 1;
                    end
                endcase
                if (stage < 2) begin
                    stage <= stage + 1;
                end
            end else begin
               stage = 0;
               val <= 0;
            end
        end
    end  
endmodule






