module reg_64(in, out, clk, clr, en);
    //multiplicand
    input [63:0] in;
    input clk, clr, en;

    output [63:0] out;

    genvar k;
    generate
        for(k = 0; k < 64; k = k + 1) begin
            dffe_ref rest31(.q(out[k]), .d(in[k]), .clk(clk), .en(en), .clr(clr));
        end
    endgenerate

endmodule