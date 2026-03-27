module cla8(A, B, Cin, S, Cout, p_b, g_b);

    input [7:0] A, B;
    input Cin;

    output [7:0] S;
    output Cout;
    output p_b, g_b;

    ///propogates (0,7)
    wire p0, p1, p2, p3, p4, p5, p6, p7;
    //generates (0,7)
    wire g0, g1, g2, g3, g4, g5, g6, g7;

    or px0(p0, A[0], B[0]);
    or px1(p1, A[1], B[1]);
    or px2(p2, A[2], B[2]);
    or px3(p3, A[3], B[3]);
    or px4(p4, A[4], B[4]);
    or px5(p5, A[5], B[5]);
    or px6(p6, A[6], B[6]);
    or px7(p7, A[7], B[7]);

    and gx0(g0, A[0], B[0]);
    and gx1(g1, A[1], B[1]);
    and gx2(g2, A[2], B[2]);
    and gx3(g3, A[3], B[3]);
    and gx4(g4, A[4], B[4]);
    and gx5(g5, A[5], B[5]);
    and gx6(g6, A[6], B[6]);
    and gx7(g7, A[7], B[7]);

    wire c1, c2, c3, c4, c5, c6, c7; //where c0 = Cin

    //expanded logic for look ahead adders

    //c1 = g0 + p0C0
    wire c1_out;
    and c1o(c1_out, p0, Cin);
    or c1or(c1, c1_out, g0);

    //c2 = g1 + p1g0 + p1p0Cin
    wire c2_out, c2_out2;
    and c2o(c2_out, p1, g0);
    and c202(c2_out2, p1, p0, Cin);
    or c2or(c2, c2_out, c2_out2, g1);

    //c3 = g2 + p2g1 + p2p1g0 + p2p1p0cin
    wire c3_out, c3_out2, c3_out3;
    and c3o(c3_out, p2, g1);
    and c3o2(c3_out2, p2, p1, g0);
    and c3o3(c3_out3, p2, p1, p0, Cin);
    or c3or(c3, c3_out, c3_out2, c3_out3, g2);

    //c4 = g3 + p3g2 + p3p2g1 + p3p2p1g0 + p3p2p1p0cin
    wire c4_out, c4_out2, c4_out3, c4_out4;
    and c4o(c4_out, p3, g2);
    and c4o2(c4_out2, p3, p2, g1);
    and c403(c4_out3, p3, p2, p1, g0);
    and c404(c4_out4, p3, p2, p1, p0, Cin);
    or c4or(c4, c4_out, c4_out2, c4_out3, c4_out4, g3);

    //c5 = g4 + p4g3 + p4p3g2 + p4p3p2g1 + p4p3p2p1g0 + p4p3p2p1Cin
    wire c5_out, c5_out2, c5_out3, c5_out4, c5_out5;
    and c5o(c5_out, p4, g3);
    and c5o2(c5_out2, p4, p3, g2);
    and c5o3(c5_out3, p4, p3, p2, g1);
    and c5o4(c5_out4, p4, p3, p2, p1, g0);
    and c5o5(c5_out5, p4, p3, p2, p1, p0, Cin);
    or c5or(c5, g4, c5_out, c5_out2, c5_out3, c5_out4, c5_out5);

    //c6 = g5 + p5g4 + p5p4g3 + p5p4p3g2 + p5p4p3p2g1 + p5p4p3p2p1g0 + p5p4p3p2p1p0Cin
    wire c6_out, c6_out2, c6_out3, c6_out4, c6_out5, c6_out6;
    and c6o(c6_out, p5, g4);
    and c6o2(c6_out2, p5, p4, g3);
    and c6o3(c6_out3, p5, p4, p3, g2);
    and c6o4(c6_out4, p5, p4, p3, p2, g1);
    and c6o5(c6_out5, p5, p4, p3, p2, p1, g0);
    and c6o6(c6_out6, p5, p4, p3, p2, p1, p0, Cin);
    or c6or(c6, g5, c6_out, c6_out2, c6_out3, c6_out4, c6_out5, c6_out6);


    //c7 = g6 + p6g5 + p6p5g4 + p6p5p4g3 + p6p5p4p3g2 + p6p5p4p3p2g1 + p6p5p4p3p2p1g0 + p6p5p4p3p2p1p0Cin
    wire c7_out, c7_out2, c7_out3, c7_out4, c7_out5, c7_out6, c7_out7;
    and c7o(c7_out, p6, g5);
    and c7o2(c7_out2, p6, p5, g4);
    and c7o3(c7_out3, p6, p5, p4, g3);
    and c7o4(c7_out4, p6, p5, p4, p3, g2);
    and c7o5(c7_out5, p6, p5, p4, p3, p2, g1);
    and c7o6(c7_out6, p6, p5, p4, p3, p2, p1, g0);
    and c7o7(c7_out7, p6, p5, p4, p3, p2, p1, p0, Cin);
    or c7or(c7, g6, c7_out, c7_out2, c7_out3, c7_out4, c7_out5, c7_out6, c7_out7);

    //c8 
    wire c8_out, c8_out2, c8_out3, c8_out4, c8_out5, c8_out6, c8_out7, c8_out8;
    and c8o(c8_out, p7, g6);
    and c8o2(c8_out2, p7, p6, g5);
    and c8o3(c8_out3, p7, p6, p5, g4);
    and c8o4(c8_out4, p7, p6, p5, p4, g3);
    and c8o5(c8_out5, p7, p6, p5, p4, p3, g2);
    and c8o6(c8_out6, p7, p6, p5, p4, p3, p2, g1);
    and c8o7(c8_out7, p7, p6, p5, p4, p3, p2, p1, g0);
    and c8o8(c8_out8, p7, p6, p5, p4, p3, p2, p1, p0, Cin);
    or c8or(Cout, g7, c8_out, c8_out2, c8_out3, c8_out4, c8_out5, c8_out6, c8_out7, c8_out8);


    //sum
    xor sum0(S[0], A[0], B[0], Cin);
    xor sum1(S[1], A[1], B[1], c1);
    xor sum2(S[2], A[2], B[2], c2);
    xor sum3(S[3], A[3], B[3], c3);
    xor sum4(S[4], A[4], B[4], c4);
    xor sum5(S[5], A[5], B[5], c5);
    xor sum6(S[6], A[6], B[6], c6);
    xor sum7(S[7], A[7], B[7], c7);

    //pblock p7p6p5p4p3p2p1p0
    and pblock(p_b, p0, p1, p2, p3, p4, p5, p6, p7);
    
    //gblock g7 + p7g6 + p7p6g5 + p7p6p5g4 + p7p6p5p4g3 + p7p6p5p4p3g2 + p7p6p5p4p3p2g1 + p7p6p5p4p3p2p1g0
    wire g_b1, g_b2, g_b3, g_b4, g_b5, g_b6, g_b7;
    and g_block1(g_b1, p7, g6);
    and g_block2(g_b2, p7, p6, g5);
    and g_block3(g_b3, p7, p6, p5, g4);
    and g_block4(g_b4, p7, p6, p5, p4, g3);
    and g_block5(g_b5, p7, p6, p5, p4, p3, g2);
    and g_block6(g_b6, p7, p6, p5, p4, p3, p2, g1);
    and g_block7(g_b7, p7, p6, p5, p4, p3, p2, p1, g0);
    or g_blockOr(g_b, g7, g_b1, g_b2, g_b3, g_b4, g_b5, g_b6, g_b7);

endmodule