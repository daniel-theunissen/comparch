// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 1ns / 10ps

module controller (
    input clk,
    input [6:0] opcode,
    input [2:0] funct3,
    input funct7_5,
    input aluIsZero,

    output logic PCWrite,
    output logic AdrSrc,
    output logic MemWrite,
    output logic IRWrite,
    output logic [1:0] ResultSrc,
    output logic [3:0] aluControl,
    output logic [1:0] ALUSrcB,
    output logic [1:0] ALUSrcA,
    output logic RegWrite
);

localparam FETCH = 5'd0, DECODE = 5'd1, MEMADR = 5'd2, MEMREAD = 5'd3, MEMWB = 5'd4,
MEMWRITE = 5'd5, EXECUTER = 5'd6, ALUWB = 5'd7, EXECUTEI = 5'd8, JAL = 5'd9,
JALR = 5'd10, LUI = 5'd11, AUIPC = 5'd12,
BEQ = 5'd13, BNE = 5'd14, BLT = 5'd15, BGE = 5'd16, BLTU = 5'd17, BGEU = 5'd18;
reg [4:0] state = FETCH;
reg [4:0] next_state;

logic PCUpdate;
logic Branch;
logic BranchSel;
logic BranchCondition;
// Depending on BranchSel, branch if the ALU result is or is not zero
// This allows easy checking for opposite conditions (e.g. eq vs. ne)
assign BranchCondition = BranchSel ? (!aluIsZero) : aluIsZero;
assign PCWrite = ((BranchCondition & Branch) || PCUpdate);

// State transitions
always @(posedge clk) begin
    state <= next_state;
end

always_comb begin
    case(state)
      FETCH:
        next_state = DECODE;
      DECODE: begin
        case(opcode)
          7'b0000011, 7'b0100011, 7'b1100111: next_state = MEMADR;
          7'b0110011: next_state = EXECUTER;
          7'b0010011: next_state = EXECUTEI;
          7'b1101111: next_state = JAL;
          7'b0110111: next_state = LUI;
          7'b0010111: next_state = AUIPC;
          7'b1100011: begin
            case(funct3)
              3'b000: next_state = BEQ;
              3'b001: next_state = BNE;
              3'b100: next_state = BLT;
              3'b101: next_state = BGE;
              3'b110: next_state = BLTU;
              3'b111: next_state = BGEU;
              default: next_state = DECODE;
            endcase
          end
          default: next_state = DECODE;
        endcase
      end
      MEMADR: begin
        case(opcode)
          7'b0000011: next_state = MEMREAD;
          7'b0100011: next_state = MEMWRITE;
          7'b1100111: next_state = JALR;
          default: next_state = MEMADR;
        endcase
      end
      EXECUTER, EXECUTEI, AUIPC, JAL, JALR: next_state = ALUWB;
      MEMREAD: next_state = MEMWB;
      MEMWRITE, MEMWB, ALUWB, LUI: next_state = FETCH;
      BEQ, BNE, BLT, BGE, BLTU, BGEU: next_state = FETCH;
      default: next_state = state;
    endcase
end

// Controller outputs
logic [1:0] ALUOp;

initial begin
  RegWrite = 1'b0;
  MemWrite = 1'b0;
  IRWrite = 1'b0;
  PCUpdate = 1'b0;
  Branch = 1'b0;
  BranchSel = 1'b0;
end

always_comb begin
    case(state)
      FETCH: begin
        AdrSrc = 1'b0;
        ALUSrcA = 2'b00;
        ALUSrcB = 2'b10;
        ALUOp = 2'b00;
        ResultSrc = 2'b10;

        IRWrite = 1'b1;
        RegWrite = 1'b0;
        MemWrite = 1'b0;
        PCUpdate = 1'b1;
        Branch = 1'b0;
        BranchSel = 1'b0;
      end
      DECODE: begin
        ALUSrcA = 2'b01;
        ALUSrcB = 2'b01;
        ALUOp = 2'b00;

        PCUpdate = 1'b0;
        IRWrite = 1'b0;
      end
      EXECUTER: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b10;
      end
      EXECUTEI: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b01;
        ALUOp = 2'b10;
      end
      LUI: begin
        ResultSrc = 2'b11;
        RegWrite = 1'b1;
      end
      AUIPC: begin
        ALUSrcA = 2'b01;
        ALUSrcB = 2'b01;
        ALUOp = 2'b00;
      end
      JAL: begin
        ALUSrcA = 2'b01;
        ALUSrcB = 2'b10;
        ALUOp = 2'b00;
        ResultSrc = 2'b00;
        PCUpdate = 1'b1;
      end
      ALUWB: begin
        ResultSrc = 2'b00;
        RegWrite = 1'b1;
        ALUSrcB = 2'b10;

        PCUpdate = 1'b0;
      end
      JALR: begin
        ResultSrc = 2'b00;
        ALUSrcA = 2'b01;
        ALUSrcB = 2'b10;

        PCUpdate = 1'b1;
      end
      MEMADR: begin
        IRWrite = 1'b0;
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b01;
        ALUOp = 2'b00;
      end
      MEMREAD: begin
        ResultSrc = 2'b00;
        AdrSrc = 1'b1;
      end
      MEMWRITE: begin
        ResultSrc = 2'b00;
        AdrSrc = 1'b1;
        MemWrite = 1'b1;
      end
      MEMWB: begin
        ResultSrc = 2'b01;
        RegWrite = 1'b1;

        AdrSrc = 1'b0;
      end
      BEQ: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01;
        ResultSrc = 2'b00;
        Branch = 1'b1;
        BranchSel = 1'b0;
      end
      BNE: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01;
        ResultSrc = 2'b00;
        Branch = 1'b1;
        BranchSel = 1'b1;
      end
      BLT: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01;
        ResultSrc = 2'b00;
        Branch = 1'b1;
        BranchSel = 1'b1;
      end
      BGE: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01;
        ResultSrc = 2'b00;
        Branch = 1'b1;
        BranchSel = 1'b0;
      end
      BLTU: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01;
        ResultSrc = 2'b00;
        Branch = 1'b1;
        BranchSel = 1'b1;
      end
      BGEU: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01;
        ResultSrc = 2'b00;
        Branch = 1'b1;
        BranchSel = 1'b0;
      end
      default: begin
        AdrSrc = 2'b00;
      end
    endcase
end

// ALU Decoder
always_comb begin
    case(ALUOp)
      2'b00: aluControl = 4'b0000;
      2'b01: begin
        case(funct3)
          3'b000, 3'b001: aluControl = 4'b0001; // eq, ne
          3'b100, 3'b101: aluControl = 4'b0101; // lt, ge
          3'b110, 3'b111: aluControl = 4'b0111; // ltu, geu
          default: aluControl = 4'b0000;
        endcase
      end
      2'b10: begin
        case(funct3)
          3'b000: begin
            if({opcode[5], funct7_5} == 2'b11) begin
              aluControl = 4'b0001;
            end else begin
              aluControl = 4'b0000;
            end
          end
          3'b101: begin
            if(funct7_5 == 1'b1) begin
              aluControl = 4'b1010;
            end else begin
              aluControl = 4'b1001;
            end
          end
          3'b001: aluControl = 4'b1000;
          3'b010: aluControl = 4'b0101;
          3'b011: aluControl = 4'b0111;
          3'b100: aluControl = 4'b0110;
          3'b110: aluControl = 4'b0011;
          3'b111: aluControl = 4'b0010;
          default: aluControl = 4'b0000;
        endcase
      end
      default: aluControl = 4'b0000;
    endcase
end

endmodule
