# Run from the folder containing all the .v files and program.hex:
#   vsim -do run.do           (or:  do run.do   inside the QuestaSim console)

quit -sim
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work

# Explicit file list (does not compile tb_pipeline_registers.v)
vlog -work work \
    alu.v \
    control_unit.v \
    data_memory.v \
    instruction_memory.v \
    program_counter.v \
    register_file.v \
    forwarding_unit.v \
    hazard_detection_unit.v \
    IF_ID.v ID_EX.v EX_MEM.v MEM_WB.v \
    mips_pipeline.v \
    tb_mips_pipeline.v

vsim -voptargs=+acc work.tb_mips_pipeline

add wave -divider CLOCK
add wave -radix hex  /tb_mips_pipeline/clk /tb_mips_pipeline/reset

add wave -divider {HAZARD INDICATORS}
add wave -color Orange  -label DATA_forwarding   /tb_mips_pipeline/dut/data_hazard_forward
add wave -color Red     -label DATA_loaduse_stall /tb_mips_pipeline/dut/data_hazard_loaduse
add wave -color Yellow  -label CONTROL_branch    /tb_mips_pipeline/dut/control_hazard
add wave -color Cyan    -label STRUCTURAL        /tb_mips_pipeline/dut/struct_hazard
add wave -color Cyan    -label STRUCT_mem        /tb_mips_pipeline/dut/struct_hazard_mem
add wave -color Cyan    -label STRUCT_regfile    /tb_mips_pipeline/dut/struct_hazard_rf

add wave -divider {HAZARD CONTROL SIGNALS}
add wave /tb_mips_pipeline/dut/pc_write_hdu /tb_mips_pipeline/dut/if_id_write /tb_mips_pipeline/dut/control_mux_hdu
add wave /tb_mips_pipeline/dut/flush_if_id /tb_mips_pipeline/dut/flush_id_ex
add wave -radix unsigned /tb_mips_pipeline/dut/forward_a /tb_mips_pipeline/dut/forward_b

add wave -divider PIPELINE
add wave -radix hex  /tb_mips_pipeline/dut/pc /tb_mips_pipeline/dut/instr_if /tb_mips_pipeline/dut/instr_id
add wave -radix hex  /tb_mips_pipeline/dut/branch_target_ex
add wave -radix hex  /tb_mips_pipeline/dut/fwd_a_val /tb_mips_pipeline/dut/alu_b /tb_mips_pipeline/dut/alu_result_ex
add wave -radix hex  /tb_mips_pipeline/dut/wb_data /tb_mips_pipeline/dut/wb_write_reg

add wave -divider REGFILE
add wave -radix unsigned /tb_mips_pipeline/dut/rf/registers

run -all
wave zoom full
