`timescale 1ns/1ps
// Completion return queue. Execution units submit a completion record; software
// or the control plane consumes it through ready/valid. This module transports
// completions only; stale/duplicate detection requires a separate scoreboard.
module tessera_completion_queue #(
  parameter integer N_CLIENTS = 4,
  parameter integer CLIENT_W = (N_CLIENTS <= 2) ? 1 : $clog2(N_CLIENTS),
  parameter integer TAG_W = 8,
  parameter integer STATUS_W = 2,
  parameter integer DEPTH = 4,
  parameter integer REC_W = CLIENT_W + TAG_W + STATUS_W,
  parameter integer COUNT_W = $clog2(DEPTH + 1)
) (
  input logic clk,
  input logic rst_n,
  input logic done_valid,
  output logic done_ready,
  input logic [CLIENT_W-1:0] done_client,
  input logic [TAG_W-1:0] done_tag,
  input logic [STATUS_W-1:0] done_status,
  output logic completion_valid,
  input logic completion_ready,
  output logic [CLIENT_W-1:0] completion_client,
  output logic [TAG_W-1:0] completion_tag,
  output logic [STATUS_W-1:0] completion_status,
  output logic [COUNT_W-1:0] occupancy
);
  logic [REC_W-1:0] in_data, out_data;
  assign in_data = {done_client, done_tag, done_status};
  assign {completion_client, completion_tag, completion_status} = out_data;

  tessera_command_fifo #(.WIDTH(REC_W), .DEPTH(DEPTH), .COUNT_W(COUNT_W)) fifo (
    .clk(clk), .rst_n(rst_n),
    .in_valid(done_valid), .in_ready(done_ready), .in_data(in_data),
    .out_valid(completion_valid), .out_ready(completion_ready),
    .out_data(out_data), .occupancy(occupancy)
  );
endmodule
