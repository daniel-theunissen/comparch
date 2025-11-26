// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 1ns / 10ps

module immgen (
    input [31:0] instr,
    output logic [31:0] imm
);

// The 5 immediate formats
wire [31:0] Uimm = {instr[31], instr[30:12], {12{1'b0}}};
wire [31:0] Iimm = {{21{instr[31]}}, instr[30:20]};
wire [31:0] Simm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
wire [31:0] Bimm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
wire [31:0] Jimm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

wire isALUimm = (instr[6:0] == 7'b0010011);  // rd <- rs1 OP Iimm
wire isBranch = (instr[6:0] == 7'b1100011);  // if(rs1 OP rs2) PC<-PC+Bimm
wire isJALR = (instr[6:0] == 7'b1100111);  // rd <- PC+4; PC<-rs1+Iimm
wire isJAL = (instr[6:0] == 7'b1101111);  // rd <- PC+4; PC<-PC+Jimm
wire isAUIPC = (instr[6:0] == 7'b0010111);  // rd <- PC + Uimm
wire isLUI = (instr[6:0] == 7'b0110111);  // rd <- Uimm
wire isLoad = (instr[6:0] == 7'b0000011);  // rd <- mem[rs1+Iimm]
wire isStore = (instr[6:0] == 7'b0100011);  // mem[rs1+Simm] <- rs2

wire isUtype = isAUIPC || isLUI;
wire isItype = isALUimm || isJALR || isLoad;
wire isStype = isStore;
wire isBtype = isBranch;
wire isJtype = isJAL;

always_comb begin
    if (isUtype) imm = Uimm;
    else if (isItype) imm = Iimm;
    else if (isStype) imm = Simm;
    else if (isBtype) imm = Bimm;
    else if (isJtype) imm = Jimm;
end

endmodule
