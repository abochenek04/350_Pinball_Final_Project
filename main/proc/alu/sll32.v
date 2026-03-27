module sll32(A, ctrl_shiftamt, out);
    input [31:0] A;
    input [4:0] ctrl_shiftamt;

    output [31:0] out;
    wire [31:0] w1, w2, w3, w4;

    sll1 one_shift(A, ctrl_shiftamt[0], w1);
    sll2 two_shift(w1, ctrl_shiftamt[1], w2);
    sll4 four_shift(w2, ctrl_shiftamt[2], w3);
    sll8 eight_shift(w3, ctrl_shiftamt[3], w4);
    sll16 sxt_shift(w4, ctrl_shiftamt[4], out);
    
endmodule