`timescale 1ns/1ps
// End-to-end control-plane prototype: requester arbitration -> command FIFO ->
// deterministic execution stub -> tagged completion FIFO. The execution stub
// is for protocol validation only; it is not a compute tile.
module tessera_control_plane #(
  parameter integer N_CLIENTS=4, OP_W=3, TAG_W=8, FIFO_DEPTH=4,
  parameter integer CLIENT_W=(N_CLIENTS<=2)?1:$clog2(N_CLIENTS),
  parameter integer COUNT_W=$clog2(FIFO_DEPTH+1),
  parameter integer LATENCY=3
)(
  input logic clk, rst_n,
  input logic [N_CLIENTS-1:0] req,
  input logic [N_CLIENTS*OP_W-1:0] op_bus,
  input logic [N_CLIENTS*TAG_W-1:0] tag_bus,
  output logic [N_CLIENTS-1:0] grant,
  output logic completion_valid,
  input logic completion_ready,
  output logic [CLIENT_W-1:0] completion_client,
  output logic [TAG_W-1:0] completion_tag,
  output logic [1:0] completion_status,
  output logic [COUNT_W-1:0] command_occupancy,
  output logic [COUNT_W-1:0] completion_occupancy,
  output logic busy
);
  logic cmd_valid, cmd_ready;
  logic [CLIENT_W-1:0] cmd_client;
  logic [OP_W-1:0] cmd_op;
  logic [TAG_W-1:0] cmd_tag;
  logic done_valid, done_ready;
  logic [CLIENT_W-1:0] done_client;
  logic [TAG_W-1:0] done_tag;
  logic [1:0] done_status;
  logic [$clog2(LATENCY+1)-1:0] cycles_left;

  tessera_command_path #(.N_CLIENTS(N_CLIENTS),.OP_W(OP_W),.TAG_W(TAG_W),.FIFO_DEPTH(FIFO_DEPTH)) commands(
    .clk(clk),.rst_n(rst_n),.req(req),.op_bus(op_bus),.tag_bus(tag_bus),
    .grant(grant),.cmd_valid(cmd_valid),.cmd_client(cmd_client),.cmd_op(cmd_op),
    .cmd_tag(cmd_tag),.out_ready(cmd_ready),.occupancy(command_occupancy)
  );

  // One-command execution stub. Completion is held stable under backpressure.
  assign busy = (cycles_left != 0);
  assign cmd_ready = !busy && !done_valid;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cycles_left <= '0;
      done_valid <= 1'b0;
      done_client <= '0;
      done_tag <= '0;
      done_status <= '0;
    end else begin
      if(done_valid && done_ready) done_valid <= 1'b0;
      if(cmd_valid && cmd_ready) begin
        done_client <= cmd_client;
        done_tag <= cmd_tag;
        // Status 0 = success. The opcode is carried but not executed here.
        done_status <= 2'b00;
        cycles_left <= LATENCY;
      end else if(cycles_left != 0) begin
        cycles_left <= cycles_left - 1'b1;
        if(cycles_left == 1) done_valid <= 1'b1;
      end
    end
  end

  tessera_completion_queue #(.N_CLIENTS(N_CLIENTS),.TAG_W(TAG_W),.STATUS_W(2),.DEPTH(FIFO_DEPTH)) completions(
    .clk(clk),.rst_n(rst_n),.done_valid(done_valid),.done_ready(done_ready),
    .done_client(done_client),.done_tag(done_tag),.done_status(done_status),
    .completion_valid(completion_valid),.completion_ready(completion_ready),
    .completion_client(completion_client),.completion_tag(completion_tag),
    .completion_status(completion_status),.occupancy(completion_occupancy)
  );
endmodule
