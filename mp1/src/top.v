// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 1ns / 10ps

module top (
    input  clk,
    output RGB_B,
    output RGB_G,
    output RGB_R
);

  localparam TIMER_CYCLES = 2000000;
  reg [$clog2(TIMER_CYCLES) - 1:0] count;

  reg [2:0] cycle_pos;
  reg [2:0] LEDS;

  initial begin
    LEDS = 3'b000;
    cycle_pos = 0;
    count = 0;
  end

  always @(posedge clk) begin
    if (count == TIMER_CYCLES - 1) begin

      if (cycle_pos == 5) begin
        cycle_pos <= 0;
      end else begin
        cycle_pos <= cycle_pos + 1;
      end

      count <= 0;

    end else begin
      count <= count + 1;
    end


  end

  always @(posedge clk) begin
    case (cycle_pos)
      3'd0: LEDS <= 3'b100;
      3'd1: LEDS <= 3'b110;
      3'd2: LEDS <= 3'b010;
      3'd3: LEDS <= 3'b011;
      3'd4: LEDS <= 3'b001;
      3'd5: LEDS <= 3'b101;
      default: LEDS <= 3'b000;
    endcase
  end

  assign RGB_R = ~LEDS[2];
  assign RGB_G = ~LEDS[1];
  assign RGB_B = ~LEDS[0];

endmodule

