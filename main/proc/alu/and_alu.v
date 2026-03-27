module and_alu(A, B, Y);
    input [31:0] A, B;
    output [31:0] Y;

    genvar k;
    generate 
        for (k = 0; k < 32; k = k + 1) begin
            and anding(Y[k], A[k], B[k]);
        end
    endgenerate

endmodule
