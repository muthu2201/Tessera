`timescale 1ns/1ps
// Tessera v0 dispatcher: round-robin arbitration among typed tile requesters.
// One command can be accepted per cycle. A requester holds req and payload
// stable until grant; grant is a one-cycle acceptance pulse.
module tessera_dispatcher #(
  parameter integer N_CLIENTS = 4,
  parameter integer CLIENT_W = (N_CLIENTS <= 2) ? 1 : $clog2(N_CLIENTS),
  parameter integer OP_W = 3,
  parameter integer TAG_W = 8
) (
  input  logic clk,
  input  logic rst_n,
  input  logic [N_CLIENTS-1:0] req,
  input  logic [N_CLIENTS*OP_W-1:0] op_bus,
  input  logic [N_CLIENTS*TAG_W-1:0] tag_bus,
  output logic [N_CLIENTS-1:0] grant,
  output logic cmd_valid,
  input  logic cmd_ready,
  output logic [CLIENT_W-1:0] cmd_client,
  output logic [OP_W-1:0] cmd_op,
  output logic [TAG_W-1:0] cmd_tag
);
  logic [CLIENT_W-1:0] rr_ptr;
  logic found;
  integer offset;
  integer idx;
  integer chosen;

  // Use Verilog-2005 combinational sensitivity syntax for broader simulator
  // compatibility; this also avoids an Icarus constant-select warning.
  always @* begin
    found = 1'b0;
    chosen = 0;
    idx = 0;
    for (offset = 0; offset < N_CLIENTS; offset = offset + 1) begin
      idx = rr_ptr + offset;
      if (idx >= N_CLIENTS) idx = idx - N_CLIENTS;
      if (!found && req[idx]) begin
        found = 1'b1;
        chosen = idx;
      end
    end

    grant = '0;
    cmd_valid = found;
    cmd_client = chosen[CLIENT_W-1:0];
    cmd_op = op_bus[chosen*OP_W +: OP_W];
    cmd_tag = tag_bus[chosen*TAG_W +: TAG_W];
    if (found && cmd_ready) grant[chosen] = 1'b1;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr_ptr <= '0;
    end else if (cmd_valid && cmd_ready) begin
      if (cmd_client == N_CLIENTS-1) rr_ptr <= '0;
      else rr_ptr <= cmd_client + 1'b1;
    end
  end
endmodule
