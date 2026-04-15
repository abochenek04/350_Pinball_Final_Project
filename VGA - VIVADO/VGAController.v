`timescale 1 ns/ 100 ps

module VGAController(     
    input clk,          // 100 MHz System Clock
    input reset,        // Reset Signal
    output hSync,       
    output vSync,       
    output[3:0] VGA_R,  
    output[3:0] VGA_G,  
    output[3:0] VGA_B
    input [31:0] VGA_score
    );

    // --- Signals ---
    reg [9:0] ref_x, ref_y;
    
    localparam FILES_PATH = "C:/Users/amb350/Downloads/lab7-8_kit/";

    // --- Clock and Timing ---
    wire clk25, locked;
    clk_wiz_0 pll(
        .clk_out1(clk25),
        .reset(reset),
        .locked(locked), 
        .clk_in1(clk)
    );

    wire active, screenEnd;
    wire[9:0] x;
    wire[8:0] y;
    
    VGATimingGenerator #(
        .HEIGHT(480),
        .WIDTH(640)
    ) Display ( 
        .clk25(clk25),
        .reset(reset),
        .screenEnd(screenEnd),
        .active(active),
        .hSync(hSync),
        .vSync(vSync),
        .x(x),
        .y(y)
    );
    
    localparam CHAR_WIDTH = 45;
    localparam TEXT_WIDTH = 12 * CHAR_WIDTH;
    localparam SPRITE_WIDTH = 50;
    localparam TEXT_Y = 20;
    localparam SQUARE_Y = TEXT_Y;
    localparam SQUARE_SIZE = 50;
    localparam TEXT_X = (640 - 12*CHAR_WIDTH)/2;
    
    localparam SCORE_LABEL_LEN = 5;
    localparam SCORE_DIGITS = 4;
    localparam SCORE_CHAR_WIDTH = 50;
    localparam SCORE_SPRITE_WIDTH = 50;

    //change to be dependong on a register input 
    localparam SCORE_Y = 100;
    localparam SCORE_X = (640 - (SCORE_LABEL_LEN + SCORE_DIGITS) * SCORE_CHAR_WIDTH) / 2;

  
    // --- Self Movement Logic ---
    reg direction;
    
    initial {ref_x, ref_y, direction} = 0;
    always @(posedge clk25) begin
        if (screenEnd) begin
            // move square right
            if (!direction) begin
                if (ref_x < (640 - SQUARE_SIZE))
                    ref_x <= ref_x + 1;
                else
                    direction <= 1; // change direction at right edge
            end else begin
                if (ref_x > 0)
                    ref_x <= ref_x - 1;
                else
                    direction <= 0; // change direction at left edge
            end
            ref_y <= SQUARE_Y; // always align with title
        end
    end

    wire inside_square;
    assign inside_square = (x >= ref_x && x < ref_x + SQUARE_SIZE) &&
                           (y >= ref_y && y < ref_y + SQUARE_SIZE);
                        
    //Spites for title
    wire [7:0] sprite_index;
    wire [17:0] sprite_addr;
    wire sprite_bit;
    
    //RAM
    RAM #(
    .DEPTH(94*2500),
    .DATA_WIDTH(1),
    .ADDRESS_WIDTH(18),
    .MEMFILE({FILES_PATH, "sprites.mem"})
    ) SpriteData (
    .clk(clk25),
    .addr(sprite_addr),
    .dataOut(sprite_bit),
    .wEn(1'b0)
    );

    //CASINO ROYALE TITLE implemenation, get clarification on the title
    reg [7:0] title [0:11];

    //set the indexes to the right awscii chars
    initial begin
        title[0]  = 67; // C
        title[1]  = 65; // A
        title[2]  = 83; // S
        title[3]  = 73; // I
        title[4]  = 78; // N
        title[5]  = 79; // O
        title[6]  = 82; // R
        title[7]  = 79; // O
        title[8]  = 89; // Y
        title[9] = 65; // A
        title[10] = 76; // L
        title[11] = 69; // E
    end

    

    //logic for getting the title/pixes centered on the screen bounded
    wire inside_text;
    assign inside_text = (y >= TEXT_Y && y < TEXT_Y + SPRITE_WIDTH) &&
                         (x >= TEXT_X && x < TEXT_X + 12*CHAR_WIDTH);

    wire [3:0] char_index;
    assign char_index = (x - TEXT_X) / CHAR_WIDTH;

    wire valid_char;
    assign valid_char = (char_index < 12);

    //what char to print in the square location
    wire [7:0] current_char;
    assign current_char = valid_char ? title[char_index] : 8'd0;
    
    // scale horizontally
    wire [5:0] sprite_x, sprite_y;
    assign sprite_x = (x - TEXT_X) % CHAR_WIDTH * SPRITE_WIDTH / CHAR_WIDTH;
    assign sprite_y = y - TEXT_Y;

    // Sprite memory address
    assign sprite_addr = (inside_text && valid_char) ?
                     ((current_char - 33) * SPRITE_WIDTH * SPRITE_WIDTH + sprite_y * SPRITE_WIDTH + sprite_x)
                     : 18'd0;

    //what text to draw
    wire draw_text_pixel;
    assign draw_text_pixel = inside_text && valid_char && sprite_bit;
    
    //Score display
    reg [7:0] score_label [0:SCORE_LABEL_LEN-1];
    initial begin
        score_label[0] = 83; // S
        score_label[1] = 67; // C
        score_label[2] = 79; // O
        score_label[3] = 82; // R
        score_label[4] = 69; // E
    end
    

    //Change the 32 bit input from the score register ($2) to a decimal value (up to 5 decimal values long)

    //always be chekcing this (always loop perhaps)
    //once we have a input that is 5 digits (ie. 32400), 
    //use logic to decode what the digit is at each spot (or extract bit by bit from this value actually)?

    //instead of hardcoding a specific avlue, take this general number (for exmaple 3) in that position and find its ASCII value and assign that to print


    //chnage to reflect score obtained by user during gameplay
    //feed input from register. Either the full score, or break down the register bits into indiviaul and then place the individuals
    reg [7:0] score_digits [0:SCORE_DIGITS-1];
    initial begin
        VGA_score
        score_digits[0] = 48; // '0'
        score_digits[1] = 52; // '4'
        score_digits[2] = 53; // '5'
        score_digits[3] = 57; // '9'
    end
    
    wire inside_score;
    assign inside_score =  (y >= SCORE_Y && y < SCORE_Y + SCORE_SPRITE_WIDTH) &&
                      (x >= SCORE_X && x < SCORE_X + (SCORE_LABEL_LEN+SCORE_DIGITS)*SCORE_CHAR_WIDTH);
                      
    wire [3:0] score_char_index;
    assign score_char_index = (x - SCORE_X) / SCORE_CHAR_WIDTH;
    
    wire score_valid_char;
    assign score_valid_char = (score_char_index < SCORE_LABEL_LEN + SCORE_DIGITS);
    
    // Current character to draw (if index < 5, draw score letters, otherwise draw from digits)
    wire [7:0] score_char;
    assign score_char = (score_char_index < SCORE_LABEL_LEN) ? 
                        score_label[score_char_index] : 
                        score_digits[score_char_index - SCORE_LABEL_LEN];
    
    // Scale horizontally for sprite RAM
    wire [5:0] score_sprite_x, score_sprite_y;
    assign score_sprite_x = (x - SCORE_X) % SCORE_CHAR_WIDTH * SCORE_SPRITE_WIDTH / SCORE_CHAR_WIDTH;
    assign score_sprite_y = y - SCORE_Y;
    
    // Sprite memory address
    wire [17:0] score_sprite_addr;
    assign score_sprite_addr = (inside_score && score_valid_char) ?
                               ((score_char - 33) * SCORE_SPRITE_WIDTH * SCORE_SPRITE_WIDTH + score_sprite_y * SCORE_SPRITE_WIDTH + score_sprite_x)
                               : 18'd0;
    
    // Draw the score pixel
    wire score_sprite_bit;
    RAM #(
        .DEPTH(94*2500),
        .DATA_WIDTH(1),
        .ADDRESS_WIDTH(18),
        .MEMFILE({FILES_PATH, "sprites.mem"})
    ) ScoreSpriteData (
        .clk(clk25),
        .addr(score_sprite_addr),
        .dataOut(score_sprite_bit),
        .wEn(1'b0)
    );
    
    //what text to draw
    wire draw_score_pixel;
    assign draw_score_pixel = inside_score && score_valid_char && score_sprite_bit;

    // 3. Background Image (image.mem)
    wire [7:0] bg_color_addr;
    RAM #(.DEPTH(640*480), .DATA_WIDTH(8), .ADDRESS_WIDTH(19), .MEMFILE({FILES_PATH, "image.mem"})) 
    BackgroundData (.clk(clk25), .addr(x + (640*y)), .dataOut(bg_color_addr), .wEn(1'b0));

    // 4. Color Selection and Palette
    wire [7:0] final_color_idx;
    assign final_color_idx =
    draw_score_pixel ? 8'd8 :   //SCORE
    draw_text_pixel ? 8'd7 :   // TEXT
    inside_square   ? 8'd2 :   // MOVING SQUARE
                      bg_color_addr;    
                      
                      
    wire [11:0] colorData;
    RAM #(.DEPTH(256), .DATA_WIDTH(12), .ADDRESS_WIDTH(8), .MEMFILE({FILES_PATH, "colors.mem"}))
    ColorPalette (.clk(clk25), .addr(final_color_idx), .dataOut(colorData), .wEn(1'b0));

    assign {VGA_R, VGA_G, VGA_B} = active ? colorData : 12'h000;

endmodule