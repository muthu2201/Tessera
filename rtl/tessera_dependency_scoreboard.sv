`timescale 1ns/1ps
// Live dependency tags are scoped by client. Duplicate allocations are rejected;
// unknown completions are flagged and do not alter the scoreboard.
module tessera_dependency_scoreboard #(parameter integer N_CLIENTS=4,TAG_W=8,CLIENT_W=(N_CLIENTS<=2)?1:$clog2(N_CLIENTS),DEPTH=16,TOTAL=N_CLIENTS*DEPTH,COUNT_W=$clog2(TOTAL+1))(input logic clk,rst_n,input logic alloc_valid,output logic alloc_ready,input logic [CLIENT_W-1:0] alloc_client,input logic [TAG_W-1:0] alloc_tag,input logic complete_valid,input logic [CLIENT_W-1:0] complete_client,input logic [TAG_W-1:0] complete_tag,output logic complete_known,output logic duplicate_alloc,output logic unknown_completion,output logic [TOTAL-1:0] live_bitmap,output logic [COUNT_W-1:0] live_count);
logic [TOTAL-1:0] live; logic [TAG_W-1:0] tags[0:TOTAL-1]; logic [CLIENT_W-1:0] clients[0:TOTAL-1]; integer free_slot,alloc_match_idx,done_match_idx;
always @* begin
  free_slot=-1; alloc_match_idx=-1; done_match_idx=-1;
  for(integer j=0;j<TOTAL;j=j+1) begin
    // A slot completing this cycle can be reused immediately at full capacity.
    if((!live[j] || (complete_valid && live[j] && clients[j]==complete_client && tags[j]==complete_tag)) && free_slot==-1) free_slot=j;
    if(live[j]&&clients[j]==alloc_client&&tags[j]==alloc_tag) alloc_match_idx=j;
    if(live[j]&&clients[j]==complete_client&&tags[j]==complete_tag) done_match_idx=j;
  end
end
assign alloc_ready=(alloc_match_idx==-1)&&(free_slot!=-1);
assign complete_known=(done_match_idx!=-1);
assign duplicate_alloc=alloc_valid&&(alloc_match_idx!=-1);
assign unknown_completion=complete_valid&&!complete_known;
assign live_bitmap=live;
always_ff @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    live<='0; live_count<='0;
    for(integer n=0;n<TOTAL;n=n+1) begin tags[n]<='0; clients[n]<='0; end
  end else begin
    // Clear first, then allocate. If a full-capacity slot turns over, the
    // later nonblocking assignment intentionally keeps the replacement live.
    if(complete_valid&&complete_known) live[done_match_idx]<=1'b0;
    if(alloc_valid&&alloc_ready) begin
      live[free_slot]<=1'b1; tags[free_slot]<=alloc_tag; clients[free_slot]<=alloc_client;
    end
    case ({alloc_valid&&alloc_ready,complete_valid&&complete_known})
      2'b10: live_count<=live_count+1'b1;
      2'b01: live_count<=live_count-1'b1;
      default: live_count<=live_count;
    endcase
  end
end
endmodule
