`timescale 1ns/1ps
module tb_tessera_completion_queue;
  localparam N=4, CW=2, TW=8, SW=2, DEPTH=4;
  logic clk=0, rst_n=0, done_valid=0, done_ready;
  logic [CW-1:0] done_client=0, completion_client;
  logic [TW-1:0] done_tag=0, completion_tag;
  logic [SW-1:0] done_status=0, completion_status;
  logic completion_valid, completion_ready=0;
  logic [$clog2(DEPTH+1)-1:0] occupancy;
  integer i;
  always #5 clk=~clk;
  tessera_completion_queue #(.N_CLIENTS(N),.TAG_W(TW),.STATUS_W(SW),.DEPTH(DEPTH)) dut(.*);
  task tick; begin @(posedge clk); #1; end endtask
  task fail(input [8*100-1:0] msg); begin $display("FAIL: %0s",msg); $fatal(1); end endtask
  initial begin
    repeat(2) tick(); rst_n=1; tick();
    for(i=0;i<DEPTH;i=i+1) begin
      @(negedge clk); done_valid=1; done_client=i; done_tag=8'h40+i; done_status=i%3;
      #1; if(!done_ready) fail("completion queue filled early");
      tick();
    end
    @(negedge clk); #1;
    if(done_ready || occupancy!=DEPTH) fail("completion queue full/backpressure failed");
    done_valid=0; completion_ready=1;
    for(i=0;i<DEPTH;i=i+1) begin
      #1;
      if(!completion_valid) fail("completion missing");
      if(completion_client!==i[CW-1:0] || completion_tag!==(8'h40+i) || completion_status!==(i%3))
        fail("completion record corrupted or reordered");
      tick();
    end
    #1; if(completion_valid || occupancy!=0) fail("completion queue did not drain");
    $display("PASS: completion queue preserves client, tag, status, ordering, and backpressure");
    $finish;
  end
endmodule
