`timescale 1ns/1ps
// Integrated Tessera command path: round-robin requester arbitration followed
// by a bounded command FIFO. A grant means the command entered the FIFO.
module tessera_command_path #(
  parameter integer N_CLIENTS = 4,
  parameter integer OP_W = 3,
  parameter integer TAG_W = 8,
  parameter integer FIFO_DEPTH = 4,
  parameter integer CLIENT_W = (N_CLIENTS <= 2) ? 1 : $clog2(N_CLIENTS),
  parameter integer CMD_W = CLIENT_W + OP_W + TAG_W
) (
  input logic clk,
  input logic rst_n,
  input logic [N_CLIENTS-1:0] req,
  input logic [N_CLIENTS*OP_W-1:0] op_bus,
  input logic [N_CLIENTS*TAG_W-1:0] tag_bus,
  output logic [N_CLIENTS-1:0] grant,
  output logic cmd_valid,
  output logic [CLIENT_W-1:0] cmd_client,
  output logic [OP_W-1:0] cmd_op,
  output logic [TAG_W-1:0] cmd_tag,
  input logic out_ready,
  output logic [ $clog2(FIFO_DEPTH+1)-1:0] occupancy
);
  localparam integer COUNT_W = $clog2(FIFO_DEPTH + 1);
  logic dispatch_valid, fifo_in_ready;
  logic [CLIENT_W-1:0] dispatch_client;
  logic [OP_W-1:0] dispatch_op;
  logic [TAG_W-1:0] dispatch_tag;
  logic [CMD_W-1:0] fifo_in_data, fifo_out_data;

  assign fifo_in_data = {dispatch_client, dispatch_op, dispatch_tag};
  assign {cmd_client, cmd_op, cmd_tag} = fifo_out_data;

  tessera_dispatcher #(
    .N_CLIENTS(N_CLIENTS), .CLIENT_W(CLIENT_W), .OP_W(OP_W), .TAG_W(TAG_W)
  ) dispatcher (
    .clk(clk), .rst_n(rst_n), .req(req), .op_bus(op_bus), .tag_bus(tag_bus),
    .grant(grant), .cmd_valid(dispatch_valid), .cmd_ready(fifo_in_ready),
    .cmd_client(dispatch_client), .cmd_op(dispatch_op), .cmd_tag(dispatch_tag)
  );

  tessera_command_fifo #(.WIDTH(CMD_W), .DEPTH(FIFO_DEPTH)) command_fifo (
    .clk(clk), .rst_n(rst_n), .in_valid(dispatch_valid),
    .in_ready(fifo_in_ready), .in_data(fifo_in_data),
    .out_valid(cmd_valid), .out_ready(out_ready), .out_data(fifo_out_data),
    .occupancy(occupancy)
  );
endmodule
