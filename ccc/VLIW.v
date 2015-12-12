//synopsys translate_off
`include "DW01_addsub.v"
`include "DW_rash.v"
`include "DW02_mult.v"
//synopsys translate_on

`define ADDR_W 5
`define MEM_W (1 << `ADDR_W)
`define BASE_R 4
`define END_R (`BASE_R+`ADDR_W*8-1)
`define BASE_M (`END_R+3)
`define END_M (`BASE_M+`ADDR_W*6-1)

module VLIW(clk, inst, data_in, acc);
input clk;
input [`END_M+8:0] inst;
input [79:0] data_in;
output [15:0] acc;

wire [15:0] M_in_1, M_in_2, A_in_1, A_in_2, S_in;
wire [31:0] M_out;
wire [15:0] A_out, S_out;
wire [15:0] data_write;

wire co;

initial
    $display("watch:%d", `BASE_M+`ADDR_W*0);

//assign M_out = mult_temp_out[30:15];

Register_File_5R3W u_RF( .clk(clk), .addr_r1_M(inst[`BASE_R+`ADDR_W*1-1:`BASE_R+`ADDR_W*0]), .addr_r2_M(inst[`BASE_R+`ADDR_W*2-1:`BASE_R+`ADDR_W*1]), .addr_r1_A(inst[`BASE_R+`ADDR_W*3-1:`BASE_R+`ADDR_W*2]), .addr_r2_A(inst[`BASE_R+`ADDR_W*4-1:`BASE_R+`ADDR_W*3]), .addr_r_S(inst[`BASE_R+`ADDR_W*5-1:`BASE_R+`ADDR_W*4]), .wen_w_M(inst[`END_M+8]), .addr_w_M(inst[`BASE_R+`ADDR_W*6-1:`BASE_R+`ADDR_W*5]), .data_w_M(M_out[30:15]), .wen_w_A(inst[`END_R+1]), .addr_w_A(inst[`BASE_R+`ADDR_W*7-1:`BASE_R+`ADDR_W*6]), .data_w_A(A_out), .wen_w_S(inst[`END_R+2]), .addr_w_S(inst[`BASE_R+`ADDR_W*8-1:`BASE_R+`ADDR_W*7]), .data_w_S(S_out), .rf_data_r1_M(M_in_1), .rf_data_r2_M(M_in_2), .rf_data_r1_A(A_in_1), .rf_data_r2_A(A_in_2), .rf_data_r_S(S_in), .DM_addr_w1_M(inst[`BASE_M+`ADDR_W*6-1:`BASE_M+`ADDR_W*5]), .DM_addr_w2_M(inst[`BASE_M+`ADDR_W*5-1:`BASE_M+`ADDR_W*4]), .DM_addr_w1_A(inst[`BASE_M+`ADDR_W*4-1:`BASE_M+`ADDR_W*3]), .DM_addr_w2_A(inst[`BASE_M+`ADDR_W*3-1:`BASE_M+`ADDR_W*2]), .DM_addr_w_S(inst[`BASE_M+`ADDR_W*2-1:`BASE_M+`ADDR_W*1]), .DM_data_w(data_in), .DM_wen_M1(inst[`END_M+5]), .DM_wen_M2(inst[`END_M+4]), .DM_wen_A1(inst[`END_M+3]), .DM_wen_A2(inst[`END_M+2]), .DM_wen_S(inst[`END_M+1]), .DM_addr_r(inst[`BASE_M+`ADDR_W*1-1:`BASE_M+`ADDR_W*0]), .DM_data_r(acc) );       

DW02_mult #(16, 16) u_mult( .A(M_in_1), .B(M_in_2), .TC(inst[`END_M+7]), .PRODUCT(M_out) );
DW01_addsub #(16) u_add( .A(A_in_1), .B(A_in_2), .CI(1'b0), .ADD_SUB(inst[`END_M+6]), .SUM(A_out), .CO(co) );
//DW01_ash #(16, 4) u_ash( .A(S_in), .DATA_TC(1'b1), .SH(inst[3:0]), .SH_TC(1'b1), .B(S_out) );
sh u_sh( .in(S_in), .sel(inst[3:0]), .out(S_out) );

