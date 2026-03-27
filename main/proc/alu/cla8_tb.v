`timescale 1ns/1ps

module cla8_tb;

    reg  [7:0] A;
    reg  [7:0] B;
    reg        Cin;
    wire [7:0] S;
    wire       Cout;

    // Instantiate DUT
    cla8 dut (
        .A(A),
        .B(B),
        .Cin(Cin),
        .S(S),
        .Cout(Cout)
    );

    initial begin
        $display(" A        B        Cin | Cout  S");
        $display("----------------------------------");

        // Test 1: simple add
        A = 8'b00000001; B = 8'b00000001; Cin = 0;
        #10 $display("%b %b   %b   |  %b   %b", A, B, Cin, Cout, S);

        // Test 2: add with carry-in
        A = 8'b00001111; B = 8'b00000001; Cin = 1;
        #10 $display("%b %b   %b   |  %b   %b", A, B, Cin, Cout, S);

        // Test 3: random values
        A = 8'b01010101; B = 8'b00110011; Cin = 0;
        #10 $display("%b %b   %b   |  %b   %b", A, B, Cin, Cout, S);

        // Test 4: max + 1 (overflow)
        A = 8'b11111111; B = 8'b00000001; Cin = 0;
        #10 $display("%b %b   %b   |  %b   %b", A, B, Cin, Cout, S);

        // Test 5: max + max
        A = 8'b11111111; B = 8'b11111111; Cin = 0;
        #10 $display("%b %b   %b   |  %b   %b", A, B, Cin, Cout, S);

        // Test 6: random + carry-in
        A = 8'b10011001; B = 8'b01100110; Cin = 1;
        #10 $display("%b %b   %b   |  %b   %b", A, B, Cin, Cout, S);

        $finish;
    end

endmodule
