// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module top_tb;

  parameter PWM_DUTY_CYCLE = 1200;

  reg clk = 0;
  wire RGB_R, RGB_G, RGB_B;

  top #(
    .PWM_DUTY_CYCLE(PWM_DUTY_CYCLE)
  ) top (
    .clk(clk),
    .RGB_R(RGB_R),
    .RGB_G(RGB_G),
    .RGB_B(RGB_B)
  );

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    #100000000
    $finish;
  end

  always begin
    #4
    clk = ~clk;
  end

endmodule
