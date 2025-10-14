// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module memory #(
  parameter INIT_FILE = ""
)(
    input clk,
    input write_en,
    input [5:0] address,
    input [7:0] data_in,
    output reg [7:0] data_out
    // output reg [7:0] mem [64]
);

reg [7:0] mem [64];

initial begin
    $readmemh(INIT_FILE, mem);
end

always_ff @(negedge clk) begin
    if(write_en)
      mem[address] <= data_in;
    data_out <= mem[address];
end

endmodule
