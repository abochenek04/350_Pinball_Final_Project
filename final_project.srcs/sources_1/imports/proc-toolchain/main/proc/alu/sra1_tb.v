`timescale 1ns/1ps

module sra1_tb;

  reg  [31:0] A;
  reg         select;
  wire [31:0] out;

  // DUT: change module/port names if yours differ
  sra1 dut (
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

      // SRA by 1 when sel=1, otherwise passthrough
      expected = sel_val ? {in_val[31], in_val[31:1]} : in_val;

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
    $display("---- sra1 testbench start ----");

    // Directed tests (sel=0 passthrough)
    check(32'h00000000, 1'b0);
    check(32'hFFFFFFFF, 1'b0);
    check(32'h80000000, 1'b0);

    // Directed tests (sel=1 arithmetic right shift by 1)
    check(32'h00000001, 1'b1); // -> 00000000
    check(32'h00000002, 1'b1); // -> 00000001
    check(32'h7FFFFFFF, 1'b1); // -> 3FFFFFFF (MSB=0 fills 0)
    check(32'h80000000, 1'b1); // -> C0000000 (MSB=1 fills 1)
    check(32'hFFFFFFFF, 1'b1); // -> FFFFFFFF (stays -1)
    check(32'h90000001, 1'b1); // negative, should keep MSB=1

    // Random tests (both sel=0 and sel=1)
    for (i = 0; i < 50; i = i + 1) begin
      check($random, 1'b0);
      check($random, 1'b1);
    end

    $display("---- ALL TESTS PASSED ----");
    $finish;
  end

endmodule
