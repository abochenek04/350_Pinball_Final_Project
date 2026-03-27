`timescale 1ns/1ps

module sra16_tb;

  reg  [31:0] A;
  reg         select;
  wire [31:0] out;

  // DUT: change "sra16" and port names if yours differ
  sra16 dut (
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

      // arithmetic right shift by 16 when sel=1, else passthrough
      expected = sel_val ? {{16{in_val[31]}}, in_val[31:16]} : in_val;

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
    $display("---- sra16 testbench start ----");

    // Passthrough tests (sel=0)
    check(32'h00000000, 1'b0);
    check(32'hFFFFFFFF, 1'b0);
    check(32'h80000000, 1'b0);
    check(32'h12345678, 1'b0);

    // Arithmetic shift tests (sel=1)
    check(32'h00000001, 1'b1); // -> 00000000
    check(32'h00008000, 1'b1); // -> 00000000
    check(32'h12345678, 1'b1); // -> 00001234

    check(32'h80000000, 1'b1); // -> FFFF8000 (sign-extend)
    check(32'hFFFF0000, 1'b1); // -> FFFFFFFF (sign-extend)
    check(32'hFFFFFFFF, 1'b1); // -> FFFFFFFF

    // Random tests
    for (i = 0; i < 50; i = i + 1) begin
      check($random, 1'b0);
      check($random, 1'b1);
    end

    $display("---- ALL TESTS PASSED ----");
    $finish;
  end

endmodule
