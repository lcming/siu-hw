//synopsys translate_off
`include "DW01_addsub.v"
`include "DW_rash.v"
`include "DW02_mult.v"
`include "DW01_mux_any.v"
`include "DW03_pipe_reg.v"
//synopsys translate_on


module MS_11(clk, inst, data_in, acc);
input clk;
input [55:0] inst;
input [47:0] data_in;
output [15:0] acc;

wire [15:0] RF_read_1, RF_read_2, RF_read_3;
wire [15:0] mux_L_M, mux_L_A, mux_L_S;
wire [15:0] M_in_1, M_in_2, A_in_1, A_in_2, S_in;
wire [31:0] M_out;
wire [15:0] A_out, S_out;
wire [15:0] data_w;

wire co;

//assign M_out = mult_temp_out[30:15];

Register_File_3R1W u_RF( .clk(clk), .addr_r1(inst[15:12]), .addr_r2(inst[11:8]), .addr_r3(inst[7:4]), .wen_w(inst[20]), .addr_w(inst[19:16]), .data_w(data_w), .rf_data_r1(RF_read_1), .rf_data_r2(RF_read_2), .rf_data_r3(RF_read_3), .DM_addr_w1(inst[50:47]), .DM_addr_w2(inst[46:43]), .DM_addr_w3(inst[42:39]), .DM_data(data_in), .DM_wen1(inst[53]), .DM_wen2(inst[52]), .DM_wen3(inst[51]), .DM_addr_r(inst[38:35]), .acc(acc) );       

demux_2to3 u_demun2to3( .in(RF_read_1), .sel(inst[34:33]), .y0(mux_L_M), .y1(mux_L_A), .y2(mux_L_S) );

buffer_2 u_buffer_2_M( .clk(clk), .port_L(mux_L_M), .port_R(RF_read_2), .M_out(M_out[30:15]), .A_out(A_out), .S_out(S_out), .mux_L(inst[32:31]), .mux_R(inst[30:29]), .out_L(M_in_1), .out_R(M_in_2) );
DW02_mult #(16, 16) u_mult( .A(M_in_1), .B(M_in_2), .TC(inst[55]), .PRODUCT(M_out) );

buffer_2 u_buffer_2_A( .clk(clk), .port_L(mux_L_A), .port_R(RF_read_3), .M_out(M_out[30:15]), .A_out(A_out), .S_out(S_out), .mux_L(inst[28:27]), .mux_R(inst[26:25]), .out_L(A_in_1), .out_R(A_in_2) );
DW01_addsub #(16) u_add( .A(A_in_1), .B(A_in_2), .CI(1'b0), .ADD_SUB(inst[54]), .SUM(A_out), .CO(co) );

buffer_1 u_buffer_1_S( .clk(clk), .port_1(mux_L_S), .M_out(M_out[30:15]), .A_out(A_out), .S_out(S_out), .mux_L1(inst[24:23]), .out(S_in) );
sh u_sh( .in(S_in), .sel(inst[3:0]), .out(S_out) );

DW01_mux_any #(64, 2, 16) u_mux_3( .A({16'h0000, S_out, A_out, M_out[30:15]}), .SEL(inst[22:21]), .MUX(data_w) );
//mux_3to1 u_mux_3( .in0(M_out[30:15]), .in1(A_out), .in2(S_out), .sel(inst[50:49]), .y(data_w) );
endmodule




module Register_File_3R1W(clk, addr_r1, addr_r2, addr_r3, wen_w, addr_w, data_w, rf_data_r1, rf_data_r2, rf_data_r3, DM_addr_w1, DM_addr_w2, DM_addr_w3, DM_data, DM_wen1, DM_wen2, DM_wen3, DM_addr_r, acc);                                                       
input		clk		;                                              		
input	[3:0]	addr_r1		;                                              
input	[3:0]	addr_r2		;				 
input	[3:0]	addr_r3		;	                                          
input		wen_w		;                                              
input	[3:0]	addr_w		;                                              
input	[15:0]	data_w		;  	
input   [3:0]   DM_addr_w1;
input   [3:0]   DM_addr_w2;
input   [3:0]   DM_addr_w3;
input   [47:0]  DM_data;
input			DM_wen1, DM_wen2, DM_wen3;
input	[3:0]	DM_addr_r;
	// output
output	[15:0]	rf_data_r1	;	                                       
output	[15:0]	rf_data_r2	;
output	[15:0]	rf_data_r3	;
output	[15:0]	acc;
//=====================================================================
//   WIRE AND REG DECLARATION                                          
//=====================================================================	 
reg [15:0]  register_file [0:15];
//=====================================================================
//   DESIGN                                                            
//=====================================================================

//---------------------------------------------------------------------                                
//	Read                                                                                              
//---------------------------------------------------------------------  
assign acc = register_file[DM_addr_r];

assign rf_data_r1 = register_file[addr_r1];
					
assign rf_data_r2 = register_file[addr_r2];

assign rf_data_r3 = register_file[addr_r3];

                    
//---------------------------------------------------------------------                                
//	Write                                                                                              
//--------------------------------------------------------------------- 
always @ (posedge clk)                                            
begin                                                                  
        if (wen_w) register_file[addr_w] <= data_w;
		
		if (DM_wen1) register_file[DM_addr_w1] <= DM_data[47:32];
		if (DM_wen2) register_file[DM_addr_w2] <= DM_data[31:16];
		if (DM_wen3) register_file[DM_addr_w3] <= DM_data[15:0];

		
end
//---------------------------------------------------------------------  

endmodule  

module sh(in, sel, out);
input [15:0] in;
input [3:0] sel;
output [15:0] out;

DW_rash #(16, 4) u_rash( .A(in), .DATA_TC(1'b1), .SH(sel), .SH_TC(1'b1), .B(out) );
endmodule


module buffer_1(clk, port_1, M_out, A_out, S_out, mux_L1, out);
input clk;
input [15:0] port_1;
input [15:0] M_out;
input [15:0] A_out;
input [15:0] S_out;
input [1:0] mux_L1;
output [15:0] out;

wire [15:0] temp_in_1;

//mux_4to1 u_mux4( .in0(S_out), .in1(A_out), .in2(M_out), .in3(port_1), .sel(mux_L1), .y(temp_in_1) );
DW01_mux_any #(64, 2, 16) u_mux4( .A({S_out, A_out, M_out, port_1}), .SEL(mux_L1), .MUX(temp_in_1) );
p_reg1 u_preg_1( .clk(clk), .in1(temp_in_1), .out1(out) );
//DW03_pipe_reg #(1, 16) u_preg_1( .A(temp_in_1), .clk(clk), .B(out) );
endmodule

module buffer_2(clk, port_L, port_R, M_out, A_out, S_out, mux_L, mux_R, out_L, out_R);
input clk;
input [15:0] port_L;
input [15:0] port_R;
input [15:0] M_out;
input [15:0] A_out;
input [15:0] S_out;
input [1:0] mux_L;
input [1:0] mux_R;
output [15:0] out_L;
output [15:0] out_R;

wire [15:0] temp_in_L, temp_out_L;
wire [15:0] temp_in_R, temp_out_R;

//mux_4to1 u_mux4( .in0(S_out), .in1(A_out), .in2(M_out), .in3(port_1), .sel(mux_L1), .y(temp_in_L1) );
DW01_mux_any #(64, 2, 16) u_mux4_L( .A({S_out, A_out, M_out, port_L}), .SEL(mux_L), .MUX(temp_in_L) );
p_reg1 u_preg_L( .clk(clk), .in1(temp_in_L), .out1(out_L) );
//DW03_pipe_reg #(1, 16) u_preg_L1( .A(temp_in_L1), .clk(clk), .B(out_L) );

//mux_4to1 u_mux4( .in0(S_out), .in1(A_out), .in2(M_out), .in3(port_1), .sel(mux_L1), .y(temp_in_L1) );
DW01_mux_any #(64, 2, 16) u_mux4_R( .A({S_out, A_out, M_out, port_R}), .SEL(mux_R), .MUX(temp_in_R) );
p_reg1 u_preg_R( .clk(clk), .in1(temp_in_R), .out1(out_R) );
//DW03_pipe_reg #(1, 16) u_preg_L1( .A(temp_in_L1), .clk(clk), .B(out_L) );

endmodule

module demux_2to3(in, sel, y0, y1, y2);
input [15:0] in;
input [1:0] sel;
output [15:0] y0;
output [15:0] y1;
output [15:0] y2;

assign y0 = (sel==2'b00) ? in : 0;
assign y1 = (sel==2'b01) ? in : 0; 
assign y2 = (sel==2'b10) ? in : 0; 

endmodule

module p_reg1(clk, in1, out1);
input			clk;
input	[15:0]	in1;
output	[15:0]	out1;


reg		[15:0]	out1;


always @(posedge clk)
begin
	out1 <= in1;
end

endmodule
