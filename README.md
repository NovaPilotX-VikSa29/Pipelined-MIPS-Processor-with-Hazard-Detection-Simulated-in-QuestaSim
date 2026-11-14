# Pipelined MIPS Processor with Hazard Detection

## 1. Project Overview

This project involves the design and simulation of a **5-stage pipelined MIPS processor** using Verilog HDL. The processor implements instruction pipelining and incorporates hazard detection, forwarding, and branch handling mechanisms to ensure correct instruction execution.

The design is simulated using **QuestaSim**, with waveform analysis used to observe processor behaviour across different pipeline stages.

## 2. Project Objectives

- Design a five-stage pipelined MIPS processor.
- Implement pipeline registers between consecutive stages.
- Support arithmetic and logical instruction execution.
- Implement data hazard detection and forwarding.
- Handle load-use dependencies through pipeline stalls.
- Implement conditional branching using BEQ and BNE.
- Handle control hazards through pipeline flushing.
- Verify processor functionality through simulation and waveform analysis.

## 3. Project Requirements

### 3.1 Functional Requirements

The processor should satisfy the following requirements:

1. **Instruction Fetch:** Fetch instructions from instruction memory using the program counter.
2. **Instruction Decode:** Decode instructions and obtain operands from the register file.
3. **Execution:** Perform arithmetic, logical, and branch comparison operations.
4. **Memory Access:** Support memory read and write operations.
5. **Write Back:** Write execution or memory results into the register file.
6. **Data Hazard Detection:** Detect dependencies between instructions and introduce stalls when necessary.
7. **Data Forwarding:** Forward available results to reduce unnecessary pipeline stalls.
8. **Control Hazard Handling:** Support conditional branches and flush incorrectly fetched instructions when a branch is taken.
9. **Program Counter Update:** Support sequential execution and branch target selection.

### 3.2 Non-Functional Requirements

- The design should be modular and maintainable.
- Verilog modules should have clearly defined inputs and outputs.
- Simulation should be reproducible using QuestaSim.
- Pipeline behaviour should be observable through waveform analysis.
- The design should maintain correct instruction execution in the presence of hazards.

## 4. Processor Architecture

The processor follows a five-stage pipeline architecture.

| Stage | Name | Function |
|---|---|---|
| IF | Instruction Fetch | Fetches instructions from instruction memory. |
| ID | Instruction Decode | Decodes instructions and reads register operands. |
| EX | Execute | Performs ALU operations and branch comparisons. |
| MEM | Memory Access | Performs memory read and write operations. |
| WB | Write Back | Writes results back into the register file. |

### Pipeline Registers

Four pipeline registers are implemented:

- **IF/ID:** Stores the fetched instruction and PC information.
- **ID/EX:** Stores decoded operands, immediate values, and control signals.
- **EX/MEM:** Transfers execution results and memory-related control signals.
- **MEM/WB:** Transfers results and control signals for the write-back stage.

## 5. Instruction Set Support

The design includes support for the following instructions:

| Instruction | Description |
|---|---|
| ADD | Adds two register operands. |
| SUB | Subtracts one register operand from another. |
| AND | Performs a bitwise AND operation. |
| BEQ | Branches when two register operands are equal. |
| BNE | Branches when two register operands are not equal. |

## 6. Hazard Detection and Handling

### 6.1 Data Hazards

Data hazards occur when an instruction depends on the result of a previous instruction.

The processor uses:

- **Hazard Detection Unit:** Detects load-use dependencies and generates stall control signals.
- **Forwarding Unit:** Forwards results from later pipeline stages to avoid unnecessary stalls.

### 6.2 Control Hazards

Control hazards occur during conditional branch instructions.

The design handles control hazards using:

- Branch condition evaluation.
- Branch target address calculation.
- Program counter redirection.
- Pipeline flushing to remove instructions fetched along an incorrect execution path.

BEQ branches when the operands are equal, whereas BNE branches when the operands are unequal.

## 7. Software and Hardware Requirements

### Software Requirements

| Software / Tool | Purpose |
|---|---|
| QuestaSim | Verilog compilation and simulation. |
| Verilog HDL | Hardware description and processor implementation. |
| Visual Studio Code | Source code editing. |
| Git | Version control. |
| GitHub | Source code hosting and collaboration. |

### Hardware Requirements

- Computer or laptop capable of running QuestaSim.
- Sufficient RAM and storage for simulation and waveform analysis.
- Windows or Linux operating system compatible with the installed QuestaSim version.

## 8. Project Modules

| File | Description |
|---|---|
| `alu.v` | Performs arithmetic and logical operations. |
| `program_counter.v` | Maintains and updates the program counter. |
| `instruction_memory.v` | Stores instructions for execution. |
| `data_memory.v` | Handles data memory operations. |
| `register_file.v` | Stores and provides register operands. |
| `control_unit.v` | Generates control signals based on instruction decoding. |
| `IF_ID.v` | Implements the IF/ID pipeline register. |
| `ID_EX.v` | Implements the ID/EX pipeline register. |
| `EX_MEM.v` | Implements the EX/MEM pipeline register. |
| `MEM_WB.v` | Implements the MEM/WB pipeline register. |
| `hazard_detection_unit.v` | Detects data hazards and generates stall and flush signals. |
| `forwarding_unit.v` | Generates forwarding control signals. |
| `mips_pipeline.v` | Integrates the processor components into the pipelined architecture. |
| `tb_mips_pipeline.v` | Testbench for the complete pipelined processor. |
| `tb_pipeline_registers.v` | Testbench for pipeline register verification. |
| `program.hex` | Contains the hexadecimal instruction program. |
| `run.do` | QuestaSim simulation script. |

## 9. Simulation and Verification

The project uses QuestaSim to compile and simulate the Verilog modules.

The verification process includes:

1. Testing individual pipeline registers.
2. Verifying arithmetic and logical instruction execution.
3. Checking data hazard detection.
4. Testing load-use pipeline stalls.
5. Verifying forwarding operations.
6. Testing BEQ and BNE branch conditions.
7. Checking branch target selection and pipeline flushing.
8. Analysing waveforms to observe pipeline behaviour.

### Simulation Files

- `run.do` – Simulation command script.
- `program.hex` – Instruction input file.
- `tb_mips_pipeline.v` – Main processor testbench.
- `tb_pipeline_registers.v` – Pipeline register testbench.
- `waves.vcd` – Waveform dump, when generated.
- `transcript` – Simulation transcript output.

## 10. Running the Simulation

1. Open QuestaSim.
2. Navigate to the project directory.
3. Compile the Verilog source files and testbench.
4. Start the simulation.
5. Execute the simulation script using:

```tcl
do run.do
```

6. Observe the simulation transcript.
7. Open the waveform window to inspect pipeline signals and verify processor behaviour.

*Note: The exact compilation order and simulation commands depend on the contents of `run.do`.*

## 11. Expected Outcomes

- Successful implementation of a five-stage pipelined MIPS processor.
- Correct execution of supported arithmetic and logical instructions.
- Detection and handling of data hazards.
- Reduced pipeline stalls through forwarding.
- Correct conditional branch handling.
- Proper pipeline flushing for taken branches.
- Successful simulation and waveform-based verification.

## 12. Conclusion

This project demonstrates the implementation of a five-stage pipelined MIPS processor using Verilog HDL. It provides practical experience with processor architecture, instruction pipelining, pipeline registers, data forwarding, hazard detection, and control hazard handling.

The project also demonstrates the importance of simulation and waveform analysis in verifying digital hardware designs.

## 13. Technologies Used

- Verilog HDL
- QuestaSim
- Visual Studio Code
- Git and GitHub