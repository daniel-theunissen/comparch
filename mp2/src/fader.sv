// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module fader #(
    parameter POLARITY = 1,
    parameter START_OFFSET = 0.01, // NOTE: Start offset can't be more than hold time
    parameter RAMP_TIME = 0.033,
    parameter HOLD_TIME = 0.1,
    parameter PWM_DUTY_CYCLE = 1200, // 1200 clocks per cycle / 12 MHz clock = 100us
    parameter PWM_UPDATE_INTERVAL = 12000, // Update PWM value every 12000 clocks = 1ms
    parameter CLOCK_FREQ = 12e6,
    parameter HOLD_CYCLES = $rtoi(HOLD_TIME * CLOCK_FREQ),
    parameter START_OFFSET_CYCLES = $rtoi(START_OFFSET * CLOCK_FREQ),
    parameter RAMP_INTERVALS = $rtoi(RAMP_TIME / (PWM_UPDATE_INTERVAL/CLOCK_FREQ)),
    parameter RAMP_STEP = $rtoi(PWM_DUTY_CYCLE / RAMP_INTERVALS)
  ) (
    input clk,
    output reg [$clog2(PWM_DUTY_CYCLE) - 1:0] pwm_signal
  );

  localparam WAIT = 0, INC = 1, DEC = 2;
  reg [1:0] state = WAIT;
  reg [1:0] next_state;

  // This is all unsynthesizable outside of an FPGA
  // but without a synchronous reset I'm not sure how to handle it
  reg [$clog2(RAMP_INTERVALS) - 1:0] update_count = 0;
  reg [$clog2(HOLD_CYCLES) - 1:0] count = 0;

  reg ramp_direction = POLARITY;
  reg done_waiting = 0;
  reg done_ramping = 0;
  reg update_pwm = 0;
  reg wait_start = 1;

  initial begin
    pwm_signal = POLARITY ? PWM_DUTY_CYCLE : 0;
  end

  // Handle state transfers
  always @(posedge clk) begin
    state <= next_state;
  end

  always_comb begin
    case (state)
      WAIT:
        if (done_waiting) begin
          next_state = ramp_direction ? DEC : INC;
        end else begin
          next_state = state;
        end
      INC, DEC:
        if (done_ramping) begin
          next_state = WAIT;
        end else begin
          next_state = state;
        end
      default: next_state = state;
    endcase
  end

  always @(posedge clk) begin
    case (state)
      WAIT: // Handle waiting
      begin
        if (wait_start) begin
          if ((START_OFFSET_CYCLES == 0) || (count == START_OFFSET_CYCLES - 1)) begin
            done_waiting <= 1'b1;
            wait_start <= 1'b0;
            count <= 0;
          end else begin
            done_waiting <= 1'b0;
            count <= count + 1'b1;
          end
        end else if (count == HOLD_CYCLES - 1) begin
          count <= 0;
          done_waiting <= 1'b1;
        end else begin
          done_waiting <= 1'b0;
          count <= count + 1'b1;
        end
      end
      INC, DEC: // Update the PWM signal
      begin
        if (count == PWM_UPDATE_INTERVAL - 1) begin
          count <= 0;
          update_pwm <= 1'b1;
        end else begin
          update_pwm <= 1'b0;
          count <= count + 1'b1;
        end
      end
      default: count <= 0;
    endcase
  end

  // Handle increasing/decreasing PWM signal
  always @(posedge clk) begin
    if(update_pwm) begin
      if (update_count == RAMP_INTERVALS - 1) begin
        update_count <= 0;
        done_ramping <= 1'b1;
        ramp_direction <= ~ramp_direction;
      end else begin
        update_count <= update_count + 1'b1;
      end
      pwm_signal <= ramp_direction ? (pwm_signal - RAMP_STEP) : (pwm_signal + RAMP_STEP);
    end else begin done_ramping <= 0; end
end
endmodule
