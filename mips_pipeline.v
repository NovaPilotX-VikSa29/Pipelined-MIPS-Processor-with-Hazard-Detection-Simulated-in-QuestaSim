// Top-level 5-stage pipelined MIPS: IF / ID / EX / MEM / WB
// Wires together the repo's modules.
//
// HAZARDS DETECTED AND HANDLED
//  DATA       forwarding_unit        EX/MEM->EX and MEM/WB->EX forwarding
//             hazard_detection_unit  load-use: stall PC + IF/ID, bubble in ID/EX
//             WB->ID bypass (here)   register file writes on the clock edge, so a
//                                    value in WB is not visible to ID that cycle
//  CONTROL    BEQ/BNE resolved in EX. branch_taken -> PC loads branch target and
//             hazard_detection_unit flushes IF/ID and ID/EX (2-cycle penalty)
//  STRUCTURAL avoided by design (separate instruction + data memory, register
//             file read/write in the same cycle). The struct_* wires below DETECT
//             when the conflict would have occurred so it can be shown/counted.
module mips_pipeline (
    input wire clk,
    input wire reset
);
    // ---------------------------------------------------------------
    // Cross-stage signals, all declared up front (strict tools such as
    // QuestaSim reject use-before-declaration).
    // ---------------------------------------------------------------
    wire        pc_write_hdu, if_id_write, control_mux_hdu;
    wire        flush_if_id, flush_id_ex;
    wire        branch_taken_ex;
    wire [31:0] branch_target_ex;

    wire [31:0] wb_data, wb_read_data, wb_alu_result;
    wire [4:0]  wb_write_reg;
    wire        wb_mem_to_reg, wb_reg_write;

    wire [31:0] ex_pc4, ex_rd1, ex_rd2, ex_imm;
    wire [4:0]  ex_rs, ex_rt, ex_rd;
    wire        ex_reg_dst, ex_alu_src, ex_mem_read, ex_mem_write;
    wire        ex_mem_to_reg, ex_reg_write, ex_branch;
    wire [2:0]  ex_alu_control;

    wire [31:0] mem_alu_result, mem_write_data, mem_read_data;
    wire [4:0]  mem_write_reg;
    wire        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;

    // ------------------------------------------------------------------ IF
    wire [31:0] pc, pc_plus4_if, instr_if;
    assign pc_plus4_if = pc + 32'd4;

    program_counter pc_reg (
        .clk(clk), .reset(reset),
        .pc_write(pc_write_hdu),
        .branch_taken(branch_taken_ex),
        .branch_target(branch_target_ex),
        .next_pc(pc_plus4_if),
        .pc(pc)
    );

    instruction_memory imem (.address(pc), .instruction(instr_if));

    // ---------------------------------------------------------- IF/ID reg
    wire [31:0] instr_id, pc_plus4_id;

    IF_ID if_id (
        .clk(clk), .reset(reset),
        .enable(if_id_write),
        .flush(flush_if_id),
        .instr_in(instr_if), .pc_plus4_in(pc_plus4_if),
        .instr_out(instr_id), .pc_plus4_out(pc_plus4_id)
    );

    // ------------------------------------------------------------------ ID
    wire [5:0]  opcode_id = instr_id[31:26];
    wire [4:0]  rs_id     = instr_id[25:21];
    wire [4:0]  rt_id     = instr_id[20:16];
    wire [4:0]  rd_id     = instr_id[15:11];
    wire [5:0]  funct_id  = instr_id[5:0];
    wire [31:0] imm_id    = {{16{instr_id[15]}}, instr_id[15:0]};

    wire        c_reg_dst, c_alu_src, c_mem_read, c_mem_write;
    wire        c_mem_to_reg, c_reg_write, c_branch, c_branch_ne;
    wire [2:0]  c_alu_control;

    control_unit cu (
        .opcode(opcode_id), .funct(funct_id),
        .reg_dst(c_reg_dst), .alu_src(c_alu_src), .alu_control(c_alu_control),
        .mem_read(c_mem_read), .mem_write(c_mem_write),
        .mem_to_reg(c_mem_to_reg), .reg_write(c_reg_write),
        .branch(c_branch), .branch_ne(c_branch_ne)
    );

    wire [31:0] rf_rd1, rf_rd2;
    register_file rf (
        .clk(clk), .reset(reset),
        .reg_write(wb_reg_write),
        .read_reg1(rs_id), .read_reg2(rt_id),
        .write_reg(wb_write_reg), .write_data(wb_data),
        .read_data1(rf_rd1), .read_data2(rf_rd2)
    );

    // WB -> ID bypass (producer in WB, consumer in ID in the same cycle)
    wire byp1 = wb_reg_write && (wb_write_reg != 5'd0) && (wb_write_reg == rs_id);
    wire byp2 = wb_reg_write && (wb_write_reg != 5'd0) && (wb_write_reg == rt_id);
    wire [31:0] rd1_id = byp1 ? wb_data : rf_rd1;
    wire [31:0] rd2_id = byp2 ? wb_data : rf_rd2;

    // ---------------------------------------------------------- ID/EX reg
    ID_EX id_ex (
        .clk(clk), .reset(reset),
        .enable(1'b1),
        .control_mux(control_mux_hdu),   // load-use bubble
        .flush(flush_id_ex),             // taken-branch flush
        .pc_plus4_in(pc_plus4_id),
        .read_data1_in(rd1_id), .read_data2_in(rd2_id),
        .sign_ext_imm_in(imm_id),
        .rs_in(rs_id), .rt_in(rt_id), .rd_in(rd_id),
        .reg_dst_in(c_reg_dst), .alu_src_in(c_alu_src),
        .alu_control_in(c_alu_control),
        .mem_read_in(c_mem_read), .mem_write_in(c_mem_write),
        .mem_to_reg_in(c_mem_to_reg), .reg_write_in(c_reg_write),
        .branch_in(c_branch),
        .pc_plus4_out(ex_pc4),
        .read_data1_out(ex_rd1), .read_data2_out(ex_rd2),
        .sign_ext_imm_out(ex_imm),
        .rs_out(ex_rs), .rt_out(ex_rt), .rd_out(ex_rd),
        .reg_dst_out(ex_reg_dst), .alu_src_out(ex_alu_src),
        .alu_control_out(ex_alu_control),
        .mem_read_out(ex_mem_read), .mem_write_out(ex_mem_write),
        .mem_to_reg_out(ex_mem_to_reg), .reg_write_out(ex_reg_write),
        .branch_out(ex_branch)
    );

    // ID_EX has a single branch bit, so BEQ-vs-BNE travels in this 1-bit
    // register. It only matters when ex_branch is 1; bubbles/flushes clear
    // ex_branch, so no extra flush/stall handling is needed.
    reg ex_is_bne;
    always @(posedge clk or posedge reset) begin
        if (reset) ex_is_bne <= 1'b0;
        else       ex_is_bne <= c_branch_ne;
    end

    // Hazard detection (needs ID/EX outputs, so it sits after ID_EX)
    hazard_detection_unit hdu (
        .id_ex_memread(ex_mem_read),
        .id_ex_rt(ex_rt),
        .if_id_opcode(opcode_id),
        .if_id_rs(rs_id),
        .if_id_rt(rt_id),
        .branch_taken(branch_taken_ex),
        .pc_write(pc_write_hdu),
        .if_id_write(if_id_write),
        .control_mux(control_mux_hdu),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex)
    );

    // ------------------------------------------------------------------ EX
    wire [1:0] forward_a, forward_b;

    forwarding_unit fwd (
        .id_ex_rs(ex_rs), .id_ex_rt(ex_rt),
        .ex_mem_rd(mem_write_reg), .ex_mem_regwrite(mem_reg_write),
        .mem_wb_rd(wb_write_reg),  .mem_wb_regwrite(wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    wire [31:0] fwd_a_val = (forward_a == 2'b10) ? mem_alu_result :
                            (forward_a == 2'b01) ? wb_data        : ex_rd1;
    wire [31:0] fwd_b_val = (forward_b == 2'b10) ? mem_alu_result :
                            (forward_b == 2'b01) ? wb_data        : ex_rd2;
    wire [31:0] alu_b     = ex_alu_src ? ex_imm : fwd_b_val;

    wire [31:0] alu_result_ex;
    wire        zero_ex;
    alu alu_u (
        .a(fwd_a_val), .b(alu_b), .alu_control(ex_alu_control),
        .result(alu_result_ex), .zero(zero_ex)
    );

    // Branch resolved here: BEQ taken on zero, BNE taken on not-zero
    assign branch_taken_ex  = ex_branch & (ex_is_bne ? ~zero_ex : zero_ex);
    assign branch_target_ex = ex_pc4 + (ex_imm << 2);

    wire [4:0] write_reg_ex = ex_reg_dst ? ex_rd : ex_rt;

    // --------------------------------------------------------- EX/MEM reg
    // Branch fields are carried for completeness but unused: branches are
    // already resolved in EX.
    wire [31:0] unused_mem_branch_target;
    wire        unused_mem_zero, unused_mem_branch;

    EX_MEM ex_mem (
        .clk(clk), .reset(reset),
        .enable(1'b1),
        .flush(1'b0),
        .branch_target_in(branch_target_ex), .zero_in(zero_ex),
        .alu_result_in(alu_result_ex), .write_data_in(fwd_b_val),
        .write_reg_in(write_reg_ex),
        .mem_read_in(ex_mem_read), .mem_write_in(ex_mem_write),
        .mem_to_reg_in(ex_mem_to_reg), .reg_write_in(ex_reg_write),
        .branch_in(ex_branch),
        .branch_target_out(unused_mem_branch_target), .zero_out(unused_mem_zero),
        .alu_result_out(mem_alu_result), .write_data_out(mem_write_data),
        .write_reg_out(mem_write_reg),
        .mem_read_out(mem_mem_read), .mem_write_out(mem_mem_write),
        .mem_to_reg_out(mem_mem_to_reg), .reg_write_out(mem_reg_write),
        .branch_out(unused_mem_branch)
    );

    // ----------------------------------------------------------------- MEM
    data_memory dmem (
        .clk(clk),
        .mem_read(mem_mem_read), .mem_write(mem_mem_write),
        .address(mem_alu_result), .write_data(mem_write_data),
        .read_data(mem_read_data)
    );

    // --------------------------------------------------------- MEM/WB reg
    MEM_WB mem_wb (
        .clk(clk), .reset(reset),
        .enable(1'b1), .flush(1'b0),
        .read_data_in(mem_read_data), .alu_result_in(mem_alu_result),
        .write_reg_in(mem_write_reg),
        .mem_to_reg_in(mem_mem_to_reg), .reg_write_in(mem_reg_write),
        .read_data_out(wb_read_data), .alu_result_out(wb_alu_result),
        .write_reg_out(wb_write_reg),
        .mem_to_reg_out(wb_mem_to_reg), .reg_write_out(wb_reg_write)
    );

    // ------------------------------------------------------------------ WB
    assign wb_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

    // ---------------------------------------------------------------
    // Hazard indicator wires (for waveforms and testbench counters)
    // ---------------------------------------------------------------
    // DATA: an instruction that really executes is using a forwarded operand
    wire ex_valid = ex_reg_write | ex_mem_write | ex_branch;
    wire data_hazard_forward = ex_valid & ((forward_a != 2'b00) | (forward_b != 2'b00));
    // DATA: load-use stall in progress
    wire data_hazard_loaduse = ~pc_write_hdu;
    // CONTROL: taken branch being resolved (2 wrong-path instructions flushed)
    wire control_hazard      = branch_taken_ex;
    // STRUCTURAL: would conflict if memory were unified (fetch + load/store same cycle)
    wire struct_hazard_mem   = mem_mem_read | mem_mem_write;
    // STRUCTURAL: register file written and read (same reg) in one cycle
    wire struct_hazard_rf    = wb_reg_write && (wb_write_reg != 5'd0) &&
                               ((wb_write_reg == rs_id) || (wb_write_reg == rt_id));
    wire struct_hazard       = struct_hazard_mem | struct_hazard_rf;

endmodule
