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
`define LOG_DATA_W 4
`define INST_W 6

// stack operation


module dual(clk, inst1, inst2, data1, data2, data1_in_en, data2_in_en, data1_out_en, data2_out_en, M_sel, A_sel, S_sel, A_overflow);

parameter PUSH = 2'b00;
parameter WRITE= 2'b01;
parameter POP  = 2'b10;
parameter NOP  = 2'b11;

input clk, data1_in_en, data2_in_en, data1_out_en, data2_out_en;
input [1:0] M_sel, A_sel, S_sel; // 0: valid 1: select
input [`INST_W-1:0] inst1, inst2;
inout [`DATA_W-1:0] data1, data2;
output A_overflow;

reg [`DATA_W-1:0] A_buf, M_buf, S_buf;
reg [`DATA_W-1:0] n_A_buf, n_M_buf, n_S_buf;

reg [`DATA_W-1:0] A_in1, A_in2, M_in1, M_in2, S_in, q2_in, q1_in;

wire [`DATA_W*2-1:0] _M_out;
wire [`DATA_W-1:0] A_out, M_out, S_out, q1_out, s1_data, q2_out, s2_data, q1_in_final, q2_in_final;
wire [1:0] A_in1_sel, M_in1_sel, S_in_sel, s1_op, s2_op;
wire [2:0] A_in2_sel, M_in2_sel;
wire q1_push, q1_pop, q2_push, q2_pop, A_cand, M_cand, S_cand, A_overflow;
wire [`LOG_DATA_W-1:0] S_m;

// ping pong control


// FU instantiation
assign M_out = _M_out[`DATA_W*2-1:`DATA_W];
DW02_mult #(`DATA_W, `DATA_W) u_mult ( .A(M_in1), .B(M_in2), .TC(1'b1), .PRODUCT(_M_out));
DW01_addsub #(`DATA_W) u_addsub ( .A(A_in1), .B(A_in2), .CI(1'b0), .ADD_SUB(1'b0), .SUM(A_out), .CO(A_overflow));
DW_rash #(`DATA_W, `LOG_DATA_W) u_rash ( .A(S_in), .DATA_TC(1'b1), .SH(S_m), .SH_TC(1'b1), .B(S_out));

// RF instantiation
//module queue(clk, data_in, data_out, push, pop);
queue q1 (.clk(clk), .data_in(q1_in_final), .data_out(q1_out), .push(q1_push), .pop(q1_pop));
queue q2 (.clk(clk), .data_in(q2_in_final), .data_out(q2_out), .push(q2_push), .pop(q2_pop));

//module stack(clk, op, data);
stack s1 (.clk(clk), .op(s1_op), .data(s1_data));
stack s2 (.clk(clk), .op(s2_op), .data(s2_data));

// stack op
assign s1_op = inst1[4:3];
assign s2_op = inst2[4:3];

// push Q
assign q1_in_final = inst1[5]? q1_in : data1;
assign q2_in_final = inst2[5]? q2_in : data2;
assign q1_push = inst1[5] | data1_in_en;
assign q2_push = inst2[5] | data2_in_en;

// pop Q
assign data1 = data1_in_en? `DATA_W'bz : q1_out;
assign data2 = data2_in_en? `DATA_W'bz : q2_out;
assign q1_pop = inst1[0] | data1_out_en;
assign q2_pop = inst2[0] | data2_out_en;

// FU result buffer
always@(*)
begin
    n_A_buf = A_sel[0]? A_out : A_buf;
    n_M_buf = M_sel[0]? M_out : M_buf;
    n_S_buf = S_sel[0]? S_out : S_buf;
end

always@(posedge clk)
begin
    A_buf <= n_A_buf;
    M_buf <= n_M_buf;
    S_buf <= n_S_buf;
end


// MUXs //
// input of FUs
always@(*)
begin//: A_IN1
    casex({A_sel[1], inst1[0], inst2[0]})
        3'b00x: begin A_in1 = q1_out;  end
        3'b01x: begin A_in1 = s1_data; end
        3'b1x0: begin A_in1 = q2_out;  end
        3'b1x1: begin A_in1 = s2_data; end
        default: begin A_in1 = q1_out; end
    endcase
end

always@(*)
begin//: M_IN1
    casex({M_sel[1], inst1[0], inst2[0]})
        3'b00x: begin M_in1 = q1_out;  end
        3'b01x: begin M_in1 = s1_data; end
        3'b1x0: begin M_in1 = q2_out;  end
        3'b1x1: begin M_in1 = s2_data; end
        default: begin M_in1 = q1_out; end
    endcase
end


assign S_m = S_sel[1]? q2_out[`LOG_DATA_W-1:0] : q1_out[`LOG_DATA_W-1:0];

// special case for shifter in, treat it as IN2
always@(*)
begin//: S_IN
    casex( {S_sel[1], inst1[2:1], inst2[2:1]} )
        5'b001xx: begin S_in = A_buf;  end
        5'b010xx: begin S_in = M_buf;  end
        5'b011xx: begin S_in = S_buf;  end
        5'b1xx01: begin S_in = A_buf;  end
        5'b1xx10: begin S_in = M_buf;  end
        5'b1xx11: begin S_in = S_buf;  end
        default : begin S_in = A_buf;  end
    endcase
end



always@(*)
begin//: A_IN2
    casex( {A_sel[1], inst1[2:1], inst2[2:1]} )
        5'b000xx: begin A_in2 = q2_out; end
        5'b001xx: begin A_in2 = A_buf;  end
        5'b010xx: begin A_in2 = M_buf;  end
        5'b011xx: begin A_in2 = S_buf;  end
        5'b1xx00: begin A_in2 = q1_out; end
        5'b1xx01: begin A_in2 = A_buf;  end
        5'b1xx10: begin A_in2 = M_buf;  end
        5'b1xx11: begin A_in2 = S_buf;  end
        default : begin A_in2 = q2_out; end
    endcase
end

always@(*)
begin//: M_IN2
    casex( {M_sel[1], inst1[2:1], inst2[2:1]} )
        5'b000xx: begin M_in2 = q2_out; end
        5'b001xx: begin M_in2 = A_buf;  end
        5'b010xx: begin M_in2 = M_buf;  end
        5'b011xx: begin M_in2 = S_buf;  end
        5'b1xx00: begin M_in2 = q1_out; end
        5'b1xx01: begin M_in2 = A_buf;  end
        5'b1xx10: begin M_in2 = M_buf;  end
        5'b1xx11: begin M_in2 = S_buf;  end
        default : begin M_in2 = q2_out; end
    endcase
end

// output of FUs
always@(*)
begin//: Q1_IN
    casex( {A_sel[0]&~A_sel[1], M_sel[0]&~M_sel[1], S_sel[0]&~S_sel[1]} )
        3'b1xx: begin q1_in = A_out; end
        3'b01x: begin q1_in = M_out; end
        3'b001: begin q1_in = S_out; end
        default: begin q1_in = A_out; end
    endcase
end

always@(*)
begin//: Q2_IN
    casex( {A_sel[0]&A_sel[1], M_sel[0]&M_sel[1], S_sel[0]&S_sel[1]} )
        3'b1xx: begin q2_in = A_out; end
        3'b01x: begin q2_in = M_out; end
        3'b001: begin q2_in = S_out; end
        default: begin q2_in = A_out; end
    endcase
end


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
        mem[head] <= data_in;
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
