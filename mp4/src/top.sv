// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 1ns / 10ps

module top (
    input clk,
    output reg LED
);

// Set up program counter
//wire [31:0] next_pc = res;
reg [31:0] pc = 32'h1000;
always @(posedge clk) begin
  if(PCWrite) begin
    pc <= res;
  end
end

wire [31:0] Adr;
wire [31:0] instr;
wire [31:0] data;

memory #(
  .IMEM_INIT_FILE_PREFIX("itest"),
  //.DMEM_INIT_FILE_PREFIX("lw_data"),
  .IMEM_LEN(4),
  .DMEM_LEN(1)
) memory (
  .clk(clk),
  .funct3(Instr[14:12]),
  .dmem_wren(MemWrite),
  .dmem_address(Adr),
  .dmem_data_in(B),
  .imem_address(Adr),
  .IRWrite(IRWrite),
  .imem_data_out(instr),
  .dmem_data_out(data),
  .led()
);

assign Adr = AdrSrc ? res : pc;

// Non-architectural register for multi-cycle operation
wire [31:0] Instr;
assign Instr = instr;
reg [31:0] oldpc;
// always @(posedge clk) begin
//   if(IRWrite) begin
//     Instr <= instr;
//   end
// end
reg [31:0] Data;
always @(posedge clk) begin
  oldpc <= pc;
  Data <= data;
end

wire [31:0] imm;

immgen immgen (
  .instr(Instr),
  .imm(imm)
);

wire [4:0] A1 = Instr[19:15];
wire [4:0] A2 = Instr[24:20];
wire [4:0] A3 = Instr[11:7];
wire [31:0] RD1;
wire [31:0] RD2;

regfile regfile (
  .clk(clk),
  .write_en(RegWrite),
  .A1(A1),
  .A2(A2),
  .A3(A3),
  .WD(res),
  .RD1(RD1),
  .RD2(RD2)
);

// Non-architectural register for multi-cycle operation
reg [31:0] A;
reg [31:0] B;
always @(posedge clk) begin
  A <= RD1;
  B <= RD2;
end

logic [31:0] aluIn1;
logic [31:0] aluIn2;
wire [31:0] aluRes;
wire isZero;

always_comb begin
  case (ALUSrcA)
    2'b00: aluIn1 = pc;
    2'b01: aluIn1 = oldpc;
    2'b10: aluIn1 = A;
    default: aluIn1 = 0;
  endcase

  case (ALUSrcB)
    2'b00: aluIn2 = B;
    2'b01: aluIn2 = imm;
    2'b10: aluIn2 = 32'd4;
    default: aluIn2 = 0;
  endcase
end

alu alu (
  .aluControl(aluControl),
  .aluIn1(aluIn1),
  .aluIn2(aluIn2),
  .aluRes(aluRes),
  .isZero(isZero)
);

// assign aluIn1 = aluSrcA ? A :

// Non-architectural register for multi-cycle operation
reg [31:0] aluOut;
always @(posedge clk) begin
  aluOut <= aluRes;
end

logic [31:0] res;

always_comb begin
  case (ResultSrc)
    2'b00: res = aluOut;
    2'b01: res = Data;
    2'b10: res = aluRes;
    default: res = 0;
  endcase
end

wire PCWrite;
wire AdrSrc;
wire MemWrite;
wire IRWrite;
wire [1:0] ResultSrc;
wire [3:0] aluControl;
wire [1:0] ALUSrcB;
wire [1:0] ALUSrcA;
wire RegWrite;

controller controller (
  .clk(clk),
  .opcode(Instr[6:0]),
  .funct3(Instr[14:12]),
  .funct7_5(Instr[30]),
  .aluIsZero(isZero),
  .PCWrite(PCWrite),
  .AdrSrc(AdrSrc),
  .MemWrite(MemWrite),
  .IRWrite(IRWrite),
  .ResultSrc(ResultSrc),
  .aluControl(aluControl),
  .ALUSrcB(ALUSrcB),
  .ALUSrcA(ALUSrcA),
  //.ImmSrc(),
  .RegWrite(RegWrite)
);


endmodule

