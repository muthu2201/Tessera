`timescale 1ns/1ps
module tb_tessera_dependency_scoreboard;
logic clk=0,rst_n=0,alloc_valid=0,alloc_ready,complete_valid=0,complete_known,duplicate_alloc,unknown_completion;
logic [1:0] alloc_client=0,complete_client=0; logic [7:0] alloc_tag=0,complete_tag=0; logic [63:0] live_bitmap; logic [6:0] live_count;
always #5 clk=~clk;
tessera_dependency_scoreboard dut(.*);
initial begin repeat(2) @(posedge clk); #1 rst_n=1; @(negedge clk); alloc_valid=1; alloc_client=1; alloc_tag=8'h22; @(posedge clk); #1 alloc_valid=0; if(live_count!=1) $fatal(1,"allocation failed"); alloc_valid=1; #1; if(!duplicate_alloc||alloc_ready) $fatal(1,"duplicate accepted"); @(posedge clk); #1 alloc_valid=0; complete_valid=1; complete_client=2; complete_tag=8'h33; #1; if(!unknown_completion||complete_known) $fatal(1,"unknown completion"); @(posedge clk); #1 complete_client=1; complete_tag=8'h22; #1; if(!complete_known||unknown_completion) $fatal(1,"known completion"); @(posedge clk); #1 complete_valid=0; if(live_count!=0) $fatal(1,"count not cleared"); $display("PASS dependency scoreboard"); $finish; end
endmodule
