module reg_32(d, clk, ena, q, clr);
    input [31:0] d;
    input clk, ena, clr;

    output [31:0] q;

    genvar k;
    generate 
        for (k = 0; k < 32; k = k + 1) begin
            dffe_ref banana(
                .d(d[k]), 
                .clk(clk), 
                .en(ena), 
                .q(q[k]), 
                .clr(clr)
            );
        end
    endgenerate

endmodule