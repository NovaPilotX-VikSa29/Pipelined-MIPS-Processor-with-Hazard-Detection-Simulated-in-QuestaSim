`timescale 1ns/1ps
// Self-checking system testbench for mips_pipeline.
// Detects, logs and counts all three hazard classes, then checks results.
//
// Program under test (program.hex):
//  idx  instruction            exercises
//   0   addi $1,$0,5
//   1   add  $2,$1,$1          DATA  forward EX/MEM        ($2=10)
//   2   add  $3,$2,$1          DATA  forward MEM + WB      ($3=15)
//   3   sw   $3,0($0)          DATA  forwarded store data  (dmem[0]=15)
//   4   lw   $4,0($0)
//   5   add  $5,$4,$1          DATA  LOAD-USE stall #1     ($5=20)
//  6-8  addi $8 chain          DATA  back-to-back RAW      ($8=3)
//   9   add  $9,$8,$8                                      ($9=6)
//  10   sub  $10,$9,$1                                     ($10=1)
// 11-12 nop
//  13   add  $11,$10,$10       DATA  distance-3 (WB->ID bypass) ($11=2)
//  14   beq  $1,$1,+1          CONTROL taken #1
//  15   addi $6,$0,99          flushed                     ($6=0)
//  16   addi $7,$0,7
//  17   sw   $5,4($0)                                      (dmem[1]=20)
//  18   addi $12,$0,7
//  19   beq  $12,$7,+1         CONTROL taken #2, forwarded operands
//  20   addi $13,$0,99         flushed                     ($13=0)
//  21   addi $14,$0,1
//  22   lw   $18,0($0)
//  23   beq  $18,$3,+1         DATA load-use stall #2 into a branch, then
//                              CONTROL taken #3            ($18=15)
//  24   addi $19,$0,99         flushed                     ($19=0)
//  25   addi $20,$0,1                                      ($20=1)
//  26   bne  $14,$0,+2         CONTROL taken #4 (BNE, skips TWO instrs)
//  27   addi $15,$0,99         flushed by ID/EX flush      ($15=0)
//  28   addi $21,$0,99         flushed by IF/ID flush      ($21=0)
//  29   bne  $14,$14,+1        BNE NOT taken
//  30   addi $16,$0,9          executes                    ($16=9)
//  31   addi $17,$0,2                                      ($17=2)
//  32   beq  $0,$0,-1          parks the CPU in a loop

module tb_mips_pipeline;
    reg clk   = 1'b0;
    reg reset = 1'b1;

    integer errors  = 0;
    integer cycle   = 0;
    integer n_fwd    = 0;   // cycles using a forwarded operand
    integer n_stall  = 0;   // load-use stall cycles
    integer n_branch = 0;   // taken branches (excluding the parking loop)
    integer n_struct = 0;   // structural-hazard conditions detected (avoided)

    mips_pipeline dut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;                       // 100 MHz

    // Parking loop (idx 32): its PC+4 is 132. Ignore it when counting.
    wire in_park_loop = (dut.ex_pc4 == 32'd132);

    always @(posedge clk) if (!reset) cycle <= cycle + 1;

    // ---------------- Hazard detection log + counters ----------------
    // Sampled at the falling edge (mid-cycle, signals are stable). The time printed is the
    // START of the clock cycle in which the hazard is active, so it matches the waveform.
    always @(negedge clk) if (!reset) begin
        if (dut.data_hazard_loaduse) begin
            n_stall <= n_stall + 1;
            $display("[%0d ns] DATA HAZARD    load-use: stall 1 cycle (PC and IF/ID held, bubble to EX)", $time - 5);
        end
        if (dut.data_hazard_forward) begin
            n_fwd <= n_fwd + 1;
            $display("[%0d ns] DATA HAZARD    forwarding  A=%0d B=%0d  (2=from EX/MEM, 1=from MEM/WB)",
                     $time - 5, dut.forward_a, dut.forward_b);
        end
        if (dut.control_hazard && !in_park_loop) begin
            n_branch <= n_branch + 1;
            $display("[%0d ns] CONTROL HAZARD branch taken -> target %h, flush IF/ID + ID/EX",
                     $time - 5, dut.branch_target_ex);
        end
        if (dut.struct_hazard) begin
            n_struct <= n_struct + 1;
`ifdef VERBOSE_STRUCT
            $display("[%0d ns] STRUCTURAL     mem=%b regfile=%b (avoided: separate I/D memory, bypass)",
                     $time - 5, dut.struct_hazard_mem, dut.struct_hazard_rf);
