
module instruction_memory (
    input  [31:0] address,
    output [31:0] instruction
);

    reg [31:0] memory [0:255];
    integer i;

    initial begin
        // Initialize all instruction memory locations
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'b0;

        // Sample program for testing arithmetic and control hazards

        memory[0] = 32'h10000001; // BEQ $zero, $zero, +1 : TAKEN
        memory[1] = 32'h00221820; // ADD $3, $1, $2       : FLUSHED
        memory[2] = 32'h14000001; // BNE $zero, $zero, +1 : NOT TAKEN
        memory[3] = 32'h00222022; // SUB $4, $1, $2
        memory[4] = 32'h00222824; // AND $5, $1, $2

        // BEQ opcode = 000100
        // BNE opcode = 000101
        // Branch target = (PC + 4) + (sign-extended immediate << 2)
    end

    // Each instruction occupies 4 bytes
    assign instruction = memory[address[9:2]];

endmodule
