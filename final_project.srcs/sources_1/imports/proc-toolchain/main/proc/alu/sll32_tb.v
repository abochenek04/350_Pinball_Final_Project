`timescale 1ns/1ps

module sll32_tb;

  reg  [31:0] A;
  reg  [4:0]  ctrl_shiftamt;
  wire [31:0] out;

  // DUT
  sll32 dut (
    .A(A),
    .ctrl_shiftamt(ctrl_shiftamt),
    .out(out)
  );

  task check;
    input [31:0] a_val;
    input [4:0]  s_val;
    reg   [31:0] expected;
    begin
      A     = a_val;
      ctrl_shiftamt = s_val;
      #1;

      expected = (a_val << s_val); // allowed in TB

      if (out !== expected) begin
        $display("FAIL: A=%h ctrl_shiftamt=%0d (0x%0h) | out=%h expected=%h",
                 A, ctrl_shiftamt, ctrl_shiftamt, out, expected);
        $stop;
      end else begin
        $display("PASS: A=%h ctrl_shiftamt=%0d | out=%h", A, ctrl_shiftamt, out);
      end
    end
  endtask

  integer i;

  initial begin
    $display("---- sll32 testbench start ----");

    // Directed tests
    check(32'h00000000, 5'd0);
    check(32'h00000000, 5'd5);
    check(32'h00000001, 5'd0);
    check(32'h00000001, 5'd1);
    check(32'h00000001, 5'd31);

    check(32'h80000000, 5'd0);
    check(32'h80000000, 5'd1);   // should become 00000000
    check(32'h7FFFFFFF, 5'd1);

    check(32'hFFFFFFFF, 5'd4);
    check(32'h12345678, 5'd8);
    check(32'hDEADBEEF, 5'd16);

    // Sweep all shift amounts for some patterns
    for (i = 0; i < 32; i = i + 1) begin
      check(32'h00000001, i[4:0]);
      check(32'hF0F0F0F0, i[4:0]);
      check(32'h80000001, i[4:0]);
    end

    // Random tests
    for (i = 0; i < 200; i = i + 1) begin
      check($random, $random);
    end

    $display("---- ALL TESTS PASSED ----");
    $finish;
  end

endmodule