`endif
        end
    end

    // Load program (#1 so it lands after instruction_memory's own init block)
    initial begin
        #1 $readmemh("program.hex", dut.imem.memory, 0, 32);
    end

    task check_reg(input integer n, input [31:0] expected);
        begin
            if (dut.rf.registers[n] !== expected) begin
                $display("FAIL: $%0d = %h, expected %h", n, dut.rf.registers[n], expected);
                errors = errors + 1;
            end else
                $display("PASS: $%0d = %0d", n, dut.rf.registers[n]);
        end
    endtask

    task check_mem(input integer idx, input [31:0] expected);
        begin
            if (dut.dmem.memory[idx] !== expected) begin
                $display("FAIL: dmem[%0d] = %h, expected %h", idx, dut.dmem.memory[idx], expected);
                errors = errors + 1;
            end else
                $display("PASS: dmem[%0d] = %0d", idx, dut.dmem.memory[idx]);
        end
    endtask

    task check_count(input [255:0] name, input integer got, input integer expected);
        begin
            if (got !== expected) begin
                $display("FAIL: %0s = %0d, expected %0d", name, got, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s = %0d", name, got);
        end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_mips_pipeline);

        #22 reset = 1'b0;
        #800;                                   // ~80 cycles; program needs ~45

        $display("---- Results after %0d cycles ----", cycle);
        check_reg(1,  32'd5);
        check_reg(2,  32'd10);
        check_reg(3,  32'd15);
        check_reg(4,  32'd15);
        check_reg(5,  32'd20);
        check_reg(6,  32'd0);     // flushed
        check_reg(7,  32'd7);
        check_reg(8,  32'd3);
        check_reg(9,  32'd6);
        check_reg(10, 32'd1);
        check_reg(11, 32'd2);
        check_reg(12, 32'd7);
        check_reg(13, 32'd0);     // flushed
        check_reg(14, 32'd1);
        check_reg(15, 32'd0);     // flushed (BNE taken)
        check_reg(16, 32'd9);     // BNE not taken -> executed
        check_reg(17, 32'd2);
        check_reg(18, 32'd15);
        check_reg(19, 32'd0);     // flushed
        check_reg(20, 32'd1);
        check_reg(21, 32'd0);     // flushed by IF/ID flush (2nd skipped instr)
        check_reg(0,  32'd0);     // $0 never written

        check_mem(0, 32'd15);
        check_mem(1, 32'd20);

        $display("---- Hazard summary ----");
        check_count("load-use stalls ", n_stall,  2);
        check_count("taken branches  ", n_branch, 4);
        if (n_fwd > 0) $display("PASS: forwarding used in %0d cycles", n_fwd);
        else begin $display("FAIL: forwarding never used"); errors = errors + 1; end
        if (n_struct > 0)
            $display("PASS: structural conflicts detected %0d times and avoided (separate I/D memory + bypass)", n_struct);
        else begin $display("FAIL: no structural conflict condition seen"); errors = errors + 1; end

        if (errors == 0) $display("*** ALL TESTS PASSED ***");
        else             $display("*** %0d TEST(S) FAILED ***", errors);

`ifdef BATCH
        $finish;
`else
        $stop;
`endif
    end
endmodule
