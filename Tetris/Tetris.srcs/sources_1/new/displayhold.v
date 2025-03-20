`timescale 1ns / 1ps

module displayhold(
    input clk,
    input [2:0] hold,
    output reg [0:23]board
    );
    
always @(posedge clk) begin
    case(hold)
    `LBLUE: begin //I BLOCK
            board <= {`LBLUE, `LBLUE, `LBLUE, `LBLUE,
                      `NULL, `NULL, `NULL, `NULL};
            end
    `YELLOW: begin //O BLOCK
            board <= {`NULL, `YELLOW, `YELLOW, `NULL,
                      `NULL ,`YELLOW, `YELLOW, `NULL};         
            end
    `PURPLE: begin //T BLOCK
            board <= {`NULL, `PURPLE,`NULL, `NULL, 
                      `PURPLE, `PURPLE, `PURPLE, `NULL};
            end
    `GREEN: begin //S BLOCK
            board <= {`NULL, `GREEN, `GREEN, `NULL, 
                      `GREEN, `GREEN, `NULL, `NULL};      
            end
    `RED: begin //Z BLOCK
            board <= {`RED, `RED, `NULL, `NULL, 
                      `NULL, `RED, `RED, `NULL};    
            end
    `DBLUE: begin //J BLOCK
            board <= {`DBLUE, `NULL, `NULL, `NULL, 
                      `DBLUE, `DBLUE, `DBLUE, `NULL};   
            end
    `ORANGE: begin //L BLOCK
            board <= {`NULL, `NULL, `ORANGE, `NULL, 
                      `ORANGE, `ORANGE, `ORANGE, `NULL};   
            end
    default: begin
            board <= 0;
            end
    endcase    


end

    
    
endmodule
