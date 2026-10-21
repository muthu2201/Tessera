`timescale 1ns/1ps
// Small synchronous FIFO for packed Tessera tile commands.
// Ready/valid semantics: input is accepted on in_valid && in_ready;
// output is consumed on out_valid && out_ready.
module tessera_command_fifo #(
  parameter integer WIDTH = 16,
  parameter integer DEPTH = 4,
  parameter integer PTR_W = (DEPTH <= 2) ? 1 : $clog2(DEPTH),
  parameter integer COUNT_W = $clog2(DEPTH + 1)
) (
  input  logic clk,
  input  logic rst_n,
  input  logic in_valid,
  output logic in_ready,
  input  logic [WIDTH-1:0] in_data,
  output logic out_valid,
  input  logic out_ready,
  output logic [WIDTH-1:0] out_data,
  output logic [COUNT_W-1:0] occupancy
);
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [PTR_W-1:0] wr_ptr, rd_ptr;
  logic push, pop;

  always @* begin
    in_ready = (occupancy < DEPTH);
    out_valid = (occupancy != 0);
    out_data = mem[rd_ptr];
    push = in_valid && in_ready;
    pop = out_valid && out_ready;
  end

  function automatic [PTR_W-1:0] next_ptr(input [PTR_W-1:0] ptr);
    if (ptr == DEPTH-1) next_ptr = '0;
    else next_ptr = ptr + 1'b1;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      occupancy <= '0;
    end else begin
      if (push) begin
        mem[wr_ptr] <= in_data;
        wr_ptr <= next_ptr(wr_ptr);
      end
      if (pop) rd_ptr <= next_ptr(rd_ptr);
      case ({push, pop})
        2'b10: occupancy <= occupancy + 1'b1;
        2'b01: occupancy <= occupancy - 1'b1;
        default: occupancy <= occupancy;
      endcase
    end
  end
endmodule
