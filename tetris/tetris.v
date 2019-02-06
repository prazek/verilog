`default_nettype none

module tetris(
    input             clk,
    input             reset,

    input             move_right,
    input             move_left,

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

    wire       vclk;
        // generate a 25 MHz pixel strobe
    DCM_SP#(
    .CLKFX_DIVIDE(4),
    .CLKFX_MULTIPLY(2),
    .CLKIN_PERIOD(50),
    .CLK_FEEDBACK("NONE"),
    .STARTUP_WAIT("TRUE")
    ) dcm_vclk(
        .CLKFX(vclk),
        .CLKIN(clk)
    );

    wire [9:0] display_x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0] display_y;  // current pixel y position:  9-bit value: 0-511
    wire       out_active;
    vga640x400 display(
        .i_clk    (clk),
        .i_pix_stb(vclk),
        .i_rst    (reset),
        .o_hs     (hsync),
        .o_vs     (vsync),
        .o_x      (display_x),
        .o_y      (display_y),
        .o_active (out_active)
    );


    reg [23:0] count = 1;
    reg        game_started = 0;
    reg [24:0] start_game_count = 0;
    reg [32:0] reset_cnt = 1;
    wire       game_clock = count == 0;
    wire       start_game = start_game_count == 0;
    wire       reset_game = reset_cnt == 0 || (start_game_count == 0 && game_started == 0);

    always @(posedge clk) begin
        count <= count+1;
        reset_cnt <= reset_cnt+1;
        start_game_count <= start_game_count+1;
    end



    wire [3:0] query_x = NumPiecesX-((display_x-BoardBeginX) >> 4);
    wire [5:0] query_y = NumPiecesY-1-((display_y-BoardBeginY) >> 4);
    wire [7:0] query_pos = query_y*NumPiecesX+query_x;
    wire [2:0] query_res;

    tetris_engine engine(
        .clk              (clk),
        .reset            (reset_game | reset),
        .next_fall        (game_clock),
        .move_piece_left  (move_left),
        .move_piece_right (move_right),
        .display_query_pos(query_pos),
        .display_query_res(query_res),
        .debug            (debug)
    );




    localparam BorderSize = 10;

    wire       is_board = BoardBeginX <= display_x && display_x <= BoardEndX &&
        BoardBeginY <= display_y && display_y <= BoardEndY;

    wire       is_board_border = !is_board &&
        BoardBeginX-BorderSize <= display_x && display_x <= BoardEndX+BorderSize &&
        BoardBeginY-BorderSize <= display_y && display_y <= BoardEndY+BorderSize;


    localparam pink_r = 128;
    localparam pink_g = 66;
    localparam pink_b = 244;

    wire [2:0] R_value_for_piece[7:0];
    assign R_value_for_piece[0] = 0;
    assign R_value_for_piece[1] = 0;
    assign R_value_for_piece[2] = 2;
    assign R_value_for_piece[3] = 1;
    assign R_value_for_piece[4] = 1;
    assign R_value_for_piece[5] = 1;
    assign R_value_for_piece[6] = 1;
    assign R_value_for_piece[7] = 1;


    wire [2:0] G_value_for_piece[7:0];
    assign G_value_for_piece[0] = 0;
    assign G_value_for_piece[1] = 1;
    assign G_value_for_piece[2] = 2;
    assign G_value_for_piece[3] = 2;
    assign G_value_for_piece[4] = 2;
    assign G_value_for_piece[5] = 2;
    assign G_value_for_piece[6] = 2;
    assign G_value_for_piece[7] = 2;

    wire [2:1] B_value_for_piece[7:0];
    assign B_value_for_piece[0] = 0;
    assign B_value_for_piece[1] = 3;
    assign B_value_for_piece[2] = 2;
    assign B_value_for_piece[3] = 0;
    assign B_value_for_piece[4] = 0;
    assign B_value_for_piece[5] = 1;
    assign B_value_for_piece[6] = 0;
    assign B_value_for_piece[7] = 1;


    assign VGA_R[2:0] = !out_active ? 0:(is_board_border ? pink_r:
        (is_board ? R_value_for_piece[query_res]:0));
    assign VGA_G[2:0] = !out_active ? 0:(is_board_border ? pink_g:
        (is_board ? G_value_for_piece[query_res]:0));
    assign VGA_B[2:1] = !out_active ? 0:(is_board_border ? pink_b:
        (is_board ? B_value_for_piece[query_res]:0));

endmodule