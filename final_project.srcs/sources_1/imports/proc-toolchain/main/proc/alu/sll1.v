//shift a 32 bit value left by 1 if select bit is 1, if sel = 0, dont
module sll1(A, select, out);
    input [31:0] A;
    input select;

    output [31:0] out;
    wire [31:0] shift_wire;

    assign shift_wire = {A[30:0], 1'b0};
    assign out = select ? shift_wire : A;

endmodule