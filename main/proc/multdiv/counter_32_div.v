module counter_32_div(cnt, done, clk, en, clr);
    input clk, en, clr;
    output [4:0] cnt;
    output done;

    //tff inputs
    wire [4:0] w1;

    //tff output
    wire [4:0] q;

    //lsb schematic slides
    //flips pattern from
    assign w1[0] = en;
    assign w1[1] = en & q[0];
    assign w1[2] = en & q[0] & q[1];
    assign w1[3] = en & q[0] & q[1] & q[2];
    assign w1[4] = en & q[0] & q[1] & q[2] & q[3];


    genvar k;
    generate 
        for(k = 0; k < 5; k = k + 1) begin
            tff tff_one(
            .q(q[k]),
            .t(w1[k]),
            .clk(clk), 
            .en(1'b1), 
            .clr(clr)
            );
        end
    endgenerate

    assign cnt = q;
    //done is 1 when all q bits are 1 
    assign done = q[0] & q[1] & q[2] & q[3] & q[4];

endmodule