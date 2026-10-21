// Combinational safety properties for the Tessera dispatcher.
// Proves grant safety and payload selection for arbitrary inputs at each step.
module tessera_dispatcher_formal;
  localparam N=4, OW=3, TW=8, CW=2;
  (* anyseq *) reg clk;
  (* anyseq *) reg rst_n;
  (* anyseq *) reg [N-1:0] req;
  (* anyseq *) reg [N*OW-1:0] op_bus;
  (* anyseq *) reg [N*TW-1:0] tag_bus;
  (* anyseq *) reg cmd_ready;
  wire [N-1:0] grant;
  wire cmd_valid;
  wire [CW-1:0] cmd_client;
  wire [OW-1:0] cmd_op;
  wire [TW-1:0] cmd_tag;

  tessera_dispatcher #(.N_CLIENTS(N), .OP_W(OW), .TAG_W(TW)) dut (
    .clk(clk), .rst_n(rst_n), .req(req), .op_bus(op_bus), .tag_bus(tag_bus),
    .grant(grant), .cmd_valid(cmd_valid), .cmd_ready(cmd_ready),
    .cmd_client(cmd_client), .cmd_op(cmd_op), .cmd_tag(cmd_tag)
  );

  always @* begin
    assert(cmd_valid == (|req));
    assert((grant & ~req) == 0);
    if (!cmd_ready) assert(grant == 0);
    assert((grant & (grant - 1'b1)) == 0);
    if (cmd_valid) begin
      assert(cmd_op == op_bus[cmd_client*OW +: OW]);
      assert(cmd_tag == tag_bus[cmd_client*TW +: TW]);
    end
  end
endmodule
