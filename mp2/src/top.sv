// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module top #(
  parameter PWM_DUTY_CYCLE = 1200
) (
    input  clk,
    output RGB_B,
    output RGB_G,
    output RGB_R
);

wire [$clog2(PWM_DUTY_CYCLE) - 1:0] pwm_value_r, pwm_value_g, pwm_value_b;
wire pwm_out_r, pwm_out_g, pwm_out_b;

fader #(
  .POLARITY(1),
  .START_OFFSET(0.167),
  .RAMP_TIME(0.167),
  .HOLD_TIME(0.333)
) fader_r (
  .clk(clk),
  .pwm_signal(pwm_value_r)
);

fader #(
  .POLARITY(0),
  .START_OFFSET(0),
  .RAMP_TIME(0.167),
  .HOLD_TIME(0.333)
) fader_g (
  .clk(clk),
  .pwm_signal(pwm_value_g)
);

fader #(
  .POLARITY(0),
  .START_OFFSET(0.333),
  .RAMP_TIME(0.167),
  .HOLD_TIME(0.333)
) fader_b (
  .clk(clk),
  .pwm_signal(pwm_value_b)
);

pwm pwm_r (
  .clk(clk),
  .pwm_value(pwm_value_r),
  .pwm_out(pwm_out_r)
);

pwm pwm_g (
  .clk(clk),
  .pwm_value(pwm_value_g),
  .pwm_out(pwm_out_g)
);

pwm pwm_b (
  .clk(clk),
  .pwm_value(pwm_value_b),
  .pwm_out(pwm_out_b)
);

assign RGB_R = ~pwm_out_r;
assign RGB_G = ~pwm_out_g;
assign RGB_B = ~pwm_out_b;

endmodule

