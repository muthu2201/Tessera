`timescale 1ns/1ps
// Pin-count-friendly FPGA shell for bring-up: exposes one command client.
// The internal execution system remains parameterized and unchanged; board
// designs can later add a serialized host interface or a board-specific wrapper.
module tessera_execution_system_fpga_shell #(
    parameter integer OP_W = 3,
    parameter integer TAG_W = 8,
    parameter integer DATA_W = 16,
    parameter integer ACC_W = 32,
    parameter integer DEPTH = 4,
    parameter integer COUNT_W = $clog2(DEPTH + 1),
    parameter integer CLIENT_W = 1
) (
    input  logic clk,
    input  logic rst_n,
    input  logic req,
    input  logic [OP_W-1:0] op,
    input  logic [TAG_W-1:0] tag,
    input  logic unit_select,
    input  logic [DATA_W-1:0] operand_a,
    input  logic [DATA_W-1:0] operand_b,
    input  logic [ACC_W-1:0] accumulator,
    output logic grant,
    output logic completion_valid,
    input  logic completion_ready,
    output logic [CLIENT_W-1:0] completion_client,
    output logic [TAG_W-1:0] completion_tag,
    output logic [1:0] completion_status,
    output logic [ACC_W-1:0] completion_result,
    output logic [COUNT_W-1:0] completion_occupancy
);
    tessera_execution_system #(
        .N_CLIENTS(1),
        .OP_W(OP_W),
        .TAG_W(TAG_W),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .DEPTH(DEPTH),
        .CLIENT_W(CLIENT_W)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .op_bus(op),
        .tag_bus(tag),
        .unit_select_bus(unit_select),
        .operand_a_bus(operand_a),
        .operand_b_bus(operand_b),
        .accumulator_bus(accumulator),
        .grant(grant),
        .completion_valid(completion_valid),
        .completion_ready(completion_ready),
        .completion_client(completion_client),
        .completion_tag(completion_tag),
        .completion_status(completion_status),
        .completion_result(completion_result),
        .completion_occupancy(completion_occupancy)
    );
endmodule
