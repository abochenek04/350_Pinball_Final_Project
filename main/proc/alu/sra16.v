//shift a 32 bit value right by 16. 
//if select bit is 1, include 1s for beggining, if sel = 0, dont
module sra16(A, select, out);
    input [31:0] A;
    input select;

    output [31:0] out;
    wire [31:0] shift_wire_right;

    //fill in beggining (2) with with signed bit
    assign shift_wire_right = {{16{A[31]}}, A[31:16]};
    //out gets shift_wire_right if select is 1, otherwise gets A
    assign out = select ? shift_wire_right : A;

endmodule