// IF/ID pipeline register
// Assumptions: 32-bit instruction and PC+4; active-high asynchronous reset.
// enable=0 holds current values; flush=1 clears the stored instruction.
module IF_ID (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire flush,
    input wire [31:0] instr_in,
    input wire [31:0] pc_plus4_in,
    output reg [31:0] instr_out,
    output reg [31:0] pc_plus4_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instr_out   <= 32'b0;
            pc_plus4_out <= 32'b0;
        end else if (flush) begin
            instr_out   <= 32'b0;
            pc_plus4_out <= 32'b0;
        end else if (enable) begin
            instr_out   <= instr_in;
            pc_plus4_out <= pc_plus4_in;
        end
        // Otherwise hold the previous values.
    end
endmodule
