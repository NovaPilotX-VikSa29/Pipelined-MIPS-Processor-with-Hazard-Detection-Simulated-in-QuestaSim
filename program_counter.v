
module program_counter (
    input clk,
    input reset,
    input pc_write,

    input branch_taken,
    input [31:0] branch_target,

    input [31:0] next_pc,
    output reg [31:0] pc
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            pc <= 32'b0;
        end

        // Branch has priority over normal PC update or stall
        else if (branch_taken) begin
            pc <= branch_target;
        end

        // Normal sequential PC update
        else if (pc_write) begin
            pc <= next_pc;
        end

    end

endmodule
