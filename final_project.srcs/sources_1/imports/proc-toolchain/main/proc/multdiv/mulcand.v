module mulcand(in, out, clk, clr, en);
    //multiplicand
    input [31:0] in;
    input clk, clr, en;

    output [31:0] out;

    genvar k;
    generate
        for(k = 0; k < 32; k = k + 1) begin
            dffe_ref rest31(.q(out[k]), .d(in[k]), .clk(clk), .en(en), .clr(clr));
        end
    endgenerate

endmodule