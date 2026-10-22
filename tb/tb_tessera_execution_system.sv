`timescale 1ns/1ps
module tb_tessera_execution_system;
  localparam N=4, OW=3, TW=8, DW=16, AW=32, CW=2, D=4;
  logic clk=0, rst_n=0, completion_valid, completion_ready=1;
  logic [N-1:0] req=0, grant, unit_select_bus=0;
  logic [N*OW-1:0] op_bus=0;
  logic [N*TW-1:0] tag_bus=0;
  logic [N*DW-1:0] operand_a_bus=0, operand_b_bus=0;
  logic [N*AW-1:0] accumulator_bus=0;
  logic [CW-1:0] completion_client;
  logic [TW-1:0] completion_tag;
  logic [1:0] completion_status;
  logic [AW-1:0] completion_result;
  logic [$clog2(D+1)-1:0] completion_occupancy;
  integer timeout;
  logic seen0, seen1;
  always #5 clk=~clk;
  tessera_execution_system dut(.*);
  task tick; begin @(posedge clk); #1; end endtask
  task wait_completion;
    input integer limit;
    begin
      timeout=0;
      while(!completion_valid && timeout<limit) begin tick(); timeout=timeout+1; end
      if(!completion_valid) $fatal(1,"completion timeout");
    end
  endtask
  initial begin
    repeat(2) tick(); rst_n=1; tick();

    // Baseline vector addition.
    op_bus[0+:OW]=0; tag_bus[0+:TW]=8'h11;
    operand_a_bus[0+:DW]=10; operand_b_bus[0+:DW]=20;
    @(negedge clk); req=1; #1;
    if(grant!==1) $fatal(1,"vector grant");
    tick(); req=0; wait_completion(20);
    if(completion_client!==0 || completion_tag!==8'h11 ||
       completion_result!==30 || completion_status!==0) $fatal(1,"vector result");
    tick();

    // Baseline tensor MAC.
    unit_select_bus[1]=1; op_bus[OW+:OW]=1; tag_bus[TW+:TW]=8'h22;
    operand_a_bus[DW+:DW]=3; operand_b_bus[DW+:DW]=4;
    accumulator_bus[AW+:AW]=5;
    @(negedge clk); req=2; #1;
    if(grant!==2) $fatal(1,"tensor grant");
    tick(); req=0; wait_completion(20);
    if(completion_client!==1 || completion_tag!==8'h22 ||
       completion_result!==17 || completion_status!==0) $fatal(1,"tensor result");
    tick();

    // Simultaneous vector/tensor requests while the consumer is stalled.
    // Both engines may finish independently; neither result may be lost.
    completion_ready=0;
    op_bus[0+:OW]=0; tag_bus[0+:TW]=8'h31;
    operand_a_bus[0+:DW]=7; operand_b_bus[0+:DW]=8;
    op_bus[2*OW+:OW]=1; tag_bus[2*TW+:TW]=8'h32;
    unit_select_bus[2]=1;
    operand_a_bus[2*DW+:DW]=(-2); operand_b_bus[2*DW+:DW]=9;
    accumulator_bus[2*AW+:AW]=4;
    @(negedge clk); req=5;
    timeout=0; seen0=0; seen1=0;
    while((!seen0 || !seen1) && timeout<20) begin
      #1;
      if(grant[0]) seen0=1;
      if(grant[2]) seen1=1;
      tick();
      timeout=timeout+1;
    end
    if(!seen0 || !seen1) $fatal(1,"round-robin failed to accept concurrent clients");
    @(negedge clk); req=0;
    repeat(4) tick();
    if(completion_occupancy<2) $fatal(1,"backpressure lost a completion");
    completion_ready=1;
    seen0=0; seen1=0; timeout=0;
    while((!seen0 || !seen1) && timeout<20) begin
      if(completion_valid) begin
        if(completion_client==0 && completion_tag==8'h31) begin
          if(completion_result!==15 || completion_status!==0) $fatal(1,"stalled vector completion corrupt");
          seen0=1;
        end else if(completion_client==2 && completion_tag==8'h32) begin
          if(completion_result!==(-14) || completion_status!==0) $fatal(1,"signed tensor MAC corrupt");
          seen1=1;
        end else $fatal(1,"unexpected completion while draining");
      end
      tick(); timeout=timeout+1;
    end
    if(!seen0 || !seen1) $fatal(1,"completion missing after backpressure release");
    // A client/tag pair remains reserved until its completion is consumed.
    completion_ready=0;
    tag_bus[0+:TW]=8'h41; operand_a_bus[0+:DW]=6; operand_b_bus[0+:DW]=7;
    @(negedge clk); req=1; #1;
    if(grant!==1) $fatal(1,"initial tag reservation command not accepted");
    tick(); req=0; wait_completion(20);
    @(negedge clk); req=1; #1;
    if(grant!==0) $fatal(1,"duplicate live tag was accepted");
    repeat(2) begin tick(); #1; if(grant!==0) $fatal(1,"duplicate tag escaped while completion stalled"); end
    req=0; completion_ready=1; tick();
    // The old completion is now consumed, so the same tag may be reused.
    @(negedge clk); req=1; #1;
    if(grant!==1) $fatal(1,"tag was not released after completion consumption");
    tick(); req=0; wait_completion(20);
    if(completion_client!==0 || completion_tag!==8'h41 ||
       completion_result!==13 || completion_status!==0) $fatal(1,"reused tag result corrupt");
    tick();

    // Unsupported vector opcode must return a tagged error completion.
    op_bus[0+:OW]=7; tag_bus[0+:TW]=8'h51;
    @(negedge clk); req=1; #1;
    if(grant!==1) $fatal(1,"invalid vector opcode was not accepted for error reporting");
    tick(); req=0; wait_completion(20);
    if(completion_client!==0 || completion_tag!==8'h51 ||
       completion_status!==1 || completion_result!==0)
      $fatal(1,"invalid vector opcode did not return the expected error");
    tick();

    // Unsupported tensor opcode must also return a tagged error completion.
    unit_select_bus[1]=1; op_bus[OW+:OW]=2; tag_bus[TW+:TW]=8'h52;
    @(negedge clk); req=2; #1;
    if(grant!==2) $fatal(1,"invalid tensor opcode was not accepted for error reporting");
    tick(); req=0; wait_completion(20);
    if(completion_client!==1 || completion_tag!==8'h52 ||
       completion_status!==1 || completion_result!==0)
      $fatal(1,"invalid tensor opcode did not return the expected error");
    tick();
    $display("PASS shared routing, concurrent clients, signed MAC, backpressure, live-tag reuse, and invalid-op errors");
    $finish;
  end
endmodule
