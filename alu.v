
module alu (
    input  [31:0] A,
    input  [31:0] B,
    input  [2:0]  ALU_Sel,
    output reg [31:0] Result
);

    always @(*) begin
        case (ALU_Sel)

            3'b000: Result = A + B; 
            3'b001: Result = A - B;
            3'b010: Result = A & B;
            3'b011: Result = A | B;
            3'b100: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;

            default: Result = 32'b0;

        endcase
    end

endmodule
