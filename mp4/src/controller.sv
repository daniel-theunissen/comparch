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
    //output wire [1:0] ImmSrc,
    output logic RegWrite
);

localparam FETCH = 5'd0, DECODE = 5'd1, MEMADR = 5'd2, MEMREAD = 5'd3, MEMWB = 5'd4,
MEMWRITE = 5'd5, EXECUTER = 5'd6, ALUWB = 5'd7, EXECUTEI = 5'd8, JAL = 5'd9,
BEQ = 5'd10, RESET = 5'd31;
// MEMWRITE = 5'd4, EXECUTE =;
reg [4:0] state = FETCH;
reg [4:0] next_state;

logic PCUpdate;
logic Branch;
assign PCWrite = ((aluIsZero & Branch) || PCUpdate);

always @(posedge clk) begin
    state <= next_state;
end

always_comb begin
    case(state)
      RESET:
        next_state = DECODE;
      FETCH:
        next_state = DECODE;
      DECODE: begin
        case(opcode)
          7'b0000011, 7'b0100011: next_state = MEMADR;
          7'b0110011: next_state = EXECUTER;
          7'b0010011: next_state = EXECUTEI;
          7'b1101111: next_state = JAL;
          7'b1100011: next_state = BEQ;
          default: next_state = DECODE;
        endcase
      end
      EXECUTER, EXECUTEI, JAL: next_state = ALUWB;
      MEMADR:
        if(opcode == 7'b0000011) begin
            next_state = MEMREAD;
        end else if(opcode == 7'b0100011) begin
            next_state = MEMWRITE;
        end
      MEMREAD:
        next_state = MEMWB;
      MEMWRITE, MEMWB, ALUWB, BEQ: next_state = FETCH;
    endcase
end

logic [1:0] ALUOp;

initial begin
  RegWrite = 1'b0;
  MemWrite = 1'b0;
  IRWrite = 1'b0;
  PCUpdate = 1'b0;
  Branch = 1'b0;
end

always_comb begin
    case(state)
      RESET: begin
        AdrSrc = 1'b0;
        ALUSrcA = 2'b00;
        ALUSrcB = 2'b10;
        ALUOp = 2'b00;
        ResultSrc = 2'b10;

        IRWrite = 1'b1;
      end
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

        PCUpdate = 1'b0;
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
      end
      BEQ: begin
        ALUSrcA = 2'b10;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01;
        ResultSrc = 2'b00;
        Branch = 1'b1;
      end
    endcase
end

always_comb begin
    case(ALUOp)
      2'b00: aluControl = 4'b0000;
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
            if({opcode[5], funct7_5} == 2'b11) begin
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
        endcase
      end
    endcase
end

endmodule
