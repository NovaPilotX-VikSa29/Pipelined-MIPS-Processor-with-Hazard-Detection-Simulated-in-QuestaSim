
module hazard_detection_unit (
    // Instruction currently in the ID/EX pipeline register
    input wire       id_ex_memread,
    input wire [4:0] id_ex_rt,

    // Instruction currently in the IF/ID pipeline register
    input wire [5:0] if_id_opcode,
    input wire [4:0] if_id_rs,
    input wire [4:0] if_id_rt,

    // Pipeline control outputs
    output reg pc_write,
    output reg if_id_write,
    output reg control_mux
);

    // MIPS opcodes
    localparam OP_RTYPE = 6'b000000;
    localparam OP_LW    = 6'b100011;
    localparam OP_SW    = 6'b101011;
    localparam OP_BEQ   = 6'b000100;
    localparam OP_BNE   = 6'b000101;
    localparam OP_ADDI  = 6'b001000;

    reg uses_rs;
    reg uses_rt;

    always @(*) begin
        // Determine which source registers the
        // instruction in IF/ID actually uses.
        uses_rs = 1'b0;
        uses_rt = 1'b0;

        case (if_id_opcode)
            OP_RTYPE: begin
                uses_rs = 1'b1;
                uses_rt = 1'b1;
            end

            OP_LW, OP_ADDI: begin
                uses_rs = 1'b1;
            end

            OP_SW, OP_BEQ, OP_BNE: begin
                uses_rs = 1'b1;
                uses_rt = 1'b1;
            end

            default: begin
                uses_rs = 1'b0;
                uses_rt = 1'b0;
            end
        endcase

        // Default: allow normal pipeline operation.
        pc_write   = 1'b1;
        if_id_write = 1'b1;
        control_mux = 1'b0;

        // Detect a load-use hazard.
        if (id_ex_memread &&
            (id_ex_rt != 5'd0) &&
            ((uses_rs && (id_ex_rt == if_id_rs)) ||
             (uses_rt && (id_ex_rt == if_id_rt)))) begin

            pc_write    = 1'b0;
            if_id_write = 1'b0;
            control_mux = 1'b1;
        end
    end

endmodule
