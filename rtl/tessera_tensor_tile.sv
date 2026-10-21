`timescale 1ns/1ps
// Synthesizable signed 16x16 multiply-accumulate tile. op 0: A*B; op 1: accumulator + A*B.
module tessera_tensor_tile #(parameter integer CLIENT_W=2,TAG_W=8,DATA_W=16,ACC_W=32,OP_W=3)(input logic clk,rst_n,input logic cmd_valid,output logic cmd_ready,input logic [CLIENT_W-1:0] cmd_client,input logic [OP_W-1:0] cmd_op,input logic [TAG_W-1:0] cmd_tag,input logic signed [DATA_W-1:0] operand_a,operand_b,input logic signed [ACC_W-1:0] accumulator,output logic done_valid,input logic done_ready,output logic [CLIENT_W-1:0] done_client,output logic [TAG_W-1:0] done_tag,output logic [1:0] done_status,output logic signed [ACC_W-1:0] done_result,output logic busy);
logic signed [2*DATA_W-1:0] product; logic signed [ACC_W-1:0] calc; logic [1:0] status_calc;
always @* begin product=operand_a*operand_b; calc={{(ACC_W-2*DATA_W){product[2*DATA_W-1]}},product}; status_calc=0; case(cmd_op) 0: calc={{(ACC_W-2*DATA_W){product[2*DATA_W-1]}},product}; 1: calc=accumulator+{{(ACC_W-2*DATA_W){product[2*DATA_W-1]}},product}; default: begin calc='0; status_calc=1; end endcase end
assign busy=done_valid; assign cmd_ready=(!done_valid)||done_ready;
always_ff @(posedge clk or negedge rst_n) begin if(!rst_n) begin done_valid<=0; done_client<='0; done_tag<='0; done_status<='0; done_result<='0; end else begin if(done_valid&&done_ready) done_valid<=0; if(cmd_valid&&cmd_ready) begin done_valid<=1; done_client<=cmd_client; done_tag<=cmd_tag; done_status<=status_calc; done_result<=calc; end end end
endmodule