endmodule




module Register_File_5R3W(clk, addr_r1_M, addr_r2_M, addr_r1_A, addr_r2_A, addr_r_S, wen_w_M, addr_w_M, data_w_M, wen_w_A, addr_w_A, data_w_A, wen_w_S, addr_w_S, data_w_S, rf_data_r1_M, rf_data_r2_M, rf_data_r1_A, rf_data_r2_A, rf_data_r_S, DM_addr_w1_M, DM_addr_w2_M, DM_addr_w1_A, DM_addr_w2_A, DM_addr_w_S, DM_data_w, DM_wen_M1, DM_wen_M2, DM_wen_A1, DM_wen_A2, DM_wen_S, DM_addr_r, DM_data_r);                                                       
input			clk		;                                              		
input	[`ADDR_W-1:0]	addr_r1_M, addr_r2_M, addr_r1_A, addr_r2_A, addr_r_S		;                                              				                                               
input			wen_w_M, wen_w_A, wen_w_S		;                                              
input	[`ADDR_W-1:0]	addr_w_M, addr_w_A, addr_w_S		;                                              
input	[15:0]	data_w_M, data_w_A, data_w_S		;  	
input   [`ADDR_W-1:0]   DM_addr_w1_M, DM_addr_w2_M, DM_addr_w1_A, DM_addr_w2_A, DM_addr_w_S;
input   [79:0]  DM_data_w;
input			DM_wen_M1, DM_wen_M2, DM_wen_A1, DM_wen_A2, DM_wen_S;
input	[`ADDR_W-1:0]	DM_addr_r;
	// output
output	[15:0]	rf_data_r1_M, rf_data_r2_M, rf_data_r1_A, rf_data_r2_A, rf_data_r_S	;	                                       
output	[15:0]	DM_data_r;
//=====================================================================
//   WIRE AND REG DECLARATION                                          
//=====================================================================	 
reg [15:0]  register_file [`MEM_W-1:0];
//=====================================================================
//   DESIGN                                                            
//=====================================================================

//---------------------------------------------------------------------                                
//	Read                                                                                              
//---------------------------------------------------------------------  
assign DM_data_r = register_file[DM_addr_r];

assign rf_data_r1_M = register_file[addr_r1_M];
					
assign rf_data_r2_M = register_file[addr_r2_M];

assign rf_data_r1_A = register_file[addr_r1_A];
					
assign rf_data_r2_A = register_file[addr_r2_A];

assign rf_data_r_S = register_file[addr_r_S];
                    
//---------------------------------------------------------------------                                
//	Write                                                                                              
//--------------------------------------------------------------------- 
always @ (posedge clk)                                            
begin                                                                  
        if (wen_w_M) register_file[addr_w_M] <= data_w_M;
		if (wen_w_A) register_file[addr_w_A] <= data_w_A;
		if (wen_w_S) register_file[addr_w_S] <= data_w_S;
		
        

  		if (DM_wen_M1) register_file[DM_addr_w1_M] <= DM_data_w[79:64];
        if (DM_wen_M2) register_file[DM_addr_w2_M] <= DM_data_w[63:48];
		if (DM_wen_A1) register_file[DM_addr_w1_A] <= DM_data_w[47:32];
        if (DM_wen_A2) register_file[DM_addr_w2_A] <= DM_data_w[31:16];
		if (DM_wen_S) register_file[DM_addr_w_S] <= DM_data_w[15:0];
	
end
//---------------------------------------------------------------------  

endmodule  

module sh(in, sel, out);
input [15:0] in;
input [3:0] sel;
output [15:0] out;

DW_rash #(16, 4) u_ash( .A(in), .DATA_TC(1'b1), .SH(sel), .SH_TC(1'b1), .B(out) );
endmodule

