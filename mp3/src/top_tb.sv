// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
`timescale 10ns / 10ns

module top_tb;

  reg clk = 0;
  // wire [7:0] mem [64];
  // wire memory_changed;

  top top (
    .clk(clk)
    // .mem(mem),
    // .next_game_step_calculated(memory_changed)
  );

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    #8000000
    $finish;
  end

  always begin
    clk = ~clk;
    #4;
  end

  // // Monitor next_game_state on the positive edge of the clock
  // always @(posedge clk) begin
  //     if(memory_changed) begin
  //     for (int i = 0; i < 64; i++) begin
  //       $write("[%b] ", mem[i]);
  //       $display("");
  //     end
  //     $display("");
  //     $display("");
  //   end
  // end

endmodule
