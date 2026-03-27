module mult(data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    wire [64:0] starting_term;
    assign starting_term = {32'b0, data_operandB, 1'b0};

    //for first time, use starting term, then use product register afterwards )=(how do make sure this works?)
    wire [64:0] product_register_in;
    wire [64:0] product_register_out;
    wire [64:0] shifted_product;
    assign product_register_in = ctrl_MULT ? starting_term : shifted_product; 


    reg_65 product_regsi(
        .in(product_register_in),
        .out(product_register_out),
        .clk(clock),
        .en(1'b1),
        .clr(1'b0)
    );

    //a mux, that loks at the two last bits (which are select) and then passes through 
    //the according informatiopn, instead of boother
    wire [31:0] A;
    assign A = product_register_out[64:33];

    wire [1:0] booth_sel;
    assign booth_sel = product_register_out[1:0];

    wire [31:0] operation;
    wire [31:0] update;
    wire cout_add;

    wire [31:0] M;
    assign M = data_operandA;

    wire [31:0] negM;
    wire dummy_cout;
    
    addOrSub make_negM(
        .A(32'b0),
        .B(M),
        .select(1'b1),
        .S(negM),
        .Cout(dummy_cout)
    );

    mux_4 #(.WIDTH(32)) muxing(
        .out(operation),
        .select(booth_sel),
        .in0(32'b0),
        .in1(M),
        .in2(negM),
        .in3(32'b0)
    );

    addOrSub add_inst(
        .A(A),
        .B(operation),
        .select(1'b0),
        .S(update),
        .Cout(cout_add)
    );
    
    //alu added
    wire [64:0] after_ALU;
    assign after_ALU = {update, product_register_out[32:0]};

    //arithmetic right shift
    assign shifted_product = {after_ALU[64], after_ALU[64:1]};

    wire [5:0] count;
    wire count_done;

    counter_32 counts(
        .cnt(count),
        .done(count_done),
        .clk(clock),
        .en(1'b1), //here
        .clr(ctrl_MULT) //here
    );

    wire overflow;
    overflowing hello_sir(
        .prod(product_register_out),
        .of(overflow)
    );

    //oberflow is m issing one thign

    assign data_result = product_register_out[32:1];
    assign data_resultRDY = count_done;

    //check special cases
    //when max negative times negative
    wire w1, w2, w3, w4, w5, w6;
    wire overflow_1;
    wire overflow_2;
    wire overflow_3;
    wire negated1, negated2;
    wire overall_overflow;

    assign w1 = &data_operandB;
    assign w2 = ~(|data_operandA[30:0]) & data_operandA[31];
    and(overflow_1, w1, w2);

    assign w3 = &data_operandA;
    assign w4 = ~(|data_operandB[30:0]) & data_operandB[31];
    and(overflow_2, w3, w4);

    and(overflow_3, w2, w4);

    or(overall_overflow, overflow_1, overflow_2, overflow_3);

    assign w5 = ~(|data_operandB[31:1]) & data_operandB[0];
    assign w6 = ~(|data_operandA[31:1]) & data_operandA[0];

    and(negated1, w2, w5);
    and(negated2, w4, w6);

    assign data_exception = (overflow | overall_overflow) & ~negated1 & ~negated2 & count_done;


endmodule