//synopsys translate_off
`include "DW01_addsub.v"
`include "DW_rash.v"
`include "DW02_mult.v"
`include "DW01_mux_any.v"
//synopsys translate_on


module MSA_PF(clk, inst, data_in, acc);
input clk;
input [53:0] inst;
input [47:0] data_in;
output [15:0] acc;

wire [15:0] RF_read_1, RF_read_2, RF_read_3, RF_read_3_temp1, RF_read_3_temp2;
wire [15:0] RF3_mux_1, RF3_mux_2;
wire [15:0] M_temp, A_temp, S_temp;
wire [15:0] M_in_1, M_in_2, A_in_1, A_in_2, S_in;
wire [31:0] M_out;
wire [15:0] A_out, S_out;

wire co;

//assign M_out = mult_temp_out[30:15];

Register_File_3R1W u_RF( .clk(clk), .addr_r1(inst[15:12]), .addr_r2(inst[11:8]), .addr_r3(inst[7:4]), .wen_w(inst[20]), .addr_w(inst[19:16]), .data_w(A_temp), .rf_data_r1(RF_read_1), .rf_data_r2(RF_read_2), .rf_data_r3(RF_read_3), .DM_addr_w1(inst[44:41]), .DM_addr_w2(inst[40:37]), .DM_addr_w3(inst[36:33]), .DM_data(data_in), .DM_wen1(inst[47]), .DM_wen2(inst[46]), .DM_wen3(inst[45]), .DM_addr_r(inst[32:29]), .acc(acc) );       

DW01_mux_any #(64, 2, 16) u_M_mux_L( .A({A_temp, S_temp, M_temp, RF_read_1}), .SEL(inst[28:27]), .MUX(M_in_1) );
DW01_mux_any #(64, 2, 16) u_M_mux_R( .A({A_temp, S_temp, M_temp, RF_read_2}), .SEL(inst[26:25]), .MUX(M_in_2) );
DW02_mult #(16, 16) u_mult( .A(M_in_1), .B(M_in_2), .TC(inst[49]), .PRODUCT(M_out) );
DW01_mux_any #(64, 2, 16) u_mux_p1( .A({A_temp, S_temp, M_temp, RF_read_3}), .SEL(inst[53:52]), .MUX(RF3_mux_1) );
p_reg2 u_preg2_1( .clk(clk), .in1(M_out[30:15]), .in2(RF3_mux_1), .out1(M_temp), .out2(RF_read_3_temp1) );

DW01_mux_any #(64, 2, 16) u_S_mux( .A({16'h0000, A_temp, S_temp, M_temp}), .SEL(inst[22:21]), .MUX(S_in) );
sh u_sh( .in(S_in), .sel(inst[3:0]), .out(S_out) );
DW01_mux_any #(64, 2, 16) u_mux_p2( .A({16'h0000, A_temp, S_temp, RF_read_3_temp1}), .SEL(inst[51:50]), .MUX(RF3_mux_2) );
p_reg2 u_preg2_2( .clk(clk), .in1(S_out), .in2(RF3_mux_2), .out1(S_temp), .out2(RF_read_3_temp2) );

DW01_mux_any #(32, 1, 16) u_A_mux_L( .A({A_temp, S_temp}), .SEL(inst[24]), .MUX(A_in_1) );
DW01_mux_any #(32, 1, 16) u_A_mux_R( .A({A_temp, RF_read_3_temp2}), .SEL(inst[23]), .MUX(A_in_2) );
DW01_addsub #(16) u_add( .A(A_in_1), .B(A_in_2), .CI(1'b0), .ADD_SUB(inst[48]), .SUM(A_out), .CO(co) );
p_reg1 u_preg1( .clk(clk), .in1(A_out), .out1(A_temp) );

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

module p_reg2(clk, in1, in2, out1, out2);
input			clk;
input	[15:0]	in1;
input	[15:0]	in2;
output	[15:0]	out1;
output	[15:0]	out2;


reg		[15:0]	out1;
reg		[15:0]	out2;


always @(posedge clk)
begin
	out1 <= in1;
end

always @(posedge clk)
begin
	out2 <= in2;
end

endmodule

