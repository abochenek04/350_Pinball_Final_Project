module score_to_ascii(
    input  [31:0] score,
    output [7:0] ascii_tenThou,
    output [7:0] ascii_thousands,
    output [7:0] ascii_hundreds,
    output [7:0] ascii_tens,
    output [7:0] ascii_ones
);

    wire [31:0] clipped_score;
    assign clipped_score = (score > 99999) ? 32'd99999 : score;

    wire [3:0] tenThou, thousands, hundreds, tens, ones;

    // Example: if score = 13200
    // tenThou = 1, thousands = 3, hundreds = 2, tens = 0, ones = 0
    assign tenThou = (clipped_score / 10000) % 10;
    assign thousands = (clipped_score / 1000) % 10;
    assign hundreds = (clipped_score / 100) % 10;
    assign tens = (clipped_score / 10) % 10;
    assign ones = clipped_score % 10;

    assign ascii_tenThou = 8'd48 + tenThou;
    assign ascii_thousands = 8'd48 + thousands;
    assign ascii_hundreds = 8'd48 + hundreds;
    assign ascii_tens = 8'd48 + tens;
    assign ascii_ones = 8'd48 + ones;

endmodule