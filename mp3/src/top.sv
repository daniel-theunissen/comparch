// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module top (
  input  clk,
  output wire _48b,
  output wire LED
  // output wire [7:0] mem [64],
  // output wire next_game_step_calculated
);

wire start_next_game_step;
wire next_game_step_calculated;
wire [5:0] address;
wire [7:0] channel_data;
wire [7:0] next_channel_data;
wire write_en;

// always @(posedge clk) begin
//   if (next_game_step_calculated)
//     start_next_game_step <= 1;
//   else
//     start_next_game_step <= 0;
// end

memory #(
  .INIT_FILE("test.txt")
) memory (
  .clk(clk),
  .write_en(write_en),
  .address(address),
  .data_in(next_channel_data),
  .data_out(channel_data)
  //.mem(mem)
);

game_controller game_controller(
  .clk(clk),
  .start(start_next_game_step),
  .channel_data(channel_data),
  .next_channel_data(next_channel_data),
  .memory_updated(next_game_step_calculated),
  .write_en(write_en),
  .memory_address(game_address)
);

wire [5:0] game_address;
wire [5:0] display_address;
assign address = next_game_step_calculated ? display_address : game_address;

reg [23:0] shift_reg = 24'd0;
wire load_sreg;
wire transmit_pixel;
wire shift;
wire ws2812b_out;

wire status;
assign LED = ~status;

display_controller display_controller(
  .clk(clk),
  .done_calculating(next_game_step_calculated),
  .start_calculating(start_next_game_step),
  .load_sreg(load_sreg),
  .transmit_pixel(transmit_pixel),
  .pixel(display_address),
  .status(status)
);

ws2812b LED_matrix (
    .clk            (clk),
    .serial_in      (shift_reg[23]),
    .transmit       (transmit_pixel),
    .ws2812b_out    (ws2812b_out),
    .shift          (shift)
);

always_ff @(posedge clk) begin
  if (load_sreg) begin
    shift_reg <= {channel_data, 16'd0};
  end else if (shift) begin
    shift_reg <= {shift_reg[22:0], 1'b0};
  end
end

assign _48b = ws2812b_out;

endmodule
