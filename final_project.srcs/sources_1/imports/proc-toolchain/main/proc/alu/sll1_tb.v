`timescale 1ns/1ps

module sll1_tb;

  reg  [31:0] A;
  reg         select;
  wire [31:0] out;

  // DUT: make sure the module name matches your file
  sll1 dut (
    .A(A),
    .select(select),
    .out(out)
  );

  task check;
    input [31:0] in_val;
    input        sel_val;
    reg   [31:0] expected;
    begin
      A  = in_val;
      select = sel_val;
      #1;

      // expected behavior for this stage
      expected = sel_val ? {in_val[30:0], 1'b0} : in_val;

      if (out !== expected) begin
        $display("FAIL: in=%h sel=%b | out=%h expected=%h", A, select, out, expected);
        $stop;
      end else begin
        $display("PASS: in=%h sel=%b | out=%h", A, select, out);
      end
    end
  endtask

  integer i;

  initial begin
    $display("---- sll_stage1 testbench start ----");

    // Directed tests
    check(32'h00000000, 1'b0);
    check(32'h00000000, 1'b1);

    check(32'hFFFFFFFF, 1'b0);
    check(32'hFFFFFFFF, 1'b1); // should become FFFFFFFE

    check(32'h80000000, 1'b1); // MSB shifts out -> 0
    check(32'h00000001, 1'b1); // becomes 00000002
    check(32'hAAAAAAAA, 1'b1);

    // Random tests (both sel=0 and sel=1)
    for (i = 0; i < 50; i = i + 1) begin
      check($random, 1'b0);
      check($random, 1'b1);
    end

    $display("---- ALL TESTS PASSED ----");
    $finish;
  end

endmodule