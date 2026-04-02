module tff (q, t, clk, en, clr);
    input t, clk, en, clr;
    output q;

    wire w1, w2, w3, w4, w5;

    assign w1 = ~t;
    assign w5 = ~q;

    // ~t and q
    and topAnd(w2, w1, q);
    //t and ~q
    and bottomAnd(w3, t, w5);

    //ors the top ands
    or onlyOr(w4, w2, w3);

    dffe_ref dflip(q, w4, clk, en, clr);
endmodule