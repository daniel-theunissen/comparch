module dump ();
  initial begin
    $dumpfile("blinky.vcd");
    $dumpvars(0, blinky);
    #1;
  end
endmodule
