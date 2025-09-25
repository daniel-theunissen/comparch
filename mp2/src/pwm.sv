module pwm #(
    parameter DUTY_CYCLE = 1200
) (
    input wire clk,
    output wire pwm_out,
    input wire [$clog2(DUTY_CYCLE) - 1:0] pwm_value
);

  reg [$clog2(DUTY_CYCLE):0] count = 0;

  always @(posedge clk) begin
    if (count == DUTY_CYCLE - 1) begin
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end

  assign pwm_out = count < pwm_value;
endmodule
