`timescale 1ns / 1ps

`include "define.vh"

module main(
    input clk,
    input reset_n,
    input [3:0] usr_sw,
    input [3:0] usr_btn,
    output [3:0] usr_led,

    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
);

parameter onesecond = 50_000_000;
reg  [$clog2(onesecond):0] system_clk;
reg  [$clog2(onesecond):0] timer;

wire [3:0]btn_pressed;
wire [3:0]btn_level;
reg  [3:0]prev_btn_level;
reg  prev_sw;
wire sw_level;

reg  [3:0]action;
wire gameover;
wire display_en;
reg  new_blk_en;
wire remove_en;
reg  hold_en;
wire start_en;
wire [7:0]remove_row;
reg  [7:0]shift_row;

clk_div#(2) clk_divider1(.clk(clk), .reset(~reset_n), .clk_out(slow_clk));  //20ns

debounce d0(.clk(slow_clk), .btn_input(usr_btn[0]), .btn_output(btn_level[0]));
debounce d1(.clk(slow_clk), .btn_input(usr_btn[1]), .btn_output(btn_level[1]));
debounce d2(.clk(slow_clk), .btn_input(usr_btn[2]), .btn_output(btn_level[2]));
debounce d3(.clk(slow_clk), .btn_input(usr_btn[3]), .btn_output(btn_level[3]));

always @(posedge slow_clk) begin
  if (~reset_n) begin
    prev_btn_level[0] <= 0;
    prev_btn_level[1] <= 0;
    prev_btn_level[2] <= 0;
    prev_btn_level[3] <= 0;
    prev_sw <= usr_sw[0];
  end  
  else begin
    prev_btn_level[0] <= btn_level[0];
    prev_btn_level[1] <= btn_level[1];
    prev_btn_level[2] <= btn_level[2];
    prev_btn_level[3] <= btn_level[3];
    prev_sw <= usr_sw[0];
  end
end

assign btn_pressed[0] = (btn_level[0] == 1 && prev_btn_level[0] == 0)? 1 : 0;
assign btn_pressed[1] = (btn_level[1] == 1 && prev_btn_level[1] == 0)? 1 : 0;
assign btn_pressed[2] = (btn_level[2] == 1 && prev_btn_level[2] == 0)? 1 : 0;
assign btn_pressed[3] = (btn_level[3] == 1 && prev_btn_level[3] == 0)? 1 : 0;
assign sw_level = (prev_sw ^ usr_sw[0]);

reg  [0:(`ROWS * `COLS * 3)-1] board;
wire [0:(`ROWS * `COLS * 3)-1] d_board;
wire [0:23] h_board;
wire [0:23] n1_board;
wire [0:23] n2_board;
wire [0:23] n3_board;
wire [0:23] n4_board;
reg  [9:0] score;
reg  [3:0] pos_x;
reg  [4:0] pos_y;
reg  [2:0] rot;
wire [2:0] width;
wire [2:0] height;
wire [7:0] blk [3:0];

reg  [3:0] test_pos_x;
reg  [4:0] test_pos_y;
reg  [2:0] test_rot;
wire [2:0] test_width;
wire [2:0] test_height;
wire [7:0] test_blk [3:0];

wire is_intersects_board;

reg [2:0] hold;
reg [2:0] current;
reg [2:0] n1;
reg [2:0] n2;
reg [2:0] n3;
reg [2:0] n4;

cur_block cur_blk0 (
    .current(current),
    .pos_x(pos_x),
    .pos_y(pos_y),
    .rot(rot),
    .blk_1(blk[0]),
    .blk_2(blk[1]),
    .blk_3(blk[2]),
    .blk_4(blk[3]),
    .width(width),
    .height(height)
);

cur_block cur_blk1 (
    .current(current),
    .pos_x(test_pos_x),
    .pos_y(test_pos_y),
    .rot(test_rot),
    .blk_1(test_blk[0]),
    .blk_2(test_blk[1]),
    .blk_3(test_blk[2]),
    .blk_4(test_blk[3]),
    .width(test_width),
    .height(test_height)
);

display display0(
    .clk(clk),
    .reset_n(reset_n),
    .usr_sw(usr_sw),
    .board(d_board),
    .h_board(h_board), 
    .n1_board(n1_board),
    .n2_board(n2_board),
    .n3_board(n3_board),
    .n4_board(n4_board),
    .score(score),
    .enable(start_en),
    .VGA_HSYNC(VGA_HSYNC),
    .VGA_VSYNC(VGA_VSYNC),
    .VGA_RED(VGA_RED),
    .VGA_GREEN(VGA_GREEN),
    .VGA_BLUE(VGA_BLUE)
);

displayboard db0(
    .clk(slow_clk),
    .enable(display_en),
    .current(current),
    .board(board), 
    .blk_1(blk[0]),
    .blk_2(blk[1]),
    .blk_3(blk[2]),
    .blk_4(blk[3]),
    .d_board(d_board)
);

