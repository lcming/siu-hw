//synopsys translate_off
`include "DW01_addsub.v"
`include "DW_rash.v"
`include "DW02_mult.v"
`include "DW01_mux_any.v"
//synopsys translate_on

`define ADDR_W 4
`define MEM_W (1 << ADDR_W)

`define BASE 9  //  bit base for decoding RF
`define BASE_M (`ADDR_W*3+`BASE+1)    // bit base for decoding M
`define END_M (`BASE_M + `ADDR_W*3)

module Scalar(clk, inst, data_in, acc);
input clk;
input [37:0] inst;
input [31:0] data_in;
output [15:0] acc;

wire [15:0] RF_read_1, RF_read_2;
wire [15:0] M_in_1, M_in_2, A_in_1, A_in_2, S_in;
wire [31:0] M_out;
wire [15:0] A_out, S_out;
wire [15:0] data_write;

wire co;

//assign M_out = mult_temp_out[30:15];

Register_File_2R1W u_RF( .clk(clk), .addr_r1(inst[`ADDR_W*2+`BASE-1:`ADDR_W+`BASE]), .addr_r2(inst[`ADDR_W+`BASE-1:`BASE]), .wen_w(inst[`ADDR_W*3+`BASE]), .addr_w(inst[`ADDR_W*3+`BASE-1:`ADDR_W*2+`BASE]), .data_w(data_write), .rf_data_r1(RF_read_1), .rf_data_r2(RF_read_2), .DM_addr_w1(inst[`ADDR_W*3+`BASE_M-1:`BASE_M+`ADDR_W*2]), .DM_addr_w2(inst[`BASE_M+`ADDR_W*2-1:`ADDR_W+`BASE_M]), .DM_data(data_in), .DM_wen_1(inst[`END_M+1]), .DM_wen_2(inst[`END_M]), .DM_addr_r(inst[`ADDR_W+`BASE_M-1:`BASE_M]), .acc(acc) );       

demux_2to3 u_demun2to3( .in(RF_read_1), .sel(inst[4:3]), .y0(M_in_1), .y1(A_in_1), .y2(S_in) );
demux_1to2 u_demux1to2( .in(RF_read_2), .sel(inst[2]), .y0(M_in_2), .y1(A_in_2) );

DW02_mult #(16, 16) u_mult( .A(M_in_1), .B(M_in_2), .TC(inst[`END_M+3]), .PRODUCT(M_out) );
DW01_addsub #(16) u_addsub( .A(A_in_1), .B(A_in_2), .CI(1'b0), .ADD_SUB(inst[`END_M+2]), .SUM(A_out), .CO(co) );
//DW01_ash #(16, 4) u_ash( .A(S_in), .DATA_TC(1'b1), .SH(inst[8:5]), .SH_TC(1'b1), .B(S_out) );
sh u_sh( .in(S_in), .sel(inst[8:5]), .out(S_out) );

DW01_mux_any #(64, 2, 16) u_mux_3( .A({16'h0000, S_out, A_out, M_out[30:15]}), .SEL(inst[1:0]), .MUX(data_write) );
//mux_3to1 u_mux3to1( .in0(M_out[30:15]), .in1(A_out), .in2(S_out), .sel(inst[1:0]), .y(data_write) );

endmodule




module Register_File_2R1W(clk, addr_r1, addr_r2, wen_w, addr_w, data_w, rf_data_r1, rf_data_r2, DM_addr_w1, DM_addr_w2, DM_data, DM_wen_1, DM_wen_2, DM_addr_r, acc);                                                       
input		clk		;                                              		
input	[3:0]	addr_r1		;                                              
input	[3:0]	addr_r2		;				                                               
input		wen_w		;                                              
input	[3:0]	addr_w		;                                              
input	[15:0]	data_w		;  	
input   [3:0]   DM_addr_w1;
input   [3:0]   DM_addr_w2;
input   [31:0]  DM_data;
input			DM_wen_1;
input			DM_wen_2;
input	[3:0]	DM_addr_r;
	// output
output	[15:0]	rf_data_r1	;	                                       
output	[15:0]	rf_data_r2	;
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
                    
//---------------------------------------------------------------------                                
//	Write                                                                                              
//--------------------------------------------------------------------- 
always @ (posedge clk)                                            
begin                                                                  
        if (wen_w) register_file[addr_w] <= data_w;
		
        if (DM_wen_1) register_file[DM_addr_w1] <= DM_data[31:16];
		if (DM_wen_2) register_file[DM_addr_w2] <= DM_data[15:0];
end
//---------------------------------------------------------------------  

endmodule  


module sh(in, sel, out);
input [15:0] in;
input [3:0] sel;
output [15:0] out;

DW_rash #(16, 4) u_rash( .A(in), .DATA_TC(1'b1), .SH(sel), .SH_TC(1'b1), .B(out) );
endmodule


module mux_3to1(in0, in1, in2, sel, y);
input [15:0] in0;
input [15:0] in1;
input [15:0] in2;
input [1:0] sel;
output [15:0] y;

assign y = (sel[1]==1) ? (in2) : ( (sel[0]==1) ? (in1) : (in0) );
 
endmodule

module demux_1to2(in, sel, y0, y1);
input [15:0] in;
input sel;
output [15:0] y0;
output [15:0] y1;

assign y0 = (sel==0) ? in : 0;
assign y1 = (sel==1) ? in : 0; 

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
