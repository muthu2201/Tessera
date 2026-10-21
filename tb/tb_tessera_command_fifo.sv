`timescale 1ns/1ps
module tb_tessera_command_fifo;
  localparam WIDTH=16, DEPTH=4, COUNT_W=3;
  logic clk=0, rst_n=0, in_valid=0, in_ready, out_valid, out_ready=0;
  logic [WIDTH-1:0] in_data=0, out_data;
  logic [COUNT_W-1:0] occupancy;
  integer i, cycle, seed, q_count, q_wr, q_rd, do_push, do_pop;
  logic [WIDTH-1:0] model_mem [0:4095];
  always #5 clk=~clk;
  tessera_command_fifo #(.WIDTH(WIDTH),.DEPTH(DEPTH)) dut(.*);
  task tick; begin @(posedge clk); #1; end endtask
  task fail(input [8*100-1:0] msg); begin $display("FAIL: %0s",msg); $fatal(1); end endtask
  initial begin
    repeat(2) tick(); rst_n=1; tick();
    if (occupancy!=0 || out_valid || !in_ready) fail("reset/empty state invalid");

    // Fill to capacity; fifth write must be backpressured.
    for(i=0;i<DEPTH;i=i+1) begin
      @(negedge clk); in_valid=1; in_data=16'h1000+i; out_ready=0;
      #1; if(!in_ready) fail("FIFO filled before DEPTH writes");
      tick();
    end
    @(negedge clk); in_data=16'hFFFF; #1;
    if(in_ready || occupancy!=DEPTH || !out_valid) fail("full/backpressure check failed");
    tick(); if(occupancy!=DEPTH) fail("overflow changed occupancy");

    // Drain and check strict FIFO ordering.
    @(negedge clk); in_valid=0; out_ready=1;
    for(i=0;i<DEPTH;i=i+1) begin
      #1; if(!out_valid || out_data !== (16'h1000+i)) fail("FIFO ordering/data mismatch");
      tick();
    end
    #1; if(out_valid || occupancy!=0) fail("FIFO did not return to empty");

    // Simultaneous push/pop preserves occupancy and advances data stream.
    @(negedge clk); in_valid=1; in_data=16'hCAFE; out_ready=0; tick();
    @(negedge clk); in_data=16'hBABE; out_ready=1; #1;
    if(out_data!==16'hCAFE) fail("simultaneous push/pop initial head mismatch");
    tick(); #1;
    if(occupancy!=1 || out_data!==16'hBABE) fail("simultaneous push/pop state mismatch");
    @(negedge clk); in_valid=0; out_ready=1; tick();
    #1; if(occupancy!=0) fail("final drain failed");

    // Deterministic randomized stress with a software reference queue.
    @(negedge clk); rst_n=0; in_valid=0; out_ready=0; tick();
    @(negedge clk); rst_n=1; q_count=0; q_wr=0; q_rd=0; seed=32'h2A771E5;
    for(cycle=0;cycle<1000;cycle=cycle+1) begin
      @(negedge clk);
      in_valid = (($random(seed) & 3) != 0);
      out_ready = (($random(seed) & 3) != 0);
      in_data = $random(seed);
      #1;
      if (occupancy !== q_count) fail("random stress occupancy diverged from model");
      if (out_valid !== (q_count != 0)) fail("random stress valid diverged from model");
      if (q_count != 0 && out_data !== model_mem[q_rd]) fail("random stress FIFO order/data mismatch");
      do_pop = out_valid && out_ready;
      do_push = in_valid && in_ready;
      if (do_pop) begin
        q_rd = (q_rd + 1) % 4096;
        q_count = q_count - 1;
      end
      if (do_push) begin
        model_mem[q_wr] = in_data;
        q_wr = (q_wr + 1) % 4096;
        q_count = q_count + 1;
      end
      tick();
    end
    @(negedge clk); in_valid=0; out_ready=1;
    while(q_count > 0) begin
      #1;
      if(!out_valid || out_data !== model_mem[q_rd]) fail("random stress final drain mismatch");
      tick();
      q_rd=(q_rd+1)%4096; q_count=q_count-1;
    end
    #1; if(occupancy!=0 || out_valid) fail("random stress failed to drain");

    $display("PASS: FIFO directed tests + 1000-cycle randomized reference-model stress");
    $finish;
  end
endmodule
