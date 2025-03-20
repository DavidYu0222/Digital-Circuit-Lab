`timescale 1ns / 1ps

module md5(
 //   input  enable,
    input clk,
    input  [0:63]  in_txt,
    output [0:127] hash,
    output [0:63]  out_txt
    //output hash_valid
    );
    
reg [0:31] k[0:63];
integer r[0:63];

initial begin
    // Initialize constants
    k[0]  = 32'hd76aa478; k[1]  = 32'he8c7b756; k[2]  = 32'h242070db; k[3]  = 32'hc1bdceee;
    k[4]  = 32'hf57c0faf; k[5]  = 32'h4787c62a; k[6]  = 32'ha8304613; k[7]  = 32'hfd469501;
    k[8]  = 32'h698098d8; k[9]  = 32'h8b44f7af; k[10] = 32'hffff5bb1; k[11] = 32'h895cd7be;
    k[12] = 32'h6b901122; k[13] = 32'hfd987193; k[14] = 32'ha679438e; k[15] = 32'h49b40821;
    k[16] = 32'hf61e2562; k[17] = 32'hc040b340; k[18] = 32'h265e5a51; k[19] = 32'he9b6c7aa;
    k[20] = 32'hd62f105d; k[21] = 32'h02441453; k[22] = 32'hd8a1e681; k[23] = 32'he7d3fbc8;
    k[24] = 32'h21e1cde6; k[25] = 32'hc33707d6; k[26] = 32'hf4d50d87; k[27] = 32'h455a14ed;
    k[28] = 32'ha9e3e905; k[29] = 32'hfcefa3f8; k[30] = 32'h676f02d9; k[31] = 32'h8d2a4c8a;
    k[32] = 32'hfffa3942; k[33] = 32'h8771f681; k[34] = 32'h6d9d6122; k[35] = 32'hfde5380c;
    k[36] = 32'ha4beea44; k[37] = 32'h4bdecfa9; k[38] = 32'hf6bb4b60; k[39] = 32'hbebfbc70;
    k[40] = 32'h289b7ec6; k[41] = 32'heaa127fa; k[42] = 32'hd4ef3085; k[43] = 32'h04881d05;
    k[44] = 32'hd9d4d039; k[45] = 32'he6db99e5; k[46] = 32'h1fa27cf8; k[47] = 32'hc4ac5665;
    k[48] = 32'hf4292244; k[49] = 32'h432aff97; k[50] = 32'hab9423a7; k[51] = 32'hfc93a039;
    k[52] = 32'h655b59c3; k[53] = 32'h8f0ccc92; k[54] = 32'hffeff47d; k[55] = 32'h85845dd1;
    k[56] = 32'h6fa87e4f; k[57] = 32'hfe2ce6e0; k[58] = 32'ha3014314; k[59] = 32'h4e0811a1;
    k[60] = 32'hf7537e82; k[61] = 32'hbd3af235; k[62] = 32'h2ad7d2bb; k[63] = 32'heb86d391;

    // Initialize shift amounts
    r[0]  = 7;  r[1]  = 12; r[2]  = 17; r[3]  = 22;
    r[4]  = 7;  r[5]  = 12; r[6]  = 17; r[7]  = 22;
    r[8]  = 7;  r[9]  = 12; r[10] = 17; r[11] = 22;
    r[12] = 7;  r[13] = 12; r[14] = 17; r[15] = 22;
    r[16] = 5;  r[17] = 9;  r[18] = 14; r[19] = 20;
    r[20] = 5;  r[21] = 9;  r[22] = 14; r[23] = 20;
    r[24] = 5;  r[25] = 9;  r[26] = 14; r[27] = 20;
    r[28] = 5;  r[29] = 9;  r[30] = 14; r[31] = 20;
    r[32] = 4;  r[33] = 11; r[34] = 16; r[35] = 23;
    r[36] = 4;  r[37] = 11; r[38] = 16; r[39] = 23;
    r[40] = 4;  r[41] = 11; r[42] = 16; r[43] = 23;
    r[44] = 4;  r[45] = 11; r[46] = 16; r[47] = 23;
    r[48] = 6;  r[49] = 10; r[50] = 15; r[51] = 21;
    r[52] = 6;  r[53] = 10; r[54] = 15; r[55] = 21;
    r[56] = 6;  r[57] = 10; r[58] = 15; r[59] = 21;
    r[60] = 6;  r[61] = 10; r[62] = 15; r[63] = 21;
end

integer r_bar = 32;

reg [0:63] w;
reg [0:31] A, A_next;
reg [0:31] B, B_next;
reg [0:31] C, C_next;
reg [0:31] D, D_next;
reg [0:127] hash_reg;
reg [0:63] out_reg;
integer i;

//assign hash_valid = valid;
assign hash = hash_reg;
assign out_txt = out_reg;

//running time about 20 clk
always@(posedge clk) begin
    w = {in_txt[24+:8], in_txt[16+:8], in_txt[ 8+:8], in_txt[ 0+:8],
          in_txt[56+:8], in_txt[48+:8], in_txt[40+:8], in_txt[32+:8]};
          
    A = 32'h67452301;
    B = 32'hefcdab89;
    C = 32'h98badcfe;
    D = 32'h10325476;

    for(i = 0; i < 64; i = i + 1) begin   
        if (i < 16) begin
            // f[i] = (B[i-1] & C[i-1]) | ((~B[i-1]) & D[i-1])
            // g[i] = i
            D_next = C;
            C_next = B;
            A_next = D;
            if(i == 0)    
                B_next = (((k[i] + ((B&C)|((~B)&D)) + A + w[0  +: 32]) <<r[i])|
                           ((k[i] + ((B&C)|((~B)&D)) + A + w[0  +: 32]) >> (r_bar - r[i]))) + B;
            else if(i == 1)
                B_next = (((k[i] + ((B&C)|((~B)&D)) + A + w[32 +: 32]) << r[i])|
                           ((k[i] + ((B&C)|((~B)&D)) + A + w[32 +: 32]) >>(r_bar - r[i]))) + B;
            else if(i == 2)
                B_next = (((k[i] + ((B&C)|((~B)&D)) + A + 32'h00000080) << r[i])|
                           ((k[i] + ((B&C)|((~B)&D)) + A + 32'h00000080) >>(r_bar - r[i]))) + B;
            else if(i == 14)
                B_next = (((k[i] + ((B&C)|((~B)&D)) + A + 32'h00000040) << r[i])|
                           ((k[i] + ((B&C)|((~B)&D)) + A + 32'h00000040) >>(r_bar - r[i]))) + B;
            else 
                B_next = (((k[i] + ((B&C)|((~B)&D)) + A) << r[i])|
                           ((k[i] + ((B&C)|((~B)&D)) + A) >> (r_bar - r[i]))) + B;     
        end 
        else if (i < 32) begin
            // f[i] = (D[i-1] & B[i-1]) | ((~D[i-1]) & C[i-1])
            // g[i] = (5*i + 1) % 16
            D_next = C;
            C_next = B;
            A_next = D;
            if(i == 16)    
                B_next = (((k[i] + ((D&B)|((~D)&C)) + A + w[32 +: 32]) << r[i])|
                           ((k[i] + ((D&B)|((~D)&C)) + A + w[32 +: 32]) >> (r_bar - r[i]))) + B;
            else if(i == 19)
                B_next = (((k[i] + ((D&B)|((~D)&C)) + A + w[0  +: 32]) <<  r[i])|
                           ((k[i] + ((D&B)|((~D)&C)) + A + w[0  +: 32]) >> (r_bar - r[i]))) + B;
            else if(i == 25)
                B_next = (((k[i] + ((D&B)|((~D)&C)) + A + 32'h00000040) <<  r[i])|
                           ((k[i] + ((D&B)|((~D)&C)) + A + 32'h00000040) >> (r_bar - r[i]))) + B;
            else if(i == 29)
                B_next = (((k[i] + ((D&B)|((~D)&C)) + A + 32'h00000080) <<  r[i])|
                           ((k[i] + ((D&B)|((~D)&C)) + A + 32'h00000080) >> (r_bar - r[i]))) + B;
            else
                B_next = (((k[i] + ((D&B)|((~D)&C)) + A) << r[i])|
                           ((k[i] + ((D&B)|((~D)&C)) + A) >> (r_bar - r[i]))) + B; 
        end 
        else if (i < 48) begin
            //f[i] = b[i-1] ^ c[i-1] ^ d[i-1]
            //g[i] = (3*i + 5) % 16 
            D_next = C;
            C_next = B;
            A_next = D;  
            if(i == 36)    
                B_next = (((k[i] + (B ^ C ^ D) + A + w[32 +: 32]) << r[i])|
                           ((k[i] + (B ^ C ^ D) + A + w[32 +: 32]) >> (r_bar - r[i]))) + B;
            else if(i == 41)
                B_next = (((k[i] + (B ^ C ^ D) + A + w[0  +: 32]) << r[i])|
                           ((k[i] + (B ^ C ^ D) + A + w[0  +: 32]) >> (r_bar - r[i]))) + B;
            else if(i == 35)
                B_next = (((k[i] + (B ^ C ^ D) + A + 32'h00000040) << r[i])|
                           ((k[i] + (B ^ C ^ D) + A + 32'h00000040) >> (r_bar - r[i]))) + B;
            else if(i == 47)
                B_next = (((k[i] + (B ^ C ^ D) + A + 32'h00000080) << r[i])|
                           ((k[i] + (B ^ C ^ D) + A + 32'h00000080) >> (r_bar - r[i]))) + B;
            else
                B_next = (((k[i] + (B ^ C ^ D) + A) << r[i])|
                           ((k[i] + (B ^ C ^ D) + A) >>(r_bar - r[i]))) + B; 
        end else begin
            //f[i] = c[i-1] ^ (b[i-1] | (~d[i-1]));
            //g[i] = (7*i) % 16;
            D_next = C;
            C_next = B;
            A_next = D;
            if(i == 48)    
                B_next = (((k[i] + (C^(B|(~D))) + A + w[0  +: 32]) << r[i])|
                           ((k[i] + (C^(B|(~D))) + A + w[0  +: 32]) >> (r_bar - r[i]))) + B;
            else if(i == 55)
                B_next = (((k[i] + (C^(B|(~D))) + A + w[32 +: 32]) << r[i])|
                           ((k[i] + (C^(B|(~D))) + A + w[32 +: 32]) >> (r_bar - r[i]))) + B;
            else if(i == 50)
                B_next = (((k[i] + (C^(B|(~D))) + A + 32'h00000040) << r[i])|
                           ((k[i] + (C^(B|(~D))) + A + 32'h00000040) >> (r_bar - r[i]))) + B;
            else if(i == 62)
                B_next = (((k[i] + (C^(B|(~D))) + A + 32'h00000080) << r[i])|
                           ((k[i] + (C^(B|(~D))) + A + 32'h00000080) >> (r_bar - r[i]))) + B;
            else
                B_next = (((k[i] + (C^(B|(~D))) + A) << r[i])|
                           ((k[i] + (C^(B|(~D))) + A) >> (r_bar - r[i]))) + B;            
        end
        A = A_next;
        B = B_next;
        C = C_next;
        D = D_next;
    end
    A = A + 32'h67452301;
    B = B + 32'hefcdab89;
    C = C + 32'h98badcfe;
    D = D + 32'h10325476;
    
    hash_reg = {A[24 +: 8], A[16 +: 8], A[ 8 +: 8], A[ 0 +: 8],
                 B[24 +: 8], B[16 +: 8], B[ 8 +: 8], B[ 0 +: 8],
                 C[24 +: 8], C[16 +: 8], C[ 8 +: 8], C[ 0 +: 8],
                 D[24 +: 8], D[16 +: 8], D[ 8 +: 8], D[ 0 +: 8]};

    out_reg  = {w[24 +: 8], w[16 +: 8], w[ 8 +: 8], w[ 0 +: 8],
                w[56 +: 8], w[48 +: 8], w[40 +: 8], w[32 +: 8]};
end

endmodule
