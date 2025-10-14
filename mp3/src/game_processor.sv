// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module game_processor (
  input  clk,
  input start,
  input [7:0] game_state_bus,
  output wire [7:0] next_game_state_bus,
  output reg [2:0] address,
  output wire write_en,
  output wire done
);

localparam LOADING = 0, CALCULATING = 1, WRITING = 2, DONE = 3;
reg [1:0] state = DONE;
reg [1:0] next_state;
reg [7:0] game_state [8];
reg [7:0] next_game_state [8];

initial begin
    address = 0;
end

reg [2:0] i = 0;
reg [2:0] j = 0;
reg [4:0] total = 0;

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

assign done = (state == DONE);
assign write_en = (state == WRITING);

always_ff @(posedge clk) begin
  state <= next_state;
end

wire calculating_done;
assign calculating_done = ((j == 3'd7) & (i == 3'd7));

always_ff @(negedge clk) begin
  if (state == CALCULATING) begin
    total <=
    game_state[j][(i-1) % 8] + game_state[j][(i+1) % 8] +
    game_state[(j-1) % 8][i] + game_state[(j+1) % 8][i] +
    game_state[(j-1) % 8][(i-1) % 8] + game_state[(j+1) % 8][(i-1) % 8] +
    game_state[(j-1) % 8][(i+1) % 8] + game_state[(j+1) % 8][(i+1) % 8];
  end
end

always_ff @(posedge clk) begin
  if (state == CALCULATING) begin
    if (i == 3'd7) begin
        j <= j + 1;
        i <= 0;
        end else begin
        i <= i + 1;
    end

    if (game_state[j][i]) begin
        if ((total < 5'd2) || (total > 5'd3)) begin
        next_game_state[j][i] <= 0;
        end else begin
        next_game_state[j][i] <= 1;
        end
    end else if (total == 5'd3) begin
        next_game_state[j][i] <= 1;
    end else begin
        next_game_state[j][i] <= 0;
    end
  end
end

wire writing_done;
assign writing_done = (address == 3'd7);

wire loading_done;
assign loading_done = (address == 3'd7);

always_ff @(posedge clk) begin
    if ((state == LOADING) || (state == WRITING)) begin
        address <= address + 1;
    end
end

assign next_game_state_bus = next_game_state[address];

always_ff @(posedge clk) begin
    if (state == LOADING) begin
        game_state[address] <= game_state_bus;
    end
end

endmodule

