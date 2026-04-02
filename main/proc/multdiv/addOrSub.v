module addOrSub(A, B, select, S, Cout);
    input [31:0] A, B;
    input select;

    output [31:0] S;
    output Cout;

    wire [31:0] negB;

    genvar k;
    generate
        for(k = 0; k < 32; k = k +1) begin
            xor suber(negB[k], B[k], select);
        end
    endgenerate

    //if add, select = 0 and A+B
    //if sub, select = 1 and A + ~B + 1
    cla32 add_sub(A, negB, select, S, Cout);
endmodule