`timescale 1ns/1ps
module tb_tessera_dispatcher;
  localparam N=4, OW=3, TW=8, CW=2;
  logic clk=0, rst_n=0;
  logic [N-1:0] req;
  logic [N*OW-1:0] op_bus;
  logic [N*TW-1:0] tag_bus;
  logic [N-1:0] grant;
  logic cmd_valid, cmd_ready;
  logic [CW-1:0] cmd_client;
  logic [OW-1:0] cmd_op;
  logic [TW-1:0] cmd_tag;
  integer k;

  always #5 clk = ~clk;
  tessera_dispatcher #(.N_CLIENTS(N), .OP_W(OW), .TAG_W(TW)) dut (.*);

  task tick; begin @(posedge clk); #1; end endtask
  task fail(input [8*120-1:0] msg); begin $display("FAIL: %0s", msg); $fatal(1); end endtask

  initial begin
    req=0; op_bus=0; tag_bus=0; cmd_ready=0;
    repeat(2) tick(); rst_n=1; tick();

    // Empty queues: no command and no grant.
    #1; if (cmd_valid || grant != 0) fail("empty queues must remain idle");

    // Backpressure: valid command remains visible but no requester is granted.
    req=4'b0100; op_bus[2*OW +: OW]=3'd5; tag_bus[2*TW +: TW]=8'hA7;
    cmd_ready=0; #1;
    if (!cmd_valid || grant != 0 || cmd_client != 2 || cmd_op != 5 || cmd_tag != 8'hA7)
      fail("backpressure/payload check failed");
    tick(); if (dut.rr_ptr != 0) fail("round-robin pointer moved while stalled");

    // Accept the stalled command exactly once.
    cmd_ready=1; #1; if (grant != 4'b0100) fail("expected only client 2 grant");
    tick(); if (dut.rr_ptr != 3) fail("pointer did not advance after client 2");

    // All clients contend; after pointer 3, expected order is 3,0,1,2.
    req=4'b1111;
    for (k=0; k<N; k=k+1) begin
      #1;
      if (cmd_client !== ((3+k)%N)) fail("round-robin ordering failed");
      if (grant !== (1 << ((3+k)%N))) fail("grant must be one-hot");
      tick();
    end

    // No duplicate grant when ready is low, even under sustained requests.
    cmd_ready=0; #1;
    if (grant != 0 || !cmd_valid) fail("grant asserted during backpressure");
    tick(); if (grant != 0) fail("grant asserted during stalled cycle");

    $display("PASS: empty, payload, backpressure, one-hot grant, round-robin tests");
    $finish;
  end
endmodule
