module mux_32_tb;
    reg [31:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15, in16, in17, in18, in19, in20, in21, in22, in23, in24, in25, in26, in27, in28, in29, in30, in31;
    wire [31:0] out;
    wire [4:0] select;

    // Instantiate the module to test
    mux_32 muxer(
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4),
        .in5(in5),
        .in6(in6),
        .in7(in7),
        .in8(in8),
        .in9(in9),
        .in10(in10),
        .in11(in11),
        .in12(in12),
        .in13(in13),
        .in14(in14),
        .in15(in15),
        .in16(in16),
        .in17(in17),
        .in18(in18),
        .in19(in19),
        .in20(in20),
        .in21(in21),
        .in22(in22),
        .in23(in23),
        .in24(in24),
        .in25(in25),
        .in26(in26),
        .in27(in27),
        .in28(in28),
        .in29(in29),
        .in30(in30),
        .in31(in31),
        .out(out),
        .select(select)
    );

    initial begin
        in0 = 32'd0;
        in1 = 32'd1;
        in2 = 32'd2;
        in3 = 32'd3;
        in4 = 32'd4;
        in5 = 32'd5;
        in6 = 32'd6;
        in7 = 32'd7;
        in8 = 32'd8;
        in9 = 32'd9;
        in10 = 32'd0;
        in11 = 32'd11;
        in12 = 32'd12;
        in13 = 32'd13;
        in14 = 32'd14;
        in15 = 32'd15;
        in16 = 32'd16;
        in17 = 32'd17;
        in18 = 32'd18;
        in19 = 32'd19;
        in20 = 32'd20;
        in21 = 32'd21;
        in22 = 32'd22;
        in23 = 32'd23;
        in24 = 32'd24;
        in25 = 32'd25;
        in26 = 32'd26;
        in27 = 32'd27;
        in28 = 32'd28;
        in29 = 32'd29;
        in30 = 32'd30;
        in31 = 32'd31;
    end

    integer i;
    assign select = i[4:0];

    initial begin
        for (i=0; i < 32; i=i+1) begin
            #20
            $display("out:%d, select:%d",
                     out, select);
        end
        $finish;
    end

endmodule