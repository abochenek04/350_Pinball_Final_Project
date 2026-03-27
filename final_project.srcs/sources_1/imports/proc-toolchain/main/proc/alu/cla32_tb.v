`timescale 1ns/1ps

module cla32_tb;

    reg  [31:0] A;
    reg  [31:0] B;
    reg         Cin;

    wire [31:0] S;
    wire        Cout;

    // expected (33 bits so we can check Cout + S together)
    reg  [32:0] expected;

    integer i;

    // DUT
    cla32 dut(
        .A(A),
        .B(B),
        .Cin(Cin),
        .S(S),
        .Cout(Cout)
    );

    // small helper task: apply vectors + check
    task apply_and_check;
        input [31:0] a_in;
        input [31:0] b_in;
        input        cin_in;
        begin
            A   = a_in;
            B   = b_in;
            Cin = cin_in;
            #5;

            expected = {1'b0, A} + {1'b0, B} + Cin;

            if ({Cout, S} !== expected) begin
                $display("FAIL: A=%h B=%h Cin=%b | got Cout=%b S=%h | exp Cout=%b S=%h",
                         A, B, Cin, Cout, S, expected[32], expected[31:0]);
                $stop;
            end else begin
                $display("PASS: A=%h B=%h Cin=%b | Cout=%b S=%h",
                         A, B, Cin, Cout, S);
            end
        end
    endtask

    initial begin
        $display("---- cla32 testbench ----");

        // Directed edge cases
        apply_and_check(32'h00000000, 32'h00000000, 1'b0);
        apply_and_check(32'h00000000, 32'h00000000, 1'b1);
        apply_and_check(32'h00000001, 32'h00000001, 1'b0);
        apply_and_check(32'h0000000F, 32'h00000001, 1'b1);

        // Overflow-style checks
        apply_and_check(32'hFFFFFFFF, 32'h00000001, 1'b0); // expect S=0, Cout=1
        apply_and_check(32'hFFFFFFFF, 32'hFFFFFFFF, 1'b0); // expect S=FFFFFFFE, Cout=1
        apply_and_check(32'h80000000, 32'h80000000, 1'b0); // expect S=0, Cout=1

        // Some patterned values
        apply_and_check(32'h55555555, 32'h33333333, 1'b0);
        apply_and_check(32'hAAAAAAAA, 32'h11111111, 1'b1);

        // Random tests
        for (i = 0; i < 200; i = i + 1) begin
            apply_and_check($random, $random, $random);
        end

        $display("ALL TESTS PASSED ✅");
        $finish;
    end

endmodule
