// ID/EX pipeline register
// control_mux=1 inserts a bubble by clearing control signals while allowing
// data fields to be captured. This matches the supplied hazard unit's output.
// Confirm the control-field meanings/widths with the decoder owner.
module ID_EX (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire control_mux,

    input wire [31:0] pc_plus4_in,
    input wire [31:0] read_data1_in,
    input wire [31:0] read_data2_in,
    input wire [31:0] sign_ext_imm_in,
    input wire [4:0] rs_in,
    input wire [4:0] rt_in,
    input wire [4:0] rd_in,

    input wire reg_dst_in,
    input wire alu_src_in,
    input wire [2:0] alu_control_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire mem_to_reg_in,
    input wire reg_write_in,
    input wire branch_in,

    output reg [31:0] pc_plus4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] sign_ext_imm_out,
    output reg [4:0] rs_out,
    output reg [4:0] rt_out,
    output reg [4:0] rd_out,

    output reg reg_dst_out,
    output reg alu_src_out,
    output reg [2:0] alu_control_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out,
    output reg reg_write_out,
    output reg branch_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_plus4_out <= 32'b0;
            read_data1_out <= 32'b0;
            read_data2_out <= 32'b0;
            sign_ext_imm_out <= 32'b0;
            rs_out <= 5'b0;
            rt_out <= 5'b0;
            rd_out <= 5'b0;
            reg_dst_out <= 1'b0;
            alu_src_out <= 1'b0;
            alu_control_out <= 3'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            reg_write_out <= 1'b0;
            branch_out <= 1'b0;
        end else if (!enable) begin
            // Hold all fields during a stall.
        end else begin
            pc_plus4_out <= pc_plus4_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            sign_ext_imm_out <= sign_ext_imm_in;
            rs_out <= rs_in;
            rt_out <= rt_in;
            rd_out <= rd_in;

            if (control_mux) begin
                // Bubble: no architectural side effects from this slot.
                reg_dst_out <= 1'b0;
                alu_src_out <= 1'b0;
                alu_control_out <= 3'b0;
                mem_read_out <= 1'b0;
                mem_write_out <= 1'b0;
                mem_to_reg_out <= 1'b0;
                reg_write_out <= 1'b0;
                branch_out <= 1'b0;
            end else begin
                reg_dst_out <= reg_dst_in;
                alu_src_out <= alu_src_in;
                alu_control_out <= alu_control_in;
                mem_read_out <= mem_read_in;
                mem_write_out <= mem_write_in;
                mem_to_reg_out <= mem_to_reg_in;
                reg_write_out <= reg_write_in;
                branch_out <= branch_in;
            end
        end
    end
endmodule
