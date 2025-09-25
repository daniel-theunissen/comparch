module dump ();
  initial
  begin
    $dumpfile("fader.vcd");
    $dumpvars(0, fader);
    #1;
  end
endmodule
