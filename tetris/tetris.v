`default_nettype none

module tetris(
    input             clk,
    input             reset_game,

    input             move_right,
    input             move_left,
    input             rotate_right,
    input             rotate_left,

    output            game_over,

    // VGA out
    output wire       hsync,    // horizontal sync output
    output wire       vsync,    // vertical sync output
    output wire [2:0] VGA_R,    // 3-bit VGA red output
    output wire [2:0] VGA_G,    // 3-bit VGA green output
    output wire [2:1] VGA_B,     // 2-bit VGA blue output
    output      [7:0] debug
);
    localparam NumPiecesX = 10;
    localparam NumPiecesY = 20;
    localparam PieceSize = 16;
    localparam BoardBeginX = 240;
    localparam BoardEndX = BoardBeginX+NumPiecesX*PieceSize;
    localparam BoardBeginY = 40;
    localparam BoardEndY = BoardBeginY+NumPiecesY*PieceSize;

        // generate a 25 MHz pixel strobe
    reg [15:0]  cnt;
    reg         pix_stb;
    always @(posedge clk)
        {pix_stb, cnt} <= cnt+16'h4000;  // divide by 4: (2^16)/4 = 0x4000

    wire [9:0]  display_x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0]  display_y;  // current pixel y position:  9-bit value: 0-511
    wire        out_active;
    vga640x480 display(
        .i_clk    (clk),
        .i_pix_stb(pix_stb),
        .i_rst    (0),
        .o_hs     (hsync),
        .o_vs     (vsync),
        .o_x      (display_x),
        .o_y      (display_y),
        .o_active (out_active)
    );


    // TODO speedup game every line
    reg [23:0]  count = 1;
    reg         start_game = 0;

    wire        game_clock = count == 0;
    always @(posedge clk) begin
        if (start_game)
            count <= count+1;
        if (move_right || move_left || rotate_left || rotate_right)
            start_game <= 1;
    end



    wire [3:0]  query_x = ((display_x-BoardBeginX) >> 4);
    wire [5:0]  query_y = NumPiecesY-1-((display_y-BoardBeginY) >> 4);
    wire [7:0]  query_pos = query_y*NumPiecesX+query_x;
    wire [2:0]  query_res;
    wire [19:0] which_lines_cleared;
    tetris_engine engine(
        .clk                (clk),
        .reset_game         (reset_game),
        .next_fall          (game_clock),
        .move_piece_left    (move_left),
        .move_piece_right   (move_right),
        .rotate_right       (rotate_right),
        .rotate_left        (rotate_left),
        .display_query_pos  (query_pos),
        .display_query_res  (query_res),
        .game_over          (game_over),
        .which_lines_cleared(which_lines_cleared),
        .debug              (debug)
    );



    localparam BorderSize = 10;

    wire        is_board = BoardBeginX <= display_x && display_x <= BoardEndX &&
        BoardBeginY <= display_y && display_y <= BoardEndY;

    wire        is_board_border = !is_board &&
        BoardBeginX-BorderSize <= display_x && display_x <= BoardEndX+BorderSize &&
        BoardBeginY-BorderSize <= display_y && display_y <= BoardEndY+BorderSize;



    localparam red = 8'b11000000;
    localparam green = 8'b00011000;
    localparam c1 = 8'b00011011;
    localparam c2 = 8'b1011000;
    localparam c3 = 8'b10101000;
    localparam c4 = 8'b1010001;
    localparam c5 = 8'b1111000;
    localparam c6 = 8'b0011000;
    localparam white = 8'b11111111;

    wire [7:0]  color_for_piece[7:0];
    assign color_for_piece[0] = 0;
    assign color_for_piece[1] = green;
    assign color_for_piece[2] = c1;
    assign color_for_piece[3] = c2;
    assign color_for_piece[4] = c3;
    assign color_for_piece[5] = c4;
    assign color_for_piece[6] = c5;
    assign color_for_piece[7] = c6;

    wire [7:0]  border_color = game_over ? red:green;

    assign {VGA_R, VGA_G, VGA_B} = !out_active ? 0:
        (is_board_border ? border_color:
            (!is_board ? 0:
                (which_lines_cleared[query_y] ? white:color_for_piece[query_res])));

    /*
    assign VGA_R[2:0] = !out_active ? 0:(is_board_border ? border_color_r:
        (is_board ? R_value_for_piece[query_res]:0));
    assign VGA_G[2:0] = !out_active ? 0:(is_board_border ? border_color_g:
        (is_board ? G_value_for_piece[query_res]:0));
    assign VGA_B[2:1] = !out_active ? 0:(is_board_border ? border_color_b:
        (is_board ? B_value_for_piece[query_res]:0));
*/
endmodule