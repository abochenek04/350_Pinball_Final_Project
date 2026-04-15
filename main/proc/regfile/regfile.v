module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	wire [31:0] w1, w2, w3;
	//5:32 decoder with RD going through decoder, ouput is 31:0 reg_file_input
	//5:32 decoder with RS1 going through decoder, ouput is 31:0 enable for RS1VAL
	//5:32 decoder with RS2 going through decoder, ouput is 31:0 enable for RS2VAL
	decoder32 Rd_decode1(w1, ctrl_writeReg, ctrl_writeEnable);
	decoder32 Rd_decode2(w2, ctrl_readRegA, 1'b1);
	decoder32 Rd_decode3(w3, ctrl_readRegB, 1'b1);

	wire [31:0] regi[0:31];
	assign regi[0] = 32'b0;

	//each reg output tristate with Rs1 and Rs2
	genvar k;
    generate 
        for (k = 0; k < 32; k = k + 1) begin
            tri_32 RS1_choice(regi[k], w2[k], data_readRegA);
			tri_32 RS2_choice(regi[k], w3[k], data_readRegB);
        end
    endgenerate


	genvar j;
    generate 
        for (j = 1; j < 32; j = j + 1) begin
            reg_32 banana(
                .d(data_writeReg), 
                .clk(clock), 
                .ena(w1[j]), 
                .q(regi[j]), 
                .clr(ctrl_reset)
            );

			
            // WE NEED 5 REGISTERs IN TOTAL one for the 2 triangles one for each mushroom and one for the ball return

            assign dataToWrite = (i == 28) ? bumper1 : data_writeReg;
            assign we = (i == 28) ? 1'bl : decoded_writeReg[i];

			assign dataToWrite = (i == 29) ? bumper2 : data_writeReg;
			assign we = (i == 29) ? 1'bl : decoded_writeReg[i];

			assign dataToWrite = (i == 30) ? bumper3 : data_writeReg;
			assign we = (i == 30) ? 1'bl : decoded_writeReg[i];

			assign dataToWrite = (i == 31) ? bumper4 : data_writeReg;
			assign we = (i == 31) ? 1'bl : decoded_writeReg[i];


            assign VGA_score = (i == 32) ? regOut : {32{1'bz}};
			
			

        end
    endgenerate



	//send each bit of data_wrtie (RDVAL) into each register
	//tt_reg(d, clk, in_ena, out_ena, q, clr)

	//dont send in the ctrl_writeEnable (WE), ctrl_writeReg (RD) yet, you 
	//have to pass these through the decoder and AND gate, which
	//will be wires you can pass to the tt_reg AFTER!!!!



endmodule