displayhold dh0(.clk(slow_clk), .hold(hold), .board(h_board));
displayhold dn1(.clk(slow_clk), .hold(n1), .board(n1_board));
displayhold dn2(.clk(slow_clk), .hold(n2), .board(n2_board));
displayhold dn3(.clk(slow_clk), .hold(n3), .board(n3_board));
displayhold dn4(.clk(slow_clk), .hold(n4), .board(n4_board));

detect_complete_row detect0(
    .clk(slow_clk),
    .enable(detect_en),
    .board(board),
    .remove_row(remove_row),
    .remove_en(remove_en)
    );

reg [2:0] bag [6:0];
reg [2:0] randomIndex;
//-------------------------------------------------------------------------------------------
initial begin
    randomIndex <= 5;
    bag[0] <= 1;
    bag[1] <= 4;
    bag[2] <= 6;
    bag[3] <= 2;
    bag[4] <= 5;
    bag[5] <= 7;
    bag[6] <= 3;
end

task initGame;
    begin     
        initBag();
        hold <= 3'b000;
        current <= bag[0]%7 + 1;
        n1 <= bag[1]%7 + 1;
        n2 <= bag[2]%7 + 1;
        n3 <= bag[3]%7 + 1;
        n4 <= bag[4]%7 + 1;
        randomIndex <= 5;
        
        pos_x <= 4;
        pos_y <= 0;
        rot <= 0;
        test_pos_x <= 4;
        test_pos_y <= 0;
        test_rot <= 0;
        
        system_clk <= 0;
        new_blk_en <= 0;
        hold_en <= 1;
        action <= 4;
        score <= 0;
    end
endtask

task initBag;
    begin
        bag[0] <= bag[0]%7 + 1;
        bag[1] <= bag[1]%7 + 1;
        bag[2] <= bag[2]%7 + 1;
        bag[3] <= bag[3]%7 + 1;
        bag[4] <= bag[4]%7 + 1;
        bag[5] <= bag[5]%7 + 1;
        bag[6] <= bag[6]%7 + 1;
    end
endtask

task getNextPiece;
    begin
        if (randomIndex == 6) begin
          // Refill the bag when all pieces are used
          initBag();
          randomIndex <= 0;
        end
        else begin
        // Get the next piece from the bag
          randomIndex <= randomIndex + 1;
        end
    end
endtask

task SetNewBlock;
    begin
        getNextPiece();
        current <= n1;
        n1 <= n2;
        n2 <= n3;
        n3 <= n4;
        n4 <= bag[randomIndex];
        pos_x <= 4;
        pos_y <= 0;
        rot <= 0;
    end
endtask

