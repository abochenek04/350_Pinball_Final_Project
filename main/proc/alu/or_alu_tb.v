`timescale 1ns/1ps

module or_alu_tb;

  reg  [31:0] A, B;
  wire [31:0] Y;

  // DUT: change "or32" to your module name
  or_alu dut (
    .A(A),
    .B(B),
    .Y(Y)
  );

  task check;
    input [31:0] a_in;
    input [31:0] b_in;
    reg   [31:0] expected;
    begin
      A = a_in;
      B = b_in;
      #1;
      expected = a_in | b_in;

      if (Y !== expected) begin
        $display("FAIL: A=%h B=%h | Y=%h expected=%h", A, B, Y, expected);
        $stop;
      end else begin
        $display("PASS: A=%h B=%h | Y=%h", A, B, Y);
      end
    end
  endtask

  integer i;

  initial begin
    $display("---- 32-bit OR testbench start ----");

    // Directed tests (edge + patterns)
    check(32'h00000000, 32'h00000000); // 0
    check(32'hFFFFFFFF, 32'hFFFFFFFF); // all 1s
    check(32'hFFFFFFFF, 32'h00000000); // all 1s
    check(32'h00000000, 32'hFFFFFFFF); // all 1s

    check(32'hAAAAAAAA, 32'h55555555); // should be FFFFFFFF
    check(32'hAAAAAAAA, 32'h00000000); // should be AAAAAAAA
    check(32'h12345678, 32'hFFFF0000); // should be FFFF5678
    check(32'hDEADBEEF, 32'h0F0F0F0F); // spot-checkable

    // Random tests
    for (i = 0; i < 50; i = i + 1) begin
      check($random, $random);
    end

    $display("---- ALL TESTS PASSED ----");
    $finish;
  end

endmodule
