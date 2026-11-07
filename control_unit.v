// Main control unit. Decodes opcode/funct in the ID stage.
// alu_control uses the encoding of the repo's alu.v:
//   000 add, 001 sub, 010 and, 011 or, 100 slt
module control_unit (
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    output reg        reg_dst,
    output reg        alu_src,
    output reg [2:0]  alu_control,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        reg_write,
    output reg        branch,      // BEQ or BNE
    output reg        branch_ne    // 1 = BNE (taken when operands differ)
);
    localparam OP_RTYPE = 6'b000000;
    localparam OP_LW    = 6'b100011;
    localparam OP_SW    = 6'b101011;
    localparam OP_BEQ   = 6'b000100;
    localparam OP_BNE   = 6'b000101;
    localparam OP_ADDI  = 6'b001000;

    always @(*) begin
        reg_dst     = 1'b0;
        alu_src     = 1'b0;
        alu_control = 3'b000;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        reg_write   = 1'b0;
        branch      = 1'b0;
        branch_ne   = 1'b0;

        case (opcode)
            OP_RTYPE: begin
                reg_dst   = 1'b1;
                reg_write = 1'b1;
                case (funct)
                    6'h20:   alu_control = 3'b000; // add
                    6'h22:   alu_control = 3'b001; // sub
                    6'h24:   alu_control = 3'b010; // and
                    6'h25:   alu_control = 3'b011; // or
                    6'h2A:   alu_control = 3'b100; // slt
                    default: reg_write   = 1'b0;   // nop (sll $0,$0,0) / unsupported
                endcase
            end
            OP_LW: begin
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                reg_write  = 1'b1;
            end
            OP_SW: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
            end
            OP_BEQ: begin
                alu_control = 3'b001; // subtract; zero flag decides
                branch      = 1'b1;
            end
            OP_BNE: begin
                alu_control = 3'b001; // subtract; NOT zero decides
                branch      = 1'b1;
                branch_ne   = 1'b1;
            end
            OP_ADDI: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end
            default: ;
        endcase
    end
endmodule
