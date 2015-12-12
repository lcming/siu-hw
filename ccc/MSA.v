//synopsys translate_off
`include "DW01_addsub.v"
`include "DW_rash.v"
`include "DW02_mult.v"
//synopsys translate_on

`define ADDR_W 5
`define MEM_W (1 << `ADDR_W)

`define BASE_R 4  //  bit base for decoding RF
`define END_R (`ADDR_W*4+`BASE_R-1)
`define BASE_M (`END_R+2)    // bit base for decoding M
`define END_M (`BASE_M + `ADDR_W*4-1)



module MSA(clk, inst, data_in, acc);
input clk;
input [`END_M+5:0] inst;
input [47:0] data_in;
output [15:0] acc;

wire [15:0] RF_read_1, RF_read_2;
wire [15:0] M_in_1, M_in_2, A_in;
wire [31:0] M_out;
wire [15:0] A_out, S_out;

wire co;

initial
    $display("%d", `END_M);
//assign M_out = mult_temp_out[30:15];

Register_File_3R1W u_RF( .clk(clk), .addr_r1(inst[`ADDR_W*1+`BASE_R-1:`ADDR_W*0+`BASE_R]), .addr_r2(inst[`ADDR_W*2+`BASE_R-1:`ADDR_W*1+`BASE_R]), .addr_r3(inst[`ADDR_W*3+`BASE_R-1:`ADDR_W*2+`BASE_R]), .wen_w(inst[`END_R+1]), .addr_w(inst[`ADDR_W*4+`BASE_R-1:`ADDR_W*3+`BASE_R]), .data_w(A_out), .rf_data_r1(M_in_1), .rf_data_r2(M_in_2), .rf_data_r3(A_in), .DM_addr_w1(inst[`ADDR_W*1+`BASE_M-1:`ADDR_W*0+`BASE_M]), .DM_addr_w2(inst[`ADDR_W*2+`BASE_M-1:`ADDR_W*1+`BASE_M]), .DM_addr_w3(inst[`ADDR_W*3+`BASE_M-1:`ADDR_W*2+`BASE_M]), .DM_data(data_in), .DM_wen1(inst[`END_M+3]), .DM_wen2(inst[`END_M+2]), .DM_wen3(inst[`END_M+1]), .DM_addr_r(inst[`ADDR_W*4+`BASE_M-1:`ADDR_W*3+`BASE_M]), .acc(acc) );       

DW02_mult #(16, 16) u_mult( .A(M_in_1), .B(M_in_2), .TC(inst[`END_M+5]), .PRODUCT(M_out) );
DW01_addsub #(16) u_add( .A(S_out), .B(A_in), .CI(1'b0), .ADD_SUB(inst[`END_M+4]), .SUM(A_out), .CO(co) );
//DW01_ash #(16, 4) u_ash( .A(M_out[30:15]), .DATA_TC(1'b1), .SH(inst[3:0]), .SH_TC(1'b1), .B(S_out) );
sh u_sh( .in(M_out[30:15]), .sel(inst[3:0]), .out(S_out) );

endmodule




module Register_File_3R1W(clk, addr_r1, addr_r2, addr_r3, wen_w, addr_w, data_w, rf_data_r1, rf_data_r2, rf_data_r3, DM_addr_w1, DM_addr_w2, DM_addr_w3, DM_data, DM_wen1, DM_wen2, DM_wen3, DM_addr_r, acc);                                                       
input		clk		;                                              		
input		wen_w		;                                              
input	[15:0]	data_w		;  	
input	[`ADDR_W-1:0]	addr_r1		;                                              
input	[`ADDR_W-1:0]	addr_r2		;				 
input	[`ADDR_W-1:0]	addr_r3		;	                                              
input	[`ADDR_W-1:0]	addr_w		;                                              
input   [`ADDR_W-1:0]   DM_addr_w1;
input   [`ADDR_W-1:0]   DM_addr_w2;
input   [`ADDR_W-1:0]   DM_addr_w3;
input	[`ADDR_W-1:0]	DM_addr_r;
input   [47:0]  DM_data;
input			DM_wen1, DM_wen2, DM_wen3;
	// output
output	[15:0]	rf_data_r1	;	                                       
output	[15:0]	rf_data_r2	;
output	[15:0]	rf_data_r3	;
output	[15:0]	acc;
//=====================================================================
//   WIRE AND REG DECLARATION                                          
//=====================================================================	 
reg [15:0]  register_file [0:`MEM_W-1];
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

DW_rash #(16, 4) u_ash( .A(in), .DATA_TC(1'b1), .SH(sel), .SH_TC(1'b1), .B(out) );
endmodule
