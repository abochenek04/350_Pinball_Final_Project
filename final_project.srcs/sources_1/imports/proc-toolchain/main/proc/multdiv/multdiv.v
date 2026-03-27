module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    wire [31:0] multiplication_res;
    wire multiplication_ex, multiplicaition_rdy;

   //latch the mult or divison command

    mult multiplcaition_doer(
        .data_operandA(data_operandA),
        .data_operandB(data_operandB),
        .ctrl_MULT(ctrl_MULT),
        .ctrl_DIV(ctrl_DIV),
        .clock(clock),
        .data_result(multiplication_res),
        .data_exception(multiplication_ex),
        .data_resultRDY(multiplicaition_rdy)
    );

    wire [31:0] division_res;
    wire division_ex, division_rdy;

    div division_doer(
        .data_operandA(data_operandA),
        .data_operandB(data_operandB),
        .ctrl_MULT(ctrl_MULT),
        .ctrl_DIV(ctrl_DIV),
        .clock(clock),
        .data_result(division_res),
        .data_exception(division_ex),
        .data_resultRDY(division_rdy)
    );

    wire finish;
    dffe_ref latch(
        .q(finish),
        .d(1'b1),
        .clk(clock),
        .en(ctrl_MULT | ctrl_DIV),
        .clr(ctrl_DIV)
    );

    assign data_result = finish ? multiplication_res : division_res;
    assign data_exception = finish ? multiplication_ex : division_ex;
    assign data_resultRDY = finish ? multiplicaition_rdy : division_rdy;

    
endmodule