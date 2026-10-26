
module forwarding_unit (
    // Source registers of the instruction in EX
    input  wire [4:0] id_ex_rs,
    input  wire [4:0] id_ex_rt,

    // Destination register of the instruction in MEM
    input  wire [4:0] ex_mem_rd,
    input  wire       ex_mem_regwrite,

    // Destination register of the instruction in WB
    input  wire [4:0] mem_wb_rd,
    input  wire       mem_wb_regwrite,

    // Forwarding controls for the ALU inputs
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);

    always @(*) begin
        // Default: use original register operands
        forward_a = 2'b00;
        forward_b = 2'b00;

        // Forward operand A from the MEM stage
        if (ex_mem_regwrite &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs)) begin
            forward_a = 2'b10;
        end

        // Forward operand B from the MEM stage
        if (ex_mem_regwrite &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rt)) begin
            forward_b = 2'b10;
        end

        // Forward operand A from the WB stage
        // only if the MEM stage did not already match
        if (mem_wb_regwrite &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs) &&
            !(ex_mem_regwrite &&
              (ex_mem_rd != 5'd0) &&
              (ex_mem_rd == id_ex_rs))) begin
            forward_a = 2'b01;
        end

        // Forward operand B from the WB stage
        // only if the MEM stage did not already match
        if (mem_wb_regwrite &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rt) &&
            !(ex_mem_regwrite &&
              (ex_mem_rd != 5'd0) &&
              (ex_mem_rd == id_ex_rt))) begin
            forward_b = 2'b01;
        end
    end

endmodule
