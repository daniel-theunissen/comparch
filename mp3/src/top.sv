// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module top (
  input  clk,
  output wire _48b,
  output wire LED
);

wire start_next_game_step;
wire next_game_step_calculated;
wire [5:0] address;
wire write_en;

wire [7:0] channel_data_g;
wire [7:0] next_channel_data_g;

memory #(
  .INIT_FILE("test_g.txt")
) memory_g (
  .clk(clk),
  .write_en(write_en),
  .address(address),
  .data_in(next_channel_data_g),
  .data_out(channel_data_g)
);

game_controller game_controller_g (
  .clk(clk),
  .start(start_next_game_step),
  .channel_data(channel_data_g),
  .next_channel_data(next_channel_data_g),
  .memory_updated(next_game_step_calculated),
  .write_en(write_en),
  .memory_address(game_address)
);

wire [7:0] channel_data_r;
wire [7:0] next_channel_data_r;

memory #(
  .INIT_FILE("test_r.txt")
) memory_r (
  .clk(clk),
  .write_en(write_en),
  .address(address),
  .data_in(next_channel_data_r),
  .data_out(channel_data_r)
);

game_controller game_controller_r (
  .clk(clk),
  .start(start_next_game_step),
  .channel_data(channel_data_r),
  .next_channel_data(next_channel_data_r),
  .memory_updated(),
  .write_en(),
  .memory_address()
);

wire [7:0] channel_data_b;
wire [7:0] next_channel_data_b;

memory #(
  .INIT_FILE("test_b.txt")
) memory_b (
  .clk(clk),
  .write_en(write_en),
  .address(address),
  .data_in(next_channel_data_b),
  .data_out(channel_data_b)
);

game_controller game_controller_b (
  .clk(clk),
  .start(start_next_game_step),
  .channel_data(channel_data_b),
  .next_channel_data(next_channel_data_b),
  .memory_updated(),
  .write_en(),
  .memory_address()
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
    shift_reg <= {channel_data_g, channel_data_r, channel_data_b};
  end else if (shift) begin
    shift_reg <= {shift_reg[22:0], 1'b0};
  end
end

assign _48b = ws2812b_out;

endmodule
