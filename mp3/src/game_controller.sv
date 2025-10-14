// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module game_controller (
  input  clk,
  input  start,
  input [7:0] channel_data,
  output wire [7:0] next_channel_data,
  output wire memory_updated,
  output wire write_en,
  output reg [5:0] memory_address
);

localparam LOADING = 0, CALCULATING = 1, WRITING = 2, DONE = 3;
reg [1:0] state = DONE;
reg [1:0] next_state;

initial begin
  memory_address = 0;
end

assign memory_updated = (state == DONE);

wire calculating_done;
assign calculating_done = processor_done;

wire loading_done;
assign loading_done = (memory_address == 6'd63);

wire writing_done;
assign writing_done = (memory_address == 6'd63);

always_ff @(posedge clk) begin
  state <= next_state;
end

always_comb begin
    next_state = 2'bxx;
    unique case (state)
      LOADING:
        if (loading_done)
          next_state = CALCULATING;
        else
          next_state = LOADING;
      CALCULATING:
        if (calculating_done)
          next_state = WRITING;
        else
          next_state = CALCULATING;
      WRITING:
        if (writing_done)
          next_state = DONE;
        else
          next_state = WRITING;
      DONE:
        if(start)
          next_state = LOADING;
        else
          next_state = DONE;
    endcase
end

reg [2:0] i = 0;
reg [2:0] j = 0;

assign write_en = (state == WRITING);
assign next_channel_data = (game_state[j][i]) ? 8'b11111111 : 8'b00000000;

always_ff @(posedge clk) begin
  if ((state == LOADING) || (state == WRITING)) begin
    if (i == 3'd7) begin
        j <= j + 1;
        i <= 0;
        end else begin
        i <= i + 1;
    end
    memory_address <= memory_address + 1;
  end
end

always_ff @(posedge clk) begin
  if (state == LOADING) begin
    game_state[j][i] <= (!channel_data) ? 1'b0 : 1'b1;
  end
end

reg [7:0] game_state [64];
wire [7:0] game_state_bus;
assign game_state_bus = game_state[game_address];
wire [7:0] next_game_state_bus;
wire [2:0] game_address;
wire processor_done;
wire processor_writing;
wire start_processor;
assign start_processor = (next_state == CALCULATING);

game_processor game_processor (
  .clk(clk),
  .start(start_processor),
  .game_state_bus(game_state_bus),
  .next_game_state_bus(next_game_state_bus),
  .address(game_address),
  .write_en(processor_writing),
  .done(processor_done)
);

always @(posedge clk) begin
  if (processor_writing) begin
    game_state[game_address] <= next_game_state_bus;
  end
end

endmodule
