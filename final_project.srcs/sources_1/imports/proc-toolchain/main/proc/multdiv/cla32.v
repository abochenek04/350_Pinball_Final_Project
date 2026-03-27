module cla32(A, B, Cin, S, Cout);
    input [31:0] A, B;
    input Cin;

    output [31:0] S;
    output Cout;

    wire P0, P1, P2, P3;
    wire G0, G1, G2, G3;

    wire Cout1, Cout2, Cout3, Cout4;


    //c8 = G0 + P0Cin
    wire c8, c8_out;
    and c8o1(c8_out, P0, Cin);
    or c8or(c8, G0, c8_out);

    //c16 = G1 + P1G0 + P1P0Cin
    wire c16, c16_out, c16_out2;
    and c16o1(c16_out, P1, G0);
    and c16o2(c16_out2, P1, P0, Cin);
    or c16o3(c16, G1, c16_out, c16_out2);


    //c24 = G2 + P2G1 + P2P1G0 + P2P1P0Cin
    wire c24, c24_out, c24_out2, c24_out3;
    and c24o1(c24_out, P2, G1);
    and c24o2(c24_out2, P2, P1, G0);
    and c24o3(c24_out3, P2, P1, P0, Cin);
    or c24or(c24, G2, c24_out, c24_out2, c24_out3);

    
    //c32 = G3 + P3G2 + P3P2G1 + P3P2P1G0 + P3P2P1P0Cin
    wire c32_out, c32_out2, c32_out3, c32_out4;
    and c32o1(c32_out, P3, G2);
    and c32o2(c32_out2, P3, P2, G1);
    and c32o3(c32_out3, P3, P2, P1, G0);
    and c32o4(c32_out4, P3, P2, P1, P0, Cin);
    or c32or(Cout, G3, c32_out, c32_out2, c32_out3, c32_out4);


    cla8 first_quarter(A[7:0], B[7:0], Cin, S[7:0], Cout1, P0, G0);
    cla8 second_quarter(A[15:8], B[15:8], c8, S[15:8], Cout2, P1, G1);
    cla8 third_quarter(A[23:16], B[23:16], c16, S[23:16], Cout3, P2, G2);
    cla8 last_part(A[31:24], B[31:24], c24, S[31:24], Cout4, P3, G3);


endmodule