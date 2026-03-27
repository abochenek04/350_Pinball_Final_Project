`timescale 1ns/1ps

module addOrSub_tb;

  reg  [31:0] A, B;
  reg         select;          // 0 = add, 1 = sub
  wire [31:0] S;
  wire        Cout;

  // DUT (change module name here if needed)
  addOrSub dut(A, B, select, S, Cout);

  task check;
    input [31:0] a_val;
    input [31:0] b_val;
    input        sub_val;
    reg   [32:0] expected_full;
    reg   [31:0] expected_S;
    reg          expected_Cout;
    begin
      A   = a_val;
      B   = b_val;
      select = sub_val;
      #1;

      // Use Verilog arithmetic in TB (allowed)
      if (sub_val == 1'b0)
        expected_full = {1'b0, a_val} + {1'b0, b_val};
      else
        expected_full = {1'b0, a_val} - {1'b0, b_val};

      expected_S    = expected_full[31:0];
      expected_Cout = expected_full[32]; // carry out / borrow bit behavior depends on adder style

      if (S !== expected_S) begin
        $display("FAIL: A=%h B=%h select=%b | S=%h expected=%h (full=%h)",
                 A, B, select, S, expected_S, expected_full);
        $stop;
      end else begin
        $display("PASS: A=%h B=%h select=%b | S=%h", A, B, select, S);
      end

      // Optional: also check Cout if you care (can comment out if not required)
      if (Cout !== expected_Cout) begin
        $display("WARN: Cout mismatch: A=%h B=%h select=%b | Cout=%b expected=%b",
                 A, B, select, Cout, expected_Cout);
      end
    end
  endtask

  integer i;

  initial begin
    $display("---- addsub32 testbench start ----");

    // Directed ADD tests
    check(32'h00000000, 32'h00000000, 1'b0);
    check(32'h00000001, 32'h00000001, 1'b0);
    check(32'hFFFFFFFF, 32'h00000001, 1'b0);
    check(32'h7FFFFFFF, 32'h00000001, 1'b0);
    check(32'h80000000, 32'h80000000, 1'b0);

    // Directed SUB tests
    check(32'h00000000, 32'h00000000, 1'b1);
    check(32'h00000001, 32'h00000001, 1'b1);
    check(32'h00000000, 32'h00000001, 1'b1);
    check(32'h00000005, 32'h00000003, 1'b1);
    check(32'h80000000, 32'h00000001, 1'b1);
    check(32'h7FFFFFFF, 32'hFFFFFFFF, 1'b1);

    // Random tests
    for (i = 0; i < 200; i = i + 1) begin
      check($random, $random, 1'b0);
      check($random, $random, 1'b1);
    end

    $display("---- ALL TESTS PASSED ----");
    $finish;
  end

endmodule
