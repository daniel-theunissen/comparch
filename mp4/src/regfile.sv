// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 1ns / 10ps

module regfile (
    input clk,
    input write_en,
    input [4:0] A1,
    input [4:0] A2,
    input [4:0] A3,
    input [31:0] WD,
    output wire [31:0] RD1,
    output wire [31:0] RD2
);

reg [31:0] RegisterFile [32];
int i;

initial begin
    for (i = 0; i < 32; i++) begin
        RegisterFile[i] <= 32'd0;
    end
end

assign RD1 = (A1 != 0) ? RegisterFile[A1] : 0;
assign RD2 = (A2 != 0) ? RegisterFile[A2] : 0;

always @(posedge clk) begin
    if((write_en) && (A3 != 32'b0)) begin
        RegisterFile[A3] <= WD;
    end
end

endmodule
