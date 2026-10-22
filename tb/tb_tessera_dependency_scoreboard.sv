`timescale 1ns/1ps
module tb_tessera_dependency_scoreboard;
  localparam N=4, DEPTH=2, TOTAL=N*DEPTH;
  logic clk=0, rst_n=0, alloc_valid=0, alloc_ready;
  logic complete_valid=0, complete_known, duplicate_alloc, unknown_completion;
  logic [1:0] alloc_client=0, complete_client=0;
  logic [7:0] alloc_tag=0, complete_tag=0;
  logic [TOTAL-1:0] live_bitmap;
  logic [$clog2(TOTAL+1)-1:0] live_count;
  always #5 clk=~clk;
  tessera_dependency_scoreboard #(.N_CLIENTS(N),.TAG_W(8),.CLIENT_W(2),.DEPTH(DEPTH)) dut(.*);

  task allocate(input logic [1:0] client, input logic [7:0] tag);
    begin
      @(negedge clk); alloc_valid=1; alloc_client=client; alloc_tag=tag; #1;
      if(!alloc_ready) $fatal(1,"expected allocation ready for client %0d tag %h",client,tag);
      @(posedge clk); #1; alloc_valid=0;
    end
  endtask

  task complete(input logic [1:0] client, input logic [7:0] tag);
    begin
      @(negedge clk); complete_valid=1; complete_client=client; complete_tag=tag; #1;
      if(!complete_known) $fatal(1,"expected known completion for client %0d tag %h",client,tag);
      @(posedge clk); #1; complete_valid=0;
    end
  endtask

  initial begin
    repeat(2) @(posedge clk); #1 rst_n=1;
    // Tags are scoped per client, so identical tags from different clients coexist.
    allocate(1,8'h22);
    allocate(2,8'h22);
    if(live_count!=2) $fatal(1,"same tag on distinct clients was not tracked independently");

    // Unknown completions must not release either live reservation.
    @(negedge clk); complete_valid=1; complete_client=3; complete_tag=8'hEE; #1;
    if(!unknown_completion || complete_known) $fatal(1,"unknown completion was not flagged");
    @(posedge clk); #1; complete_valid=0;
    if(live_count!=2) $fatal(1,"unknown completion changed live count");

    complete(1,8'h22);
    // alloc_ready depends on the candidate client/tag even when alloc_valid is low.
    // Probe an unused tag to verify the freed capacity rather than the still-live tag.
    alloc_client=1; alloc_tag=8'h23; #1;
    if(live_count!=1 || !alloc_ready) $fatal(1,"known completion failed to free a slot");
    allocate(1,8'h22);
    @(negedge clk); alloc_valid=1; alloc_client=2; alloc_tag=8'h22; #1;
    if(!duplicate_alloc || alloc_ready) $fatal(1,"live duplicate tag was accepted");
    @(posedge clk); #1; alloc_valid=0;

    // Two client reservations are already live, so add six to fill all eight slots.
    allocate(0,8'h01);
    allocate(0,8'h02);
    allocate(0,8'h03);
    allocate(0,8'h04);
    allocate(0,8'h05);
    allocate(0,8'h06);
    if(live_count!=TOTAL) $fatal(1,"scoreboard did not reach full capacity");
    @(negedge clk); alloc_valid=1; alloc_client=3; alloc_tag=8'h99; #1;
    if(alloc_ready) $fatal(1,"allocation accepted while scoreboard full");
    @(posedge clk); #1; alloc_valid=0;

    complete(0,8'h01);
    allocate(3,8'h99);
    if(live_count!=TOTAL) $fatal(1,"freed scoreboard slot was not reusable");

    // Drain all known live tags and check accounting returns to zero.
    complete(2,8'h22);
    complete(1,8'h22);
    complete(0,8'h02);
    complete(0,8'h03);
    complete(0,8'h04);
    complete(0,8'h05);
    complete(0,8'h06);
    complete(3,8'h99);
    if(live_count!=0 || live_bitmap!='0) $fatal(1,"scoreboard failed to drain cleanly");
    $display("PASS scoreboard: client-scoped tags, unknown completions, duplicate blocking, full-capacity backpressure, slot reuse");
    $finish;
  end
endmodule
