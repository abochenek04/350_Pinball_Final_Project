`timescale 1ns/1ps

module tb_tt_reg;

    reg  [31:0] d;
    reg         clk;
    reg         in_ena, out_ena, clr;
    wire [31:0] q;

    // DUT
    tt_reg dut(
        .d(d),
        .clk(clk),
        .in_ena(in_ena),
        .out_ena(out_ena),
        .q(q),
        .clr(clr)
    );

    // clock: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // helper task: write on next rising edge
    task do_write(input [31:0] val);
    begin
        d      = val;
        in_ena = 1;
        @(posedge clk);
        #1;
        in_ena = 0;
    end
    endtask

    initial begin
        // init
        d = 32'h0;
        in_ena = 0;
        out_ena = 0;
        clr = 0;

        // ---- async clear ----
        #2;
        clr = 1;
        #2;
        clr = 0;

        // enable output and check it's 0 after clear
        out_ena = 1;
        #1;
        if (q !== 32'h00000000) begin
            $display("FAIL: after clr, q=%h (expected 00000000)", q);
            $stop;
        end else $display("PASS: clear -> q=0");

        // ---- write 0xDEADBEEF ----
        do_write(32'hDEADBEEF);

        if (q !== 32'hDEADBEEF) begin
            $display("FAIL: write DEADBEEF, q=%h", q);
            $stop;
        end else $display("PASS: write DEADBEEF");

        // ---- hold when in_ena=0 ----
        d = 32'hAAAAAAAA;
        @(posedge clk);
        #1;
        if (q !== 32'hDEADBEEF) begin
            $display("FAIL: should hold value when in_ena=0, q=%h", q);
            $stop;
        end else $display("PASS: holds value when in_ena=0");

        // ---- tri-state behavior ----
        out_ena = 0;
        #1;
        if (q !== 32'hZZZZZZZZ) begin
            $display("FAIL: out_ena=0 should Z, q=%h", q);
            $stop;
        end else $display("PASS: out_ena=0 -> Z");

        out_ena = 1;
        #1;
        if (q !== 32'hDEADBEEF) begin
            $display("FAIL: out_ena=1 should drive stored value, q=%h", q);
            $stop;
        end else $display("PASS: out_ena=1 -> drives value");

        // ---- clear again while enabled (async) ----
        clr = 1;
        #1;
        if (q !== 32'h00000000) begin
            $display("FAIL: async clr while out_ena=1, q=%h", q);
            $stop;
        end else $display("PASS: async clr works while driving");

        clr = 0;

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
