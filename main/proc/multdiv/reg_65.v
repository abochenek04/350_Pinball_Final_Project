module reg_65(in, out, clk, clr, en);
    //multiplicand
    input [64:0] in;
    input clk, clr, en;

    output [64:0] out;

    genvar k;
    generate
        for(k = 0; k < 65; k = k + 1) begin
            dffe_ref rest31(.q(out[k]), .d(in[k]), .clk(clk), .en(en), .clr(clr));
        end
    endgenerate

endmodule