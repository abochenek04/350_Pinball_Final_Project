//shift a 32 bit value right by 1. 
//if select bit is 1, include 1 for beggining, if sel = 0, dont
module sra1(A, select, out);
    input [31:0] A;
    input select;

    output [31:0] out;
    wire [31:0] shift_wire_right;

    assign shift_wire_right = {A[31], A[31:1]};
    //out gets shift_wire_right if select is 1, otherwise gets A
    assign out = select ? shift_wire_right : A;


endmodule