`timescale 1ns/1ps
module tb_tessera_command_path;
  localparam N=4, OW=3, TW=8, CW=2, DEPTH=4;
  logic clk=0, rst_n=0, out_ready=0;
  logic [N-1:0] req=0, grant;
  logic [N*OW-1:0] op_bus=0;
  logic [N*TW-1:0] tag_bus=0;
  logic cmd_valid;
  logic [CW-1:0] cmd_client;
  logic [OW-1:0] cmd_op;
  logic [TW-1:0] cmd_tag;
  logic [$clog2(DEPTH+1)-1:0] occupancy;
  integer i;
  always #5 clk=~clk;
  tessera_command_path #(.N_CLIENTS(N),.OP_W(OW),.TAG_W(TW),.FIFO_DEPTH(DEPTH)) dut(.*);
  task tick; begin @(posedge clk); #1; end endtask
  task fail(input [8*100-1:0] msg); begin $display("FAIL: %0s",msg); $fatal(1); end endtask
  initial begin
    repeat(2) tick(); rst_n=1; tick();
    req=4'b1111; out_ready=0;
    for(i=0;i<N;i=i+1) begin
      op_bus[i*OW +: OW]=i;
      tag_bus[i*TW +: TW]=8'hA0+i;
    end
    for(i=0;i<DEPTH;i=i+1) begin
      @(negedge clk);
      #1; if(grant==0) fail("expected command accepted while FIFO had space");
      tick();
    end
    @(negedge clk); #1;
    if(occupancy!=DEPTH || grant!=0) fail("full FIFO must backpressure dispatcher");
    tick();
    // Drain and validate packed command fields in round-robin order.
    @(negedge clk); out_ready=1;
    for(i=0;i<DEPTH;i=i+1) begin
      #1;
      if(!cmd_valid) fail("expected queued command while draining");
      if(cmd_client !== i[CW-1:0]) fail("round-robin client order lost in FIFO");
      if(cmd_op !== i[OW-1:0]) fail("queued op field mismatch");
      if(cmd_tag !== (8'hA0+i)) fail("queued tag field mismatch");
      tick();
    end
    #1; if(occupancy!=0 || cmd_valid) fail("FIFO did not drain");
    $display("PASS: integrated dispatcher-to-FIFO path and backpressure");
    $finish;
  end
endmodule
