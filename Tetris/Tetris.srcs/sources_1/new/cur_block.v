`include "define.vh"

module cur_block(
    input wire [2:0] current,
    input wire [3:0] pos_x,
    input wire [4:0] pos_y,
    input wire [1:0] rot,
    output reg [7:0] blk_1,
    output reg [7:0] blk_2,
    output reg [7:0] blk_3,
    output reg [7:0] blk_4,
    output reg [2:0] width,
    output reg [2:0] height
    );
    
    //(pos_x, pos_y) is the left top of piece
always @ (*) begin
    case (current)
        `LBLUE: begin //I BLOCK
             if (rot == 1 || rot == 3) begin
                 blk_1 <= (pos_y * `COLS) + pos_x;
                 blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                 blk_3 <= ((pos_y + 2) * `COLS) + pos_x;
                 blk_4 <= ((pos_y + 3) * `COLS) + pos_x;
                 width <= 1;
                 height <= 4;
             end else begin
                 blk_1 <= (pos_y * `COLS) + pos_x;
                 blk_2 <= (pos_y * `COLS) + pos_x + 1;
                 blk_3 <= (pos_y * `COLS) + pos_x + 2;
                 blk_4 <= (pos_y * `COLS) + pos_x + 3;
                 width <= 4;
                 height <= 1;
             end
        end
        `YELLOW: begin //O BLOCK
            blk_1 <= (pos_y * `COLS) + pos_x;
            blk_2 <= (pos_y * `COLS) + pos_x + 1;
            blk_3 <= ((pos_y + 1) * `COLS) + pos_x;
            blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 1;
            width <= 2;
            height <= 2;
        end
        `PURPLE: begin //T BLOCK
            case (rot)
                0: begin
                    blk_1 <= (pos_y * `COLS) + pos_x + 1;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                    blk_3 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 2;
                    width <= 3;
                    height <= 2;
                end
                1: begin
                    blk_1 <= (pos_y * `COLS) + pos_x;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                    blk_3 <= ((pos_y + 2) * `COLS) + pos_x;
                    blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    width <= 2;
                    height <= 3;
                end
                2: begin
                    blk_1 <= (pos_y * `COLS) + pos_x;
                    blk_2 <= (pos_y * `COLS) + pos_x + 1;
                    blk_3 <= (pos_y * `COLS) + pos_x + 2;
                    blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    width <= 3;
                    height <= 2;
                end
                3: begin
                    blk_1 <= (pos_y * `COLS) + pos_x + 1;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    blk_3 <= ((pos_y + 2) * `COLS) + pos_x + 1;
                    blk_4 <= ((pos_y + 1) * `COLS) + pos_x;
                    width <= 2;
                    height <= 3;
                end
            endcase
        end
        `GREEN: begin //S BLOCK
            if (rot == 0 || rot == 2) begin
                blk_1 <= (pos_y * `COLS) + pos_x + 1;
                blk_2 <= (pos_y * `COLS) + pos_x + 2;
                blk_3 <= ((pos_y + 1) * `COLS) + pos_x;
                blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                width <= 3;
                height <= 2;
            end else begin
                blk_1 <= (pos_y * `COLS) + pos_x;
                blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                blk_3 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                blk_4 <= ((pos_y + 2) * `COLS) + pos_x + 1;
                width <= 2;
                height <= 3;
            end
        end
        `RED: begin //Z BLOCK
            if (rot == 0 || rot == 2) begin
                blk_1 <= (pos_y * `COLS) + pos_x;
                blk_2 <= (pos_y * `COLS) + pos_x + 1;
                blk_3 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 2;
                width <= 3;
                height <= 2;
            end else begin
                blk_1 <= (pos_y * `COLS) + pos_x + 1;
                blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                blk_3 <= ((pos_y + 2) * `COLS) + pos_x;
                blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                width <= 2;
                height <= 3;
            end
        end
        `DBLUE: begin //J BLOCK
            case (rot)
                0: begin
                    blk_1 <= (pos_y * `COLS) + pos_x;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                    blk_3 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 2;
                    width <= 3;
                    height <= 2;
                end
                1: begin
                    blk_1 <= (pos_y * `COLS) + pos_x;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                    blk_3 <= ((pos_y + 2) * `COLS) + pos_x;
                    blk_4 <= (pos_y * `COLS) + pos_x + 1;
                    width <= 2;
                    height <= 3;
                end
                2: begin
                    blk_1 <= (pos_y * `COLS) + pos_x;
                    blk_2 <= (pos_y * `COLS) + pos_x + 1;
                    blk_3 <= (pos_y * `COLS) + pos_x + 2;
                    blk_4 <= ((pos_y + 1) * `COLS) + pos_x + 2;
                    width <= 3;
                    height <= 2;
                end
                3: begin
                    blk_1 <= (pos_y * `COLS) + pos_x + 1;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    blk_3 <= ((pos_y + 2) * `COLS) + pos_x + 1;
                    blk_4 <= ((pos_y + 2) * `COLS) + pos_x;
                    width <= 2;
                    height <= 3;
                end
            endcase
        end
        `ORANGE: begin //L BLOCK
            case (rot)
                0: begin
                    blk_1 <= ((pos_y + 1) * `COLS) + pos_x;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    blk_3 <= ((pos_y + 1) * `COLS) + pos_x + 2;
                    blk_4 <= (pos_y * `COLS) + pos_x + 2;
                    width <= 3;
                    height <= 2;
                end
                1: begin
                    blk_1 <= (pos_y * `COLS) + pos_x;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x;
                    blk_3 <= ((pos_y + 2) * `COLS) + pos_x;
                    blk_4 <= ((pos_y + 2) * `COLS) + pos_x + 1;
                    width <= 2;
                    height <= 3;
                end
                2: begin
                    blk_1 <= ((pos_y + 1) * `COLS) + pos_x;
                    blk_2 <= (pos_y * `COLS) + pos_x;
                    blk_3 <= (pos_y * `COLS) + pos_x + 1;
                    blk_4 <= (pos_y * `COLS) + pos_x + 2;
                    width <= 3;
                    height <= 2;
                end
                3: begin
                    blk_1 <= (pos_y * `COLS) + pos_x + 1;
                    blk_2 <= ((pos_y + 1) * `COLS) + pos_x + 1;
                    blk_3 <= ((pos_y + 2) * `COLS) + pos_x + 1;
                    blk_4 <= (pos_y * `COLS) + pos_x;
                    width <= 2;
                    height <= 3;
                end
            endcase
        end
    endcase   
end

endmodule
