
module register_file (
    input clk,
    input reset,
    input reg_write,

    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,

    input [31:0] write_data,

    output [31:0] read_data1,
    output [31:0] read_data2
);

    reg [31:0] registers [0:31];
    integer i;

    // Reset all registers; register 0 always stays zero.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (reg_write && write_reg != 5'd0) begin
            //5'd0 means the decimal value zero represented using 5 bits.
            
            registers[write_reg] <= write_data;
        end
    end

    // Two asynchronous read ports.
    assign read_data1 = (read_reg1 == 5'd0) ? 32'b0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 32'b0 : registers[read_reg2];

endmodule
