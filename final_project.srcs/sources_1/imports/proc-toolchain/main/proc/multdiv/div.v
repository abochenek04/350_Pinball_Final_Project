module div(data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    //make sure both numbers arew positive
    //operantA = divident = Q
    //operandB = divisor = M
    wire [31:0] positive_A, positive_B;
    wire useless, useless2;

    addOrSub A_negative(
        .A(32'b0),
        .B(data_operandA),
        .select(1'b1),
        .S(positive_A),
        .Cout(useless)
    );
    addOrSub B_negative(
        .A(32'b0),
        .B(data_operandB),
        .select(1'b1),
        .S(positive_B),
        .Cout(useless2)
    );

    


    //sign bits of A and B
    wire A_sign, B_sign;
    assign A_sign = data_operandA[31];
    assign B_sign = data_operandB[31];

    //confirmewd GTKWAVE above is NOT THE PROBLEM

    //if sign bit is 1 (-), choose the positive version of that numner
    //if sign bit is 0 (+) just send in dataOperandX

    //operantA = divident = Q
    //operandB = divisor = M
    wire [31:0] M_initial, Q_initial;
    assign M_initial = B_sign ? positive_B : data_operandB;
    assign Q_initial = A_sign ? positive_A : data_operandA;


    //pseudo code outline
    //N = number of bits in divided (32)
    
    //combine A and Q
    //operantA = divident = Q
    //operandB = divisor = M
    wire [63:0] starting_term;
    assign starting_term = {32'b0, Q_initial};


    wire [63:0] divison_register_in;
    wire [63:0] divison_register_out;
    wire [63:0] shifted_divison;

    //for first operation wiht ctrl_div on, use the starting term
    //then switch to the most updated shifed_term
    assign divison_register_in = ctrl_DIV ? starting_term : shifted_divison; 

    reg_64 divison_regsi(
        .in(divison_register_in),
        .out(divison_register_out),
        .clk(clock),
        .en(1'b1),
        .clr(1'b0)
    );

     //check sign bif of A
        //if sign but is 0, 
        //shift left AQ, and A = A - M

        //if sign bit is 1
        //shift left AQ and A = A + M

    //chekcing A before the shift to sse if we should add or sub
    wire before_shifting_sign;
    assign before_shifting_sign = divison_register_out[63];

    //shifting AQ first time (and storing regardless)
    wire [63:0] shift_AQ;
    assign shift_AQ = {divison_register_out[62:0], 1'b0};

    //getting A value after shifting
    wire [31:0] A_post_shift;
    assign A_post_shift = shift_AQ[63:32];

    //similar logic to mult for making negative divisor
    wire [31:0] M;
    assign M = M_initial;

    wire [31:0] negM;
    wire dummy_cout;
    
    addOrSub make_negM(
        .A(32'b0),
        .B(M),
        .select(1'b1),
        .S(negM),
        .Cout(dummy_cout)
    );
    
    //if sign bit is 1, use + M, if 0, use negative M
    wire [31:0] op;
    assign op = before_shifting_sign ? M : negM;

    wire [31:0] A_update;
    wire dummy_cout2;

    //do either A = A + M or A + ~M
    addOrSub add_inst(
        .A(A_post_shift),
        .B(op),
        .select(1'b0),
        .S(A_update),
        .Cout(dummy_cout2)
    );

    wire sign_post_operation;
    assign sign_post_operation = A_update[31];

    //chnage with product_reg_div_out
    assign shifted_divison = {A_update, shift_AQ[31:1], ~sign_post_operation};

    //"subract N" from counter
    wire [4:0] count;
    wire count_done;

    counter_32_div counts_div(
        .cnt(count),
        .done(count_done),
        .clk(clock),
        .en(1'b1), //here for div, make enable work until count is done, not always on
        .clr(ctrl_DIV) //here
    );

    //if N = 0
    //if sign bit of A (MSB) is 1, 
        //A = A + M
    //quotient (output) is in Q, remainder in A

    //if signs differe, make quotient different
    wire division_sign;
    assign division_sign = A_sign ^ B_sign;
    
    wire [31:0] final_div_before;
    assign final_div_before = shifted_divison[31:0];

    wire [31:0] div_changed;
    wire dummy_cout3;
    addOrSub final_time(
        .A(32'b0),
        .B(final_div_before),
        .select(1'b1),
        .S(div_changed),
        .Cout(dummy_cout3)
    );

    wire div_zero;
    assign div_zero = ~(|data_operandB);

    wire [31:0] last_check;
    assign last_check = division_sign ? div_changed : final_div_before;

    assign data_result = div_zero ? 32'b0 : last_check;
    assign data_resultRDY = count_done;
    
    

    assign data_exception = div_zero & count_done;

endmodule