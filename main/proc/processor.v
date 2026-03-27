/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	 
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

    //----------------------------------------------------------------------------------------
    //--------------------SECTION 1 with PC and INSN MEM (Fetch (F/D))------------------------
    //----------------------------------------------------------------------------------------

    wire [31:0] PCinsn_out;
    wire [31:0] PCinsn_in;
    wire [31:0] PC_post_ALU;

    //wires for bypassing ALUinA/B
    wire [4:0] DX_RS1, DX_RT, XM_RD, MW_RD;

    //more wires for hardware interlock (XM_RD used again)
    wire [4:0] FD_RS1, FD_RS2, DX_RD;

    wire xminsn_sw, xminsn_setx_BP, xminsn_jal_BP, xminsn_execption_BP, xminsn_RTypeBP, xminsn_ITypeBP, xminsn_LWBP, xmWE, wmBP;

    assign address_imem = PCinsn_out;
    wire stall;

    wire [31:0] fdinsn_branchSum;
    wire dxinsnALU_Branch;

    //if a branch set Pcin to be PC + 1 + N, otherwise just PC + 1 as expected
    //pc counter logic with all instructions depending on insn and priority
    assign PCinsn_in = dxinsn_jr ? bypassMuxOutA : (dxinsn_jumping ? t_etx : (dxinsnALU_Branch ? fdinsn_branchSum : PC_post_ALU));

    //left red block w/ insn memory PC
    //right now, PC auto increments by 1 (from alu forced plus 1)
        //need to implement MUX choosing between increasing pc +1 or not?
            //this is top left half of pipeline photo
    wire bugClockMult;
    reg_32 PC_counter(
        .clk(clock),
        .clr(reset), //never reseting?
        .ena(~stall | bugClockMult), //always true, execpt on a stall. Also fixes bug with mult/div to wait half cycle so count can add
        .d(PCinsn_in), //look at diagram for this input
        .q(PCinsn_out) //output of PC register, clears to 0 after reset so starts at 0, good
    );

    //this alu will always add 1 to pc counter, somwethis this updated value wont make it to the pc register (MUXED)
    wire dummy_cout;
    addOrSub PC_increment_1(
        .A(PCinsn_out),
        .B({31'b0, 1'b1}), //addding PCinsn_out with 000...01
        .select(1'b0),
        .S(PC_post_ALU), //this is the sum that is used throughout the rest of pipeline
        .Cout(dummy_cout)
    );    

    //----------------------------------------------------------------------------------------
    //--------------------SECTION 2 with REG FILE (DECODE (F/D)) -----------------------------
    //----------------------------------------------------------------------------------------

    // Latch instruction from imem
    //second red bar
    wire [31:0] fdinsn_out;
    wire [31:0] fdinsn_in;

    //with j and jal, flush 2 times too!
    //flushing needed for dxinsnALU_branch(BLT, BNE), jumping(Jal, j), jr
    wire jump_branch_flush;
    assign jump_branch_flush = dxinsnALU_Branch | dxinsn_jumping | dxinsn_jr;
    //bne and blt work change

    //fdinsn_in = flush if branch or jump is taken in X (noOps 00s) or q_imem (no branch or jump taken);
    assign fdinsn_in = jump_branch_flush ? 32'b0 : q_imem;

    reg_32 FD_INSN(
        .clk(~clock),
        .clr(reset), 
        .ena(~stall), //no advacmennt if stalling
        .d(fdinsn_in), //IR coming out of F/D Reg
        .q(fdinsn_out) //IR coming out of F/D Reg
    );

    //latch PC from incremeneted 1 (always incrementing by 1 here)
    //second red bar
    wire [31:0] fdPC_out;
    reg_32 FD_PC_carry(
        .clk(~clock), 
        .clr(reset), 
        .ena(~stall), 
        .d(PCinsn_out),
        .q(fdPC_out)
    );

    //look at opcode of IR (5 MSB)
    wire [4:0] fdinsn_op;
    assign fdinsn_op = fdinsn_out[31:27];

    //check opcode for specific sw, blt, bne instruction
    //if sw instruction, set reg B
    wire fdinsn_sw, fdinsn_bne, fdinsn_blt;
    assign fdinsn_sw = (fdinsn_op == 5'b00111);
    assign fdinsn_bne = (fdinsn_op == 5'b00010);
    assign fdinsn_blt = (fdinsn_op == 5'b00110);

    //bex instrcution
    wire fdinsn_bex;
    assign fdinsn_bex = (fdinsn_op == 5'b10110);

    //jr (JII)
    wire fdinsn_jr;
    assign fdinsn_jr = (fdinsn_op == 5'b00100);

     //if bex, then set regA = r30 (5'd30), if branch/jr set a = fdinsn_out[26:22] to read from $rd, else /$rs fdinsn_out[26:22] for A
    wire fdinsn_B;
    assign fdinsn_B = fdinsn_blt | fdinsn_bne;
    assign ctrl_readRegA = fdinsn_bex ? 5'd30 : ((fdinsn_B | fdinsn_jr) ? fdinsn_out[26:22] : fdinsn_out[21:17]);

    //regB chosen (if its a sw, use rd, if not, use?
    //if branch, use 21:17 for B ($rs), if not branch, check if sw. if Sw, use 26:22 ($rd). if not branch or sw, use 16-12 ($rt or N) 
    assign ctrl_readRegB = fdinsn_B ? fdinsn_out[21:17] : (fdinsn_sw ? fdinsn_out[26:22] : fdinsn_out[16:12]);

    //----------------------------------------------------------------------------------------
    //--------------------SECTION 3 with LOGIC/ALUs (D/X)-------------------------------------
    //----------------------------------------------------------------------------------------

    //latch IR from f/d output
    wire [31:0] dxinsn_out;
    wire [31:0] dxinsn_in;
    wire stall_lw, stall_multdiv;
    //another potential brqanch recovery with a flushout if necessary (lw hazard)
    assign dxinsn_in = (jump_branch_flush | stall_lw) ? 32'b0 : fdinsn_out;
    reg_32 DX_INSN(
        .clk(~clock),
        .clr(reset),
        .ena(~stall_multdiv),
        .d(dxinsn_in),
        .q(dxinsn_out) //take for bypass logic control *****
    );

    //latch PC from f/d output
    wire [31:0] dxPC_out;
    reg_32 DX_PC_Carry(
        .clk(~clock),
        .clr(reset), 
        .ena(~stall_multdiv), 
        .d(fdPC_out), 
        .q(dxPC_out)
    );

    // Latch data from RS (data_readRegA)
    wire [31:0] dxa_out;
    reg_32 DX_A(
        .clk(~clock), 
        .clr(reset), 
        .ena(~stall_multdiv), 
        .d(data_readRegA), 
        .q(dxa_out)
    );

    wire [31:0] dxb_out;
    reg_32 DX_B(
        .clk(~clock), 
        .clr(reset), 
        .ena(~stall_multdiv), 
        .d(data_readRegB), 
        .q(dxb_out)
    );

    //sign extend immediate (I type) to 32 bits in case we need immediate value
    wire [31:0] immediate_ext; 
    assign immediate_ext = {{15{dxinsn_out[16]}}, dxinsn_out[16:0]};

    //extedned T (JI) with 5 0s at front be 32 bits
    wire [31:0] t_etx;
    assign t_etx ={5'b00000, dxinsn_out[26:0]};

    wire [4:0] dxinsn_op;
    assign dxinsn_op = dxinsn_out[31:27];
    //check opcode (no alu Op for Itype), note that when opcode is 00101, 00111, 01000 its Itype
    //or when its any of the others for Itype

    //JI instruction decoded
    wire dxinsn_j, dxinsn_jal, dxinsn_bex, dxinsn_jr;
    assign dxinsn_j = (dxinsn_op == 5'b00001);
    assign dxinsn_jal = (dxinsn_op == 5'b00011);
    assign dxinsn_bex = (dxinsn_op == 5'b10110);
    assign dxinsn_jr = (dxinsn_op == 5'b00100);

    //I type
    wire dxinsn_addi, dxinsn_sw, dxinsn_lw, dxinsn_bne, dxinsn_blt, dxinsn_jumping;
    assign dxinsn_addi = (dxinsn_op == 5'b00101);
    assign dxinsn_sw = (dxinsn_op == 5'b00111);
    assign dxinsn_lw = (dxinsn_op == 5'b01000);
    assign dxinsn_bne = (dxinsn_op == 5'b00010);
    assign dxinsn_blt = (dxinsn_op == 5'b00110);

    //if bex instruction and the rstatus is not 0, set bextrue to true
    wire bexTrue;
    assign bexTrue = dxinsn_bex & (bypassMuxOutA != 32'b0);

    //j, jal, and bex need jumping conditions
    assign dxinsn_jumping = (dxinsn_j | dxinsn_jal | bexTrue);
    
    //all i type insn w/o branches,memory necessary with lw and sw
    wire I_type;
    assign I_type = dxinsn_addi | dxinsn_sw | dxinsn_lw;

    //if itype and not branch, alu Opcode is 000000, and we want to add in alu (rs and immediate),
    //if a branch, then we want to subtract in alu. 
    //if niether branch nor i type, just follow alu result as opcode dictates
    //if not itype, follow rtype commands and do alu operation noted by alu op
    wire [4:0] alu_op;
    assign alu_op = I_type ? 5'b00000 : ((dxinsn_blt | dxinsn_bne) ? 5'b00001 : dxinsn_out[6:2]);

    // Use ALU to compute result
    //dxinsn_out[6:2] is the alu opcode

    wire [31:0] bypassMuxOutA, bypassMuxOutB;
    wire [31:0] xmo_out;
    wire mxBypassA, wxBypassA, mxBypassB, wxBypassB;

    //see if alu bypassing needed AND check to not bypass if $r0 and checking if we actually need to write 
    //logic imlemented from slideshow in class
    assign mxBypassA = (DX_RS1 == XM_RD) & (XM_RD != 5'b0) & xmWE;
    assign wxBypassA = (DX_RS1 == MW_RD) & (MW_RD != 5'b0) & ctrl_writeEnable;

    assign mxBypassB = (DX_RT == XM_RD) & (XM_RD != 5'b0) & xmWE;
    assign wxBypassB = (DX_RT == MW_RD) & (MW_RD != 5'b0) & ctrl_writeEnable;

    //expection bypass logic, overflow, read from DX not XM
    wire xdinsn_excBPA, xdinsn_excBPB;
    assign xdinsn_excBPA = ((dxinsn_exepction != 32'd0) & (FD_RS1 == 5'd30));
    assign xdinsn_excBPB = ((dxinsn_exepction != 32'd0) & (FD_RS2 == 5'd30));

    //for bypassing ALUinA, we need to chnage input to ALU to be the output of a mux
    //the inputs to mux with either by 0: MW (1 stage bypass), 1: WX (2 stage bypass), 2: dxa_out (no bypass)

    //if we gave mxBypassing, pass in XMo_out, if not mxbypass, if wxbypass pass in output of writeback, if niether, pass in normal dxa_out
    assign bypassMuxOutA = xdinsn_excBPA ? dxinsn_exepction : (mxBypassA ? xmo_out : (wxBypassA ? data_writeReg : dxa_out));

    //for bypassing ALUinB, we need to chnage input to red mux to be output of bypassing mux
        //additonally, send output of bypassing mux to the xmb_in register
    //the inputs to mux with either by 0: MW (1 stage bypass), 1: WX (2 stage bypass), 2: dxb_out (no bypass)
    assign bypassMuxOutB = xdinsn_excBPB ? dxinsn_exepction : (mxBypassB ? xmo_out : (wxBypassB ? data_writeReg : dxb_out));

    //load B to be extended immediate value (32 bit N) (if addi, lw or sw), to take place
    //otherwise, use the B expected earlier
    wire [31:0] data_alu_B;
    assign data_alu_B = I_type ? immediate_ext : bypassMuxOutB;
        
    wire [31:0] alu_out;
    wire Branch_NE, Branch_LT, of;
    alu ALU_ex(
        .data_operandA(bypassMuxOutA), 
        .data_operandB(data_alu_B), 
        .ctrl_ALUopcode(alu_op), 
        .ctrl_shiftamt(dxinsn_out[11:7]), 
        .data_result(alu_out),
        .isNotEqual(Branch_NE),
        .isLessThan(Branch_LT),
        .overflow(of)
    );         

    //branched alu to posibly chnage counter count (add always) PC + N + 1 type ordeal
    wire dummy_cout2;
    addOrSub Branch_PC_dec(
        .A(dxPC_out),
        .B(immediate_ext),
        .select(1'b0),
        .S(fdinsn_branchSum),
        .Cout(dummy_cout2)
    );

    //input to and gate in top 
    //(select bit for mux to either pass varried pc (Pc + 1 + N) (1) or regular pc (PC + 1) (0))
    //if blt & alu LT, or bne & alu NE, assign true to trigger flush noOps in processor
    assign dxinsnALU_Branch = (dxinsn_blt & Branch_LT) | (dxinsn_bne & Branch_NE);

    //----------------------------------------------------------------------------------------
    //--------------------SECTION 3.5 with Mult/Div (P/W)-------------------------------------
    //----------------------------------------------------------------------------------------

    //take dxinsn_outA and dxinsn_outB, send those into mult/div unit
        //have an xcontrol unit that acts as the signal input to the mult/.div unit
            //likely to notify when the process is done.
        //somewhere in here, logic needed to send in noops until the operation flags as COMPLETE
    //take output/product/divident of mult/div unti when complete and pass into P port of P/W reg as P
    //take dxIR_out and send into new P/W register as IR
    //send xcontrol to the P/W register likely to notify it is done.
    //send output of P/W reg (P) into mux to be (possibly) written back to reg file

    //module multdiv(data_operandA, data_operandB, ctrl_MULT, ctrl_DIV, clock, data_result, data_exception, data_resultRDY);

    //need to implement some stalling on reading or writing mult register
    //also need to write.

    //check alu ops for possible mult or div insn
    wire pwinsn_mult, pwinsn_div, pwinsn_multdiv;
    assign pwinsn_mult = (dxinsn_op == 5'b00000) & (dxinsn_out[6:2] == 5'b00110);
    assign pwinsn_div = (dxinsn_op == 5'b00000) & (dxinsn_out[6:2] == 5'b00111);
    assign pwinsn_multdiv = pwinsn_mult | pwinsn_div;

    //stalling logic
        //when insn enter execute, busy is true
        //busy stays true until done with mult or div
        //when dataready is true, busy turns off
        //pseudo code is stall = when its busy and that data is not ready
        //then this ~stall command becomes the write enable for the pipeline registers pc, fd, dx, xm
            //this will freeze the insn in x while mult works

    //remmeber if multdiv op started, fixes bug where the 4th multdiv insn would not be read into prcoessor
    wire startmultdiv, multdivDone;
    dffe_ref multdivtracker(
        .q(startmultdiv),
        .d(pwinsn_multdiv && ~multdivDone),
        .clk(~clock),
        .en(1'b1),
        .clr(reset)
    );

    wire ctrl_multPulse, ctrl_divPulse;
    assign ctrl_multPulse = pwinsn_mult && ~startmultdiv;
    assign ctrl_divPulse = pwinsn_div && ~startmultdiv;

    //use the bypassmux values (which if no bypassing are just the reguyalr register outputs)
    //remmeber data_alu a is the bypass muxoutB but also checked for Itype (fixes bypassing for mult div op)
    wire [31:0] multDivRes;
    wire multDivExp;
    multdiv multOrDiv(
        .data_operandA(bypassMuxOutA),
        .data_operandB(data_alu_B),
        .ctrl_MULT(ctrl_multPulse),
        .ctrl_DIV(ctrl_divPulse),
        .clock(clock),
        .data_result(multDivRes), //result after running the mult or div.
        .data_exception(multDivExp), //execption thrown for multdiv (dont worry about this for now)
        .data_resultRDY(multdivDone) //signal that mult/div is done
    );

    //add in a dff to hold mult/div operation as done until PC sees and enables to update count
    dffe_ref Bug_multDiv_Fix(
        .clk(~clock), 
        .clr(reset), 
        .en(1'b1), 
        .d(multdivDone), 
        .q(bugClockMult)
    );

    //name wire for easier remmebering
    wire isMultOrDiv;
    assign isMultOrDiv = pwinsn_multdiv;
    assign stall_multdiv = isMultOrDiv && ~multdivDone;

    //stalling for lw, either in if 1 cycle ahead (DX) or 2 cycles ahead (XM)
    //keep in mind freeze only the PC and the F/D register, while everythign else keeps going
    //sw needs data in Memory, not X, so don't stall if sw
    assign stall_lw = (dxinsn_lw & ((FD_RS1 == DX_RD) | (FD_RS2 == DX_RD & ~fdinsn_sw)) & (DX_RD != 5'b0)) | ((xminsn_out[31:27] == 5'b01000) & ((FD_RS1 == XM_RD) | (FD_RS2 == XM_RD & ~fdinsn_sw)) & (XM_RD != 5'b0));
    assign stall = stall_multdiv | stall_lw;

    //send pwinsn_ProductOut to the mux to be written back to RegFile if needed

    //----------------------------------------------------------------------------------------
    //--------------------SECTION 4 with DataMem (X/M)-------------------------------------
    //----------------------------------------------------------------------------------------

    //honeslty, im not sure why i have dx here. when i tried to change it to xm, it glitched and I didn't chnage it so im keeping it like this for now
    //may be an area to look into post cpu completion. Not causing issues for now.
    wire xminsn_bex, xminsn_setx, xminsn_jal, xminsn_add, xminsn_sub;
    assign xminsn_bex = (dxinsn_op == 5'b10110);
    assign xminsn_setx = (dxinsn_op == 5'b10101);
    assign xminsn_jal = (dxinsn_op == 5'b00011);
    assign xminsn_add = (dxinsn_op == 5'b00000) & (dxinsn_out[6:2] == 5'b00000);
    assign xminsn_sub = (dxinsn_op == 5'b00000) & (dxinsn_out[6:2] == 5'b00001);

    //set status registers to specific values (1-5) if of occurs
    wire [31:0] dxinsn_exepction;
    assign dxinsn_exepction = (xminsn_add && of) ? 32'd1 : ((dxinsn_addi && of) ? 32'd2 : ((xminsn_sub && of) ? 32'd3 : ((pwinsn_mult && multDivExp) ? 32'd4 : ((pwinsn_div && multDivExp) ? 32'd5 : 32'd0))));

    //W-M bypass logic, data coming out of WB to feed back into Memory
    assign wmBP = xminsn_sw & (xminsn_out[26:22] == MW_RD) & (MW_RD != 5'b0) & ctrl_writeEnable;

    wire [31:0] xminsn_execption;
    reg_32 XM_EXEPTION(
        .clk(~clock),
        .clr(reset),
        .ena(~stall),
        .d(dxinsn_exepction),
        .q(xminsn_execption)
    );

    wire [31:0] xminsn_out;
    reg_32 XM_INSN(
        .clk(~clock),
        .clr(reset),
        .ena(~stall_multdiv),
        .d(dxinsn_out), //pass through dxIR to x/m
        .q(xminsn_out) //take through for bypass Control ******
    );

    //if jal, send PC from dx output as xm_o input, otheriwse if setx, 
    //then set T as mx_o input, and otherwise send the alu output from execute stage

    //send in multdiv result if there was a pwinsn
    //exepction bypass handled, if exception, add of to xminsn_in, so that it can be processed and used
    wire [31:0] xminsn_in;
    assign xminsn_in = xminsn_jal ? dxPC_out : (xminsn_setx ? t_etx : (pwinsn_multdiv ? multDivRes : ((dxinsn_exepction != 32'd0) ? dxinsn_exepction : alu_out)));
    
    // Latch ALU result AND account for possible jal/setx instruction
    reg_32 XM_O(
        .clk(~clock), 
        .clr(reset), 
        .ena(~stall_multdiv), 
        .d(xminsn_in), 
        .q(xmo_out)
    );

    //latch store dara
    wire [31:0] xmb_out;
    reg_32 XM_B(
        .clk(~clock),
        .clr(reset),
        .ena(~stall_multdiv),
        .d(bypassMuxOutB), //chnage to account for bypassing output of mux aluInB //
        .q(xmb_out)
    );

    //use the opcode to figure out insn
    wire [4:0] xminsn_op;
    assign xminsn_op = xminsn_out[31:27];
    
    assign xminsn_sw = (xminsn_op == 5'b00111);
    assign xminsn_setx_BP = (xminsn_op == 5'b10101);
    assign xminsn_jal_BP = (xminsn_op == 5'b00011);
    assign xminsn_execption_BP = (xminsn_execption != 32'd0);
    assign xminsn_RTypeBP = (xminsn_op == 5'b00000);
    assign xminsn_ITypeBP = (xminsn_op == 5'b00101);
    assign xminsn_LWBP = (xminsn_op == 5'b01000);

    //we want to write (to reg file) if instruction other than branch, j, and sw. A bypass signal too
    assign xmWE = xminsn_execption_BP | xminsn_RTypeBP | xminsn_ITypeBP | xminsn_LWBP | xminsn_jal_BP | xminsn_setx_BP;


    //take address of O output from X/M and set to the adreess of data memeory
    assign address_dmem = xmo_out;

    //assignt the value of d in data mem to be B output from x/m OR is wm bypass (lw to sw) is true, take data from wb stage
    assign data = wmBP ? data_writeReg : xmb_out;

    //if sw, assign write enable to be true (to write to dmem)
    assign wren = xminsn_sw;

    //----------------------------------------------------------------------------------------
    //--------------------SECTION 5 with not writeback (M/W)----------------------------------
    //----------------------------------------------------------------------------------------

    wire [31:0] mwinsn_execption;
    reg_32 MW_EXEPTION(
        .clk(~clock),
        .clr(reset),
        .ena(~stall_multdiv),
        .d(xminsn_execption),
        .q(mwinsn_execption)
    );

    //send this value of mwinsn_out to the regfile 
    wire [31:0] mwinsn_out;
    reg_32 MW_INSN(
        .clk(~clock),
        .clr(reset),
        .ena(~stall_multdiv),
        .d(xminsn_out), //pass through xmIR to m/w
        .q(mwinsn_out) //take in through bypass cotnrol *****
    );

    wire [31:0] mwo_out;
    reg_32 MW_O(
        .clk(~clock), 
        .clr(reset), 
        .ena(~stall_multdiv), 
        .d(xmo_out), 
        .q(mwo_out)
    );

    wire [31:0] mwd_out;
    reg_32 MW_D(
        .clk(~clock), 
        .clr(reset), 
        .ena(~stall_multdiv), 
        .d(q_dmem), 
        .q(mwd_out)
    );

    //writeback logic

    wire [4:0] wb_op;
    assign wb_op = mwinsn_out[31:27];

    wire wb_Rtype, wb_Itype, wb_SW, wb_LW, wb_jal, wb_setx, wb_mult, wb_div, wb_multdiv;
    assign wb_Rtype = (wb_op == 5'b00000);

    //chnage to account for other I type instruction (branch)
    assign wb_Itype = (wb_op == 5'b00101);
    assign wb_SW = (wb_op == 5'b00111);
    assign wb_LW = (wb_op == 5'b01000);

    //JI instructions
    assign wb_jal = (wb_op == 5'b00011);
    assign wb_setx = (wb_op == 5'b10101);

    assign wb_mult = (wb_op == 5'b00000) & (mwinsn_out[6:2] == 5'b00110);
    assign wb_div = (wb_op == 5'b00000) & (mwinsn_out[6:2] == 5'b00111);
    assign wb_multdiv = (wb_mult | wb_div);

    //expections for rstatus
    wire wb_expection;
    assign wb_expection = (mwinsn_execption != 32'd0);

    //write $rd to reg in reg file, jal writes to r31, setx to r30
    assign ctrl_writeReg = wb_expection ? 5'd30 : (wb_jal ? 5'd31 : (wb_setx ? 5'd30 : mwinsn_out[26:22]));

    //write back to rd register if rtype or itype, lw, jal, setx, multdiv,
    assign ctrl_writeEnable = wb_expection ? 1'b1 : ((wb_Rtype | wb_Itype | wb_LW | wb_jal | wb_setx | wb_multdiv));

    //for now, just send alu result back, alter when editing cpu for next version
    //use mux (with some control input, not wb_LW) to determine whether to write back O from M/W or D from M/W
    assign data_writeReg = wb_expection ? mwinsn_execption : (wb_LW ? mwd_out : mwo_out);

    //bypassing control unit for ALUinA/B:
    //use the following in this control unit: dxinsn_out, xminsn_out, mwinsn_out
    //make sure that the bypass instrcution matches with the readregA and readregB registers exactly
    assign DX_RS1 = dxinsn_bex ? 5'd30 : ((dxinsn_blt | dxinsn_bne | dxinsn_jr) ? dxinsn_out[26:22] : dxinsn_out[21:17]); //$rs for R and I type, different for bne/blt
    assign DX_RT = (dxinsn_blt | dxinsn_bne) ? dxinsn_out[21:17] : (dxinsn_sw ? dxinsn_out[26:22] : dxinsn_out[16:12]); //$rt for R type, different for bne/blt

    //speciclize thewse for setx and jal for varrying target adress T isntead of $rd (bypassing)
    assign XM_RD = xminsn_execption_BP ? 5'd30 : (xminsn_jal_BP ? 5'd31 : (xminsn_setx_BP ? 5'd30 : xminsn_out[26:22]));
    assign MW_RD = mwinsn_execption ? 5'd30 : (wb_jal ? 5'd31 : (wb_setx ? 5'd30 : mwinsn_out[26:22]));

    //hardware interlock logic from lecture
    assign FD_RS1 = fdinsn_bex ? 5'd30 : ((fdinsn_blt | fdinsn_bne | fdinsn_jr) ? fdinsn_out[26:22] : fdinsn_out[21:17]); //$rs for R and I type, different for bne/blt
    assign FD_RS2 = fdinsn_bex ? 5'd30 : ((fdinsn_blt | fdinsn_bne) ? fdinsn_out[21:17] : (fdinsn_sw ? fdinsn_out[26:22] : fdinsn_out[16:12])); //$rt for R type, different for bne/blt
    assign DX_RD = dxinsn_out[26:22];

endmodule