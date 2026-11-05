
module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [2:0] alu_control,
    output reg [31:0] result,
    output zero
);

    always @(*) begin
        case (alu_control)

            3'b000: result = a + b;                   // ADD
            3'b001: result = a - b;                   // SUB
            3'b010: result = a & b;                   // AND
            3'b011: result = a | b;                   // OR
            3'b100: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT

            default: result = 32'b0;

        endcase
    end

    // Zero flag: used for branch comparison
    assign zero = (result == 32'b0);

endmodule
