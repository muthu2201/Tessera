`timescale 1ns/1ps
module tb_tessera_vec_system;
localparam N=4,OW=3,TW=8,DW=16,CW=2,D=4; logic clk=0,rst_n=0,completion_valid,completion_ready=1; logic [N-1:0] req=0,grant; logic [N*OW-1:0] op_bus=0; logic [N*TW-1:0] tag_bus=0; logic [N*DW-1:0] operand_a_bus=0,operand_b_bus=0; logic [CW-1:0] completion_client; logic [TW-1:0] completion_tag; logic [1:0] completion_status; logic [DW-1:0] completion_result; logic [$clog2(D+1)-1:0] completion_occupancy; integer i,timeout; always #5 clk=~clk; tessera_vec_system dut(.*); task tick; begin @(posedge clk); #1; end endtask
initial begin repeat(2) tick(); rst_n=1; tick(); for(i=0;i<N;i=i+1) begin op_bus[i*OW+:OW]=0; tag_bus[i*TW+:TW]=8'h30+i; operand_a_bus[i*DW+:DW]=i+10; operand_b_bus[i*DW+:DW]=i+20; end
// One outstanding request at a time isolates result-path correctness. The
// dispatcher arbitration policy is covered by its own multi-client test.
for(i=0;i<N;i=i+1) begin @(negedge clk); req=(1'b1<<i); timeout=0; while(grant==0 && timeout<20) begin tick(); timeout=timeout+1; end if(grant!==(1'b1<<i)) $fatal(1,"wrong client grant"); tick(); req=0; timeout=0; while(!completion_valid && timeout<30) begin tick(); timeout=timeout+1; end if(!completion_valid) $fatal(1,"completion timeout"); #1; if(completion_client!==i[CW-1:0]) $fatal(1,"client mismatch expected %0d got %0d",i,completion_client); if(completion_tag!==(8'h30+i)) $fatal(1,"tag mismatch"); if(completion_result!==(30+2*i)) $fatal(1,"real add result mismatch got=%0d",completion_result); if(completion_status!==0) $fatal(1,"status mismatch"); tick(); end
// Reset between the basic arithmetic cases and the dependency/backpressure case.
// This isolates scoreboard state and makes the duplicate-tag assertion deterministic.
req=0; completion_ready=1; rst_n=0; repeat(2) tick(); rst_n=1; tick();
// Hold the first completion at the output. Reusing its live tag must stall.
completion_ready=0; @(negedge clk); req=4'b0001; tag_bus[0+:TW]=8'h55; operand_a_bus[0+:DW]=16'd1; operand_b_bus[0+:DW]=16'd2; timeout=0; #1; if(grant!==4'b0001) $fatal(1,"first dependency-tag request not accepted"); tick(); req=0; timeout=0; while(!completion_valid && timeout<20) begin tick(); timeout=timeout+1; end if(!completion_valid) $fatal(1,"held completion missing"); @(negedge clk); req=4'b0001; timeout=0; repeat(5) begin tick(); if(grant!=0) $fatal(1,"duplicate live tag was dispatched"); end
// Consuming the first completion releases the tag; the waiting request can run.
completion_ready=1; timeout=0; #1; if(grant!==4'b0001) $fatal(1,"tag was not released after completion"); tick(); req=0; timeout=0; while(!completion_valid && timeout<20) begin tick(); timeout=timeout+1; end if(!completion_valid||completion_tag!==8'h55||completion_result!==3) $fatal(1,"reissued tag result mismatch"); tick();
$display("PASS: vector execution, tagged completions, duplicate-tag dependency stall/release"); $finish; end
endmodule
