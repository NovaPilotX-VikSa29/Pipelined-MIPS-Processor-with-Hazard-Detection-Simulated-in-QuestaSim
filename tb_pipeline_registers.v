`timescale 1ns/1ps

// Independent smoke test for the four pipeline-register modules.
// This checks reset, capture, hold, flush and ID/EX bubble behavior.
// It does not test a complete processor or hazard/forwarding correctness.
module tb_pipeline_registers;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg reset, enable, flush, control_mux;
    reg [31:0] instr_in, pc4_in;
    wire [31:0] instr_out, pc4_out;

    IF_ID if_id (
        .clk(clk), .reset(reset), .enable(enable), .flush(flush),
        .instr_in(instr_in), .pc_plus4_in(pc4_in),
        .instr_out(instr_out), .pc_plus4_out(pc4_out)
    );

    reg [31:0] id_pc4, id_a, id_b, id_imm;
    reg [4:0] id_rs, id_rt, id_rd;
    reg id_reg_dst, id_alu_src;
    reg [2:0] id_alu_control;
    reg id_mem_read, id_mem_write, id_mem_to_reg, id_reg_write, id_branch;
    wire [31:0] ex_pc4, ex_a, ex_b, ex_imm;
    wire [4:0] ex_rs, ex_rt, ex_rd;
    wire ex_reg_dst, ex_alu_src;
    wire [2:0] ex_alu_control;
    wire ex_mem_read, ex_mem_write, ex_mem_to_reg, ex_reg_write, ex_branch;

    ID_EX id_ex (
        .clk(clk), .reset(reset), .enable(enable), .control_mux(control_mux),
        .pc_plus4_in(id_pc4), .read_data1_in(id_a), .read_data2_in(id_b),
        .sign_ext_imm_in(id_imm), .rs_in(id_rs), .rt_in(id_rt), .rd_in(id_rd),
        .reg_dst_in(id_reg_dst), .alu_src_in(id_alu_src),
        .alu_control_in(id_alu_control), .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write), .mem_to_reg_in(id_mem_to_reg),
        .reg_write_in(id_reg_write), .branch_in(id_branch),
        .pc_plus4_out(ex_pc4), .read_data1_out(ex_a), .read_data2_out(ex_b),
        .sign_ext_imm_out(ex_imm), .rs_out(ex_rs), .rt_out(ex_rt), .rd_out(ex_rd),
        .reg_dst_out(ex_reg_dst), .alu_src_out(ex_alu_src),
        .alu_control_out(ex_alu_control), .mem_read_out(ex_mem_read),
        .mem_write_out(ex_mem_write), .mem_to_reg_out(ex_mem_to_reg),
        .reg_write_out(ex_reg_write), .branch_out(ex_branch)
    );

    reg [31:0] em_branch_target, em_alu_result, em_write_data;
    reg em_zero;
    reg [4:0] em_write_reg;
    reg em_mem_read, em_mem_write, em_mem_to_reg, em_reg_write, em_branch;
    wire [31:0] me_branch_target, me_alu_result, me_write_data;
    wire me_zero;
    wire [4:0] me_write_reg;
    wire me_mem_read, me_mem_write, me_mem_to_reg, me_reg_write, me_branch;

    EX_MEM ex_mem (
        .clk(clk), .reset(reset), .enable(enable), .flush(flush),
        .branch_target_in(em_branch_target), .zero_in(em_zero),
        .alu_result_in(em_alu_result), .write_data_in(em_write_data),
        .write_reg_in(em_write_reg), .mem_read_in(em_mem_read),
        .mem_write_in(em_mem_write), .mem_to_reg_in(em_mem_to_reg),
        .reg_write_in(em_reg_write), .branch_in(em_branch),
        .branch_target_out(me_branch_target), .zero_out(me_zero),
        .alu_result_out(me_alu_result), .write_data_out(me_write_data),
        .write_reg_out(me_write_reg), .mem_read_out(me_mem_read),
        .mem_write_out(me_mem_write), .mem_to_reg_out(me_mem_to_reg),
        .reg_write_out(me_reg_write), .branch_out(me_branch)
    );

    reg [31:0] mw_read_data, mw_alu_result;
    reg [4:0] mw_write_reg;
    reg mw_mem_to_reg, mw_reg_write;
    wire [31:0] wb_read_data, wb_alu_result;
    wire [4:0] wb_write_reg;
    wire wb_mem_to_reg, wb_reg_write;

    MEM_WB mem_wb (
        .clk(clk), .reset(reset), .enable(enable), .flush(flush),
        .read_data_in(mw_read_data), .alu_result_in(mw_alu_result),
        .write_reg_in(mw_write_reg), .mem_to_reg_in(mw_mem_to_reg),
        .reg_write_in(mw_reg_write), .read_data_out(wb_read_data),
        .alu_result_out(wb_alu_result), .write_reg_out(wb_write_reg),
        .mem_to_reg_out(wb_mem_to_reg), .reg_write_out(wb_reg_write)
    );

    initial begin
        reset = 1; enable = 0; flush = 0; control_mux = 0;
        instr_in = 0; pc4_in = 0;
        id_pc4 = 0; id_a = 0; id_b = 0; id_imm = 0;
        id_rs = 0; id_rt = 0; id_rd = 0;
        id_reg_dst = 0; id_alu_src = 0; id_alu_control = 0;
        id_mem_read = 0; id_mem_write = 0; id_mem_to_reg = 0;
        id_reg_write = 0; id_branch = 0;
        em_branch_target = 0; em_zero = 0; em_alu_result = 0;
        em_write_data = 0; em_write_reg = 0; em_mem_read = 0;
        em_mem_write = 0; em_mem_to_reg = 0; em_reg_write = 0; em_branch = 0;
        mw_read_data = 0; mw_alu_result = 0; mw_write_reg = 0;
        mw_mem_to_reg = 0; mw_reg_write = 0;

        // Let asynchronous reset settle.
        #2;
        if (instr_out !== 0 || pc4_out !== 0 || ex_reg_write !== 0 ||
            me_mem_write !== 0 || wb_reg_write !== 0)
            $fatal(1, "Reset test failed");

        // Drive values away from rising edge; registers capture at next posedge.
        @(negedge clk);
        reset = 0; enable = 1;
        instr_in = 32'h00221820; pc4_in = 32'd4;
        id_pc4 = 4; id_a = 11; id_b = 22; id_imm = 100;
        id_rs = 1; id_rt = 2; id_rd = 3;
        id_reg_dst = 1; id_alu_src = 0; id_alu_control = 3'b000;
        id_reg_write = 1;
        em_alu_result = 33; em_write_data = 22; em_write_reg = 3;
        em_reg_write = 1;
        mw_read_data = 77; mw_alu_result = 33; mw_write_reg = 3;
        mw_mem_to_reg = 1; mw_reg_write = 1;

        @(posedge clk); #1;
        if (instr_out !== 32'h00221820 || pc4_out !== 4 ||
            ex_a !== 11 || ex_b !== 22 || ex_reg_write !== 1 ||
            me_alu_result !== 33 || wb_read_data !== 77 || wb_reg_write !== 1)
            $fatal(1, "Capture test failed");

        // Disable: values must hold even if inputs change.
        @(negedge clk);
        enable = 0; instr_in = 32'hffffffff; pc4_in = 8;
        @(posedge clk); #1;
        if (instr_out !== 32'h00221820 || pc4_out !== 4)
            $fatal(1, "Hold test failed");

        // Re-enable and flush IF/ID, EX/MEM and MEM/WB.
        @(negedge clk);
        enable = 1; flush = 1;
        @(posedge clk); #1;
        if (instr_out !== 0 || pc4_out !== 0 || me_mem_write !== 0 ||
            me_reg_write !== 0 || wb_reg_write !== 0)
            $fatal(1, "Flush test failed");

        // Check ID/EX control_mux inserts a bubble.
        @(negedge clk);
        flush = 0; control_mux = 1;
        id_mem_read = 1; id_mem_write = 1; id_reg_write = 1; id_branch = 1;
        @(posedge clk); #1;
        if (ex_mem_read !== 0 || ex_mem_write !== 0 ||
            ex_reg_write !== 0 || ex_branch !== 0)
            $fatal(1, "ID/EX bubble test failed");

        $display("PASS: pipeline-register smoke tests completed.");
        $finish;
    end
endmodule
