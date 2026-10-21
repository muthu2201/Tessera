`timescale 1ns/1ps
module tb_tessera_command_fifo;
  localparam WIDTH=16, DEPTH=4, COUNT_W=3;
  logic clk=0, rst_n=0, in_valid=0, in_ready, out_valid, out_ready=0;
  logic [WIDTH-1:0] in_data=0, out_data;
  logic [COUNT_W-1:0] occupancy;
  integer i;
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

    $display("PASS: FIFO reset, full/empty, backpressure, order, simultaneous push/pop");
    $finish;
  end
endmodule
