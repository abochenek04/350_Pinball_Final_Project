`timescale 1ns/1ps

module sll16_tb;

  reg  [31:0] A;
  reg         select;
  wire [31:0] out;

  // DUT: change "sll16" and port names if needed
  sll16 dut (
    .A(A),
    .select(select),
    .out(out)
  );

  task check;
    input [31:0] in_val;
    input        sel_val;
    reg   [31:0] expected;
    begin
      A      = in_val;
      select = sel_val;
      #1;

      expected = sel_val ? {in_val[15:0], 16'b0} : in_val;

      if (out !== expected) begin
        $display("FAIL: A=%h sel=%b | out=%h expected=%h", A, select, out, expected);
        $stop;
      end else begin
        $display("PASS: A=%h sel=%b | out=%h", A, select, out);
      end
    end
  endtask

  integer i;

  initial begin
    $display("---- sll16 testbench start ----");

    // Directed tests
    check(32'h00000000, 1'b0);
    check(32'h00000000, 1'b1);

    check(32'hFFFFFFFF, 1'b0);
    check(32'hFFFFFFFF, 1'b1); // expect FFFF0000

    check(32'h0000ABCD, 1'b1); // expect ABCD0000
    check(32'hABCD0000, 1'b1); // expect 00000000 (upper half shifts out)

    check(32'h12345678, 1'b1); // expect 56780000
    check(32'h80000000, 1'b1); // expect 00000000

    // Random tests (both sel=0 and sel=1)
    for (i = 0; i < 50; i = i + 1) begin
      check($random, 1'b0);
      check($random, 1'b1);
    end

    $display("---- ALL TESTS PASSED ----");
    $finish;
  end

endmodule
