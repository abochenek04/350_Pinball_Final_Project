module overflowing(prod, of);
    input [64:0] prod;
    output of;

    wire sign;
    wire [31:0] all_bits;
    assign sign = prod[32];

    genvar k;
    generate
        for(k = 0; k < 32; k = k + 1) begin
            xor handsome_man(all_bits[k], sign, prod[k+33]);
        end
    endgenerate


    assign of = |all_bits;

endmodule