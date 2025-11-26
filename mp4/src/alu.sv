// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 1ns / 10ps

module alu(
    input [3:0] aluControl,
    input [31:0] aluIn1,
    input [31:0] aluIn2,
    output logic [31:0] aluRes,
    output wire isZero
);

  // Big combinatorial block
  always_comb begin
    case (aluControl)
      4'b0000: aluRes = aluIn1 + aluIn2;
      4'b0001: aluRes = aluIn1 - aluIn2;
      4'b0011: aluRes = (aluIn1 | aluIn2);
      4'b0010: aluRes = (aluIn1 & aluIn2);
      4'b0110: aluRes = (aluIn1 ^ aluIn2);
      4'b0101: aluRes = {31'b0, {(($signed(aluIn1) < $signed(aluIn2)))}};
      4'b0111: aluRes = {31'b0, {(aluIn1 < aluIn2)}};
      4'b1000: aluRes = aluIn1 << aluIn2[4:0];
      4'b1001: aluRes = aluIn1 >> aluIn2[4:0];
      4'b1010: aluRes = aluIn1 >>> aluIn2[4:0];
    endcase
  end

  assign isZero = (aluRes == 32'b0);

endmodule
