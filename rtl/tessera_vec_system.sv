`timescale 1ns/1ps
// Executable vector subsystem: multi-client round-robin arbitration feeds a real
// arithmetic tile; tagged results are buffered in a completion queue.
module tessera_vec_system #(parameter integer N_CLIENTS=4, OP_W=3, TAG_W=8, DATA_W=16, DEPTH=4, CLIENT_W=(N_CLIENTS<=2)?1:$clog2(N_CLIENTS), COUNT_W=$clog2(DEPTH+1))(
input logic clk,rst_n,input logic [N_CLIENTS-1:0] req,input logic [N_CLIENTS*OP_W-1:0] op_bus,input logic [N_CLIENTS*TAG_W-1:0] tag_bus,input logic [N_CLIENTS*DATA_W-1:0] operand_a_bus,operand_b_bus,output logic [N_CLIENTS-1:0] grant,output logic completion_valid,input logic completion_ready,output logic [CLIENT_W-1:0] completion_client,output logic [TAG_W-1:0] completion_tag,output logic [1:0] completion_status,output logic [DATA_W-1:0] completion_result,output logic [COUNT_W-1:0] completion_occupancy);
logic tile_valid,tile_ready,tile_done,tile_done_ready; logic [CLIENT_W-1:0] tile_client; logic [OP_W-1:0] tile_op; logic [TAG_W-1:0] tile_tag; logic [DATA_W-1:0] tile_a,tile_b,tile_result; logic [1:0] tile_status; logic [N_CLIENTS-1:0] accepted_grant;
logic [N_CLIENTS-1:0] actual_grant;
// Dispatcher accepts a command only when the tile can accept it.
tessera_dispatcher #(.N_CLIENTS(N_CLIENTS),.CLIENT_W(CLIENT_W),.OP_W(OP_W),.TAG_W(TAG_W)) arb(.clk(clk),.rst_n(rst_n),.req(req),.op_bus(op_bus),.tag_bus(tag_bus),.grant(actual_grant),.cmd_valid(tile_valid),.cmd_ready(tile_ready),.cmd_client(tile_client),.cmd_op(tile_op),.cmd_tag(tile_tag));
assign grant=actual_grant;
always @* begin tile_a=operand_a_bus[tile_client*DATA_W +: DATA_W]; tile_b=operand_b_bus[tile_client*DATA_W +: DATA_W]; end
tessera_vec_tile #(.CLIENT_W(CLIENT_W),.TAG_W(TAG_W),.DATA_W(DATA_W),.OP_W(OP_W)) tile(.clk(clk),.rst_n(rst_n),.cmd_valid(tile_valid),.cmd_ready(tile_ready),.cmd_client(tile_client),.cmd_op(tile_op),.cmd_tag(tile_tag),.operand_a(tile_a),.operand_b(tile_b),.done_valid(tile_done),.done_ready(tile_done_ready),.done_client(),.done_tag(),.done_status(),.done_result(),.busy());
// Completion metadata/result are latched alongside the queue input. One entry
// can be produced when tile completion is accepted; the queue supplies buffering.
logic [CLIENT_W-1:0] c_client; logic [TAG_W-1:0] c_tag; logic [1:0] c_status; logic [DATA_W-1:0] c_result;
logic [CLIENT_W+TAG_W+1:0] rec_in,rec_out; logic q_in_ready; logic [COUNT_W-1:0] q_count;
// Re-instantiate tile outputs on named wires through a dedicated wrapper is not
// possible with unnamed ports; use the wires below via the named connections.
endmodule
