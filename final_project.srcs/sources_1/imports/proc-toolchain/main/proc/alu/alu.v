module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    wire [31:0] add_result, sub_result, and_result, or_result, sll_result, sra_result;
    wire add_count, sub_count;

    //run all operations for a given set of inputs to the alu
    addOrSub op0(.A(data_operandA), .B(data_operandB), .select(1'b0), .S(add_result), .Cout(add_count));
    addOrSub op1(.A(data_operandA), .B(data_operandB), .select(1'b1), .S(sub_result), .Cout(sub_count));

    and_alu op2(.A(data_operandA), .B(data_operandB), .Y(and_result));
    or_alu op3(.A(data_operandA), .B(data_operandB), .Y(or_result));

    sll32 op4(.A(data_operandA), .ctrl_shiftamt(ctrl_shiftamt), .out(sll_result));
    sra32 op5(.A(data_operandA), .ctrl_shiftamt(ctrl_shiftamt), .out(sra_result));

    //chooses result based on opcode
    mux_32 opcodeMux(
        .in0(add_result),
        .in1(sub_result),
        .in2(and_result),
        .in3(or_result),
        .in4(sll_result),
        .in5(sra_result),
        .in6(32'b0),
        .in7(32'b0),
        .in8(32'b0),
        .in9(32'b0),
        .in10(32'b0),
        .in11(32'b0),
        .in12(32'b0),
        .in13(32'b0),
        .in14(32'b0),
        .in15(32'b0),
        .in16(32'b0),
        .in17(32'b0),
        .in18(32'b0),
        .in19(32'b0),
        .in20(32'b0),
        .in21(32'b0),
        .in22(32'b0),
        .in23(32'b0),
        .in24(32'b0),
        .in25(32'b0),
        .in26(32'b0),
        .in27(32'b0),
        .in28(32'b0),
        .in29(32'b0),
        .in30(32'b0),
        .in31(32'b0),
        .out(data_result), 
        .select(ctrl_ALUopcode)
    );

    //IsNotEqual: 33 length wire, start with 0
    wire [32:0] notEqual;
    assign notEqual[0] = 1'b0;

    //make the next noteqaul to the or of the current k notequal and the kth bit from sub result
    //are there any 1s till this point?
    //if any sub_result was 1, notEquall will be 1
    genvar k;
    generate
        for(k = 0; k < 32; k = k + 1) begin
            or NEQ(notEqual[k+1], notEqual[k], sub_result[k]);
        end
    endgenerate
    assign isNotEqual = notEqual[32];


    //IsLessThan: data_operandA < data_operandB
    wire subtraction_OF, sign_change, sum_change;

    //sign of a xor sign of b
    xor firstXor(sum_change, sub_result[31], data_operandA[31]);

    //did the bit change
    xor secondXor(sign_change, data_operandA[31], data_operandB[31]);

    //if a and b had different signs AND subtract results is not the same as A
    //flip sign if necessary/wrong
    and firstAnd(subtraction_OF, sum_change, sign_change);
    xor lastXor(isLessThan, sub_result[31], subtraction_OF);

    //overflow: if signed overflow occurs in Add or Sub
    //only happens if a and b have same sign, result has oppostie sign

    //add overflow: not(a[31] xor b[31]) and (add_result[31] xor A[31])
    wire w1, w2, w3, overflow_from_addition;

    xor xor_one(w1, data_operandA[31], data_operandB[31]);
    not not_one(w2, w1);
    xor xor_two(w3, add_result[31], data_operandA[31]);
    and first_and(overflow_from_addition, w3, w2);

    //sub overflow: (a[31] xor b[31]) and (sub_result[31] xor A[31])
    wire w5, overflow_from_subtraction;
    xor xor_four (w5, sub_result[31], data_operandA[31]);
    and second_and(overflow_from_subtraction, w1, w5);

    //use mux to chose sub or add, set overflow to truye for add,sub
    wire w6;
    mux_2 #(.WIDTH(1)) overflow_check (
        .in0(overflow_from_addition),
        .in1(overflow_from_subtraction),
        .out(w6),
        .select(ctrl_ALUopcode[0])
    );

    assign overflow = w6;

endmodule