`timescale 1ns/1ps
module tb_tessera_control_plane;
  localparam N=4, OW=3, TW=8, CW=2, DEPTH=4;
  logic clk=0,rst_n=0,completion_ready=0;
  logic [N-1:0] req=0,grant;
  logic [N*OW-1:0] op_bus=0;
  logic [N*TW-1:0] tag_bus=0;
  logic completion_valid;
  logic [CW-1:0] completion_client;
  logic [TW-1:0] completion_tag;
  logic [1:0] completion_status;
  logic [$clog2(DEPTH+1)-1:0] command_occupancy,completion_occupancy;
  logic busy;
  integer i, received;
  always #5 clk=~clk;
  tessera_control_plane #(.N_CLIENTS(N),.OP_W(OW),.TAG_W(TW),.FIFO_DEPTH(DEPTH),.LATENCY(3)) dut(.*);
  task tick; begin @(posedge clk); #1; end endtask
  task fail(input [8*100-1:0] msg); begin $display("FAIL: %0s",msg); $fatal(1); end endtask
  initial begin
    repeat(2) tick(); rst_n=1; tick();
    for(i=0;i<N;i=i+1) begin op_bus[i*OW +: OW]=i; tag_bus[i*TW +: TW]=8'h70+i; end
    req=4'b1111;
    // Let all four commands be accepted; then stop producing requests.
    repeat(4) tick();
    req=0;
    // Completion output is stalled first to exercise completion backpressure.
    repeat(12) tick();
    if(!completion_valid || completion_occupancy==0) fail("expected held completion under backpressure");
    completion_ready=1; received=0;
    for(i=0;i<4;i=i+1) begin
      // Wait for each completion without assuming exact scheduling cycle.
      while(!completion_valid) tick();
      #1;
      if(completion_client!==i[CW-1:0]) fail("end-to-end completion client order mismatch");
      if(completion_tag!==(8'h70+i)) fail("end-to-end completion tag mismatch");
      if(completion_status!==0) fail("execution stub should return success status");
      received=received+1; tick();
    end
    #1;
    if(received!=4 || completion_valid) fail("end-to-end completion count mismatch");
    $display("PASS: end-to-end request, queue, execution stub, and tagged completion flow");
    $finish;
  end
endmodule