function intersects_board;
    input [7:0] blk1;
    input [7:0] blk2;
    input [7:0] blk3;
    input [7:0] blk4;
    begin       
        intersects_board = !((board[3*blk1 +: 3] == 3'b000) &&
                             (board[3*blk2 +: 3] == 3'b000) &&
                             (board[3*blk3 +: 3] == 3'b000) &&
                             (board[3*blk4 +: 3] == 3'b000));
    end
endfunction

assign is_intersects_board = intersects_board(test_blk[0], test_blk[1], test_blk[2], test_blk[3]);

task move_left;
    begin
        if (pos_x > 0 && !is_intersects_board) begin
            pos_x <= pos_x - 1;
        end
    end
endtask

// If the falling piece can be moved right, moves it right
task move_right;
    begin
        if (pos_x + width < `COLS && !is_intersects_board) begin
            pos_x <= pos_x + 1;
        end
    end
endtask

// Rotates the current block if it would not cause any part of the
// block to go off screen and would not intersect with any fallen blocks.
task rotate;
    begin        
        if (pos_x + test_width <= `COLS &&
            pos_y + test_height <= `ROWS &&
            !is_intersects_board) begin
            rot <= (rot == 3) ? 0 : rot + 1;
        end
    end
endtask

task move_down;
    begin       
        if (pos_y + height < `ROWS && !is_intersects_board) begin
            pos_y <= pos_y + 1;
        end else begin
            //WriteToBoard
            new_blk_en <= 1;    
        end
    end
endtask

//---------------------------------------------------------------------------------------------------------------
//FSM of main function
localparam [2:0] S_MAIN_INIT  = 3'b000, S_MAIN_RUN  = 3'b001,
                 S_MAIN_CHECK = 3'b010, S_MAIN_END  = 3'b011,
                 S_MAIN_SHIFT = 3'b100, S_MAIN_NEW  = 3'b101,
                 S_MAIN_HOLD  = 3'b110;
                 
reg [2:0] P, P_next;

assign usr_led = {0,P};

always @(posedge slow_clk or negedge reset_n) begin
    if (~reset_n) timer <= 50_000_000;
    else begin
        if(score >= 50) //
            timer <= 5_000_000;    //0.1s
        else if(usr_sw[2] || score >= 40) 
            timer <= 10_000_000;    //0.2s
        else if(score >= 30) 
            timer <= 20_000_000;    //0.4s
        else if(score >= 20) 
            timer <= 30_000_000;    //0.6
        else if(score >= 10) 
            timer <= 40_000_000;    //0.8s
        else
            timer <= 50_000_000;    //1s
    end
end 

always @(posedge slow_clk or negedge reset_n) begin
    if (~reset_n) P <= S_MAIN_INIT;
    else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT:
        if (btn_pressed[0]) P_next <= S_MAIN_RUN;
        else P_next <= S_MAIN_INIT;
    S_MAIN_RUN:  
        if(remove_en) P_next <= S_MAIN_SHIFT;
        else if(new_blk_en) P_next <= S_MAIN_NEW;
        else if(sw_level && hold_en) P_next <= S_MAIN_HOLD;
        else if((|btn_pressed) || system_clk >= timer) P_next <= S_MAIN_CHECK;
        else P_next <= S_MAIN_RUN;
    S_MAIN_SHIFT:
        if(shift_row > 0) P_next <= S_MAIN_SHIFT;
        else P_next <= S_MAIN_RUN;
    S_MAIN_NEW:
        if (gameover) P_next <= S_MAIN_END;
        else P_next <= S_MAIN_RUN;
    S_MAIN_HOLD:
        P_next <= S_MAIN_RUN;
    S_MAIN_CHECK:
        P_next <= S_MAIN_RUN;
    S_MAIN_END:
        if (btn_pressed[0]) P_next <= S_MAIN_INIT;
        else P_next <=  S_MAIN_END;
    default:
        P_next <= S_MAIN_INIT;
  endcase
end

//-----------------------------------------------------------------------------------------------------------
assign gameover = (P == S_MAIN_NEW) && (|board[0+:3*`COLS]);

assign display_en = (P == S_MAIN_INIT || P == S_MAIN_END) ? 0 : 1; 

assign start_en = ~(P == S_MAIN_INIT);

assign detect_en = (P == S_MAIN_RUN);

always @(posedge slow_clk) begin
    if(~reset_n || P == S_MAIN_INIT) begin
        board <= 0;
        initGame();        
    end
    else if(P == S_MAIN_RUN) begin
        if (system_clk < timer) begin
            system_clk <= system_clk + 1;
        end
        //  3:rotate 2:down 1:left 0:right       
        if (btn_pressed[0]) begin
            test_pos_x <= pos_x + 1;
            test_pos_y <= pos_y;
            test_rot <= rot;          
            action <= 0;
        end else if (btn_pressed[1]) begin
            test_pos_x <= pos_x - 1; 
            test_pos_y <= pos_y;
            test_rot <= rot;                         
            action <= 1;
        end else if (btn_pressed[2] || system_clk >= timer) begin
            test_pos_x <= pos_x;               
            test_pos_y <= pos_y + 1;
            test_rot <= rot;        
            action <= 2;
            system_clk <= 0;        
        end else if (btn_pressed[3]) begin
            test_pos_x <= pos_x;    
            test_pos_y <= pos_y;              
            test_rot <= (rot == 3) ? 0 : rot + 1;
            action <= 3;
        end else if (remove_en) begin
            shift_row <= remove_row;
        end
    end
    else if(P == S_MAIN_CHECK) begin      
        if (action == 0) begin
            move_right();
            action <= 4;
        end else if (action == 1) begin
            move_left();
            action <= 4;  
        end else if (action == 2) begin
            move_down();
            action <= 4;                     
        end else if (action == 3) begin
            rotate();
            action <= 4;
        end
        
    end
    else if(P == S_MAIN_SHIFT) begin
        if (shift_row == 0)begin
           board[0: 3*`COLS - 1] <= 30'b000000000000000000000000000000;
           system_clk <= 0; 
           score <= score + 1;
        end
        else begin
            board[3*shift_row*`COLS +: 3*`COLS] <= board[3*(shift_row-1)*`COLS +: 3*`COLS];
            shift_row <= shift_row - 1;
        end
    end 
    else if(P == S_MAIN_NEW) begin
        new_blk_en <= 0;
        board[3*blk[0] +: 3] <= current;
        board[3*blk[1] +: 3] <= current;
        board[3*blk[2] +: 3] <= current;
        board[3*blk[3] +: 3] <= current;
        SetNewBlock();
        hold_en <= 1;
    end
    else if(P ==  S_MAIN_HOLD) begin
        if(hold == 3'b000) begin
            hold <= current;
            hold_en <= 0;
            SetNewBlock();
        end else begin
            hold <= current;
            current <= hold;
            pos_x <= 4;
            pos_y <= 0;
            rot <= 0;
            hold_en <= 0;
        end
    end
end

endmodule
