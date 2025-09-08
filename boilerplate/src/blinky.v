// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 1ns / 10ps

module blinky (
    input clk,
    output reg LED
);

  localparam TIMER_CYCLES = 6000000;
  reg [$clog2(TIMER_CYCLES) - 1:0] count;

  initial begin
    LED = 0;
  end

  always @(posedge clk) begin
    if (count == TIMER_CYCLES - 1) begin
      LED   <= ~LED;
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end

endmodule

