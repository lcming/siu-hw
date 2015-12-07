module Register_File_5R3W(clk, addr_r1_M, addr_r2_M, addr_r1_A, addr_r2_A, addr_r_S, wen_w_M, addr_w_M, data_w_M, wen_w_A, addr_w_A, data_w_A, wen_w_S, addr_w_S, data_w_S, rf_data_r1_M, rf_data_r2_M, rf_data_r1_A, rf_data_r2_A, rf_data_r_S, DM_addr_w1_M, DM_addr_w2_M, DM_addr_w1_A, DM_addr_w2_A, DM_addr_w_S, DM_data_w, DM_wen, DM_addr_r, DM_data_r);                                                       
input			clk		;                                              		
input	[3:0]	addr_r1_M, addr_r2_M, addr_r1_A, addr_r2_A, addr_r_S		;                                              				                                               
input			wen_w_M, wen_w_A, wen_w_S		;                                              
input	[3:0]	addr_w_M, addr_w_A, addr_w_S		;                                              
input	[15:0]	data_w_M, data_w_A, data_w_S		;  	
input   [3:0]   DM_addr_w1_M, DM_addr_w2_M, DM_addr_w1_A, DM_addr_w2_A, DM_addr_w_S;
input   [79:0]  DM_data_w;
input			DM_wen;
input	[3:0]	DM_addr_r;
	// output
output	[15:0]	rf_data_r1_M, rf_data_r2_M, rf_data_r1_A, rf_data_r2_A, rf_data_r_S	;	                                       
output	[15:0]	DM_data_r;
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
assign DM_data_r = register_file[DM_addr_r];

assign rf_data_r1_M = register_file[addr_r1_M];
					
assign rf_data_r2_M = register_file[addr_r2_M];

assign rf_data_r1_A = register_file[addr_r1_A];
					
assign rf_data_r2_A = register_file[addr_r2_A];

assign rf_data_r_A = register_file[addr_r_S];
                    
//---------------------------------------------------------------------                                
//	Write                                                                                              
//--------------------------------------------------------------------- 
always @ (posedge clk)                                            
begin                                                                  
        if (wen_w_M) register_file[addr_w_M] <= data_w_M;
		if (wen_w_A) register_file[addr_w_A] <= data_w_A;
		if (wen_w_S) register_file[addr_w_S] <= data_w_S;
		
        if (DM_wen)
        begin
  		    register_file[DM_addr_w1_M] <= DM_data_w[79:64];
            register_file[DM_addr_w2_M] <= DM_data_w[63:48];
			register_file[DM_addr_w1_A] <= DM_data_w[47:32];
            register_file[DM_addr_w2_A] <= DM_data_w[31:16];
			register_file[DM_addr_w_S] <= DM_data_w[15:0];
        end			
end
//---------------------------------------------------------------------  

endmodule  



