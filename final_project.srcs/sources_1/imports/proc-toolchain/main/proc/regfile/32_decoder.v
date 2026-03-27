module decoder32(out, RD, WE);
    input [4:0] RD;
    input WE;
    output [31:0] out;

    wire [31:0] decode_out;

    assign decode_out = 32'b1 << RD;

    genvar k;
    generate
        for (k = 0; k < 32; k = k + 1) begin
            and dec_we(out[k], decode_out[k], WE);
        end 
    endgenerate
endmodule