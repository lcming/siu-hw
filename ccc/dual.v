//synopsys translate_off
`include "DW01_addsub.v"
`include "DW_rash.v"
`include "DW02_mult.v"
`include "DW01_mux_any.v"
//synopsys translate_on

// define macro
`define ADDR_W 3
`define MEM_W (1 << `ADDR_W)
`define OFFSET (MEM_W >> 1)
`define DATA_W 16
`define INST_W 8

// stack operation


module dual(clk, inst1, inst2, in1, in2, acc, overflow);

parameter PUSH = 2'b00;
parameter WRITE= 2'b01;
parameter POP  = 2'b10;
parameter NOP  = 2'b11;

input clk;
input [`INST_W-1:0] inst1, inst2;
input [`DATA_W-1:0] in1, in2;
output [`DATA_W-1:0] acc;
output overflow;

reg [`DATA_W-1:0] add_buf, mul_buf, shi_buf;

endmodule


/*****************************/
/*queue memory implementation*/
/*****************************/
module queue(clk, data_in, data_out, push, pop);

input clk, push, pop;
input [`DATA_W-1:0] data_in;
output [`DATA_W-1:0] data_out;


reg [`ADDR_W-1:0] head, n_head, tail, n_tail;
reg [`DATA_W-1:0] mem [`MEM_W-1:0];

// output data
assign data_out = mem[tail];

// input data
always@(posedge clk)
begin
    if(push)
        mem[head] = data_in;
end

// update ptr
always@(posedge clk)
begin: PTR_UPDATE
    head <= n_head;
    tail <= n_tail;
end

// calculate next ptr
always@(*)
begin
    if(push)
        n_head = head + `ADDR_W'b1;
    else 
        n_head = head;
end

always@(*)
begin
    if(pop)
        n_tail = tail + `ADDR_W'b1;
    else 
        n_tail = tail;
end

endmodule

/*****************************/
/*stack memory implementation*/
/*****************************/
module stack(clk, op, data);

parameter PUSH = 2'b00;
parameter WRITE= 2'b01;
parameter POP  = 2'b10;
parameter NOP  = 2'b11;

input clk;
input [1:0] op;
inout [`DATA_W-1:0] data;

reg [`ADDR_W-1:0] ptr, n_ptr;
reg [`DATA_W-1:0] mem [`MEM_W-1:0];


assign data = (op[1])? mem[ptr] : `DATA_W'bz;

always@(posedge clk)
begin: MEM_WRITE
    if( !op[1] )
        mem[ptr] <= data;
end

always@(posedge clk)
begin: PTR_UPDATE
    ptr <= n_ptr;
end

always@(*)
begin
    case(op)
        PUSH:
        begin
            n_ptr = ptr + `ADDR_W'b1;
        end
        POP:
        begin
            n_ptr = ptr - `ADDR_W'b1;
        end
        default:
        begin
            n_ptr = ptr;
        end
    endcase

end
endmodule
