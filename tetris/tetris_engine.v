`default_nettype none

module tetris_engine(
    input             clk,
    input             reset_game,
    input             next_fall,
    // User inputs
    input             move_piece_right,
    input             move_piece_left,
    input             rotate_right,
    input             rotate_left,

    input  [11:0]     display_query_pos,

    output reg [2:0]  next_piece = 1,
    output reg [15:0] next_piece_matrix = 3,

    output [2:0]      display_query_res,
    output reg        game_over = 0,
    output reg [19:0] which_lines_cleared = 0,
    output reg [20:0] game_lines_cleared = 0,
    output reg [7:0]  debug = 0,
    output reg        fallen = 0
);
    localparam GameWidth = 10;
    localparam GameHeight = 20;
    localparam NumPieces = 7;
        // Numerate pieces from 1 to 8
    wire        [3:0] PiecesPos_X[4+4*NumPieces-1:4];
    wire        [4:0] PiecesPos_Y[4+4*NumPieces-1:4];
        // Z piece
    assign PiecesPos_X[4] = 3;
    assign PiecesPos_X[5] = 4;
    assign PiecesPos_X[6] = 4;
    assign PiecesPos_X[7] = 5;

    assign PiecesPos_Y[4] = 19;
    assign PiecesPos_Y[5] = 19;
    assign PiecesPos_Y[6] = 18;
    assign PiecesPos_Y[7] = 18;

        // T piece
    assign PiecesPos_X[8] = 5;
    assign PiecesPos_X[9] = 4;
    assign PiecesPos_X[10] = 5;
    assign PiecesPos_X[11] = 6;

    assign PiecesPos_Y[8] = 19;
    assign PiecesPos_Y[9] = 18;
    assign PiecesPos_Y[10] = 18;
    assign PiecesPos_Y[11] = 18;

        // S piece
    assign PiecesPos_X[12] = 5;
    assign PiecesPos_X[13] = 6;
    assign PiecesPos_X[14] = 5;
    assign PiecesPos_X[15] = 4;

    assign PiecesPos_Y[12] = 19;
    assign PiecesPos_Y[13] = 19;
    assign PiecesPos_Y[14] = 18;
    assign PiecesPos_Y[15] = 18;

        // O piece
    assign PiecesPos_X[16] = 4;
    assign PiecesPos_X[17] = 5;
    assign PiecesPos_X[18] = 4;
    assign PiecesPos_X[19] = 5;

    assign PiecesPos_Y[16] = 19;
    assign PiecesPos_Y[17] = 19;
    assign PiecesPos_Y[18] = 18;
    assign PiecesPos_Y[19] = 18;

        // L piece
    assign PiecesPos_X[20] = 6;
    assign PiecesPos_X[21] = 4;
    assign PiecesPos_X[22] = 5;
    assign PiecesPos_X[23] = 6;

    assign PiecesPos_Y[20] = 19;
    assign PiecesPos_Y[21] = 18;
    assign PiecesPos_Y[22] = 18;
    assign PiecesPos_Y[23] = 18;

        // J piece
    assign PiecesPos_X[24] = 4;
    assign PiecesPos_X[25] = 4;
    assign PiecesPos_X[26] = 5;
    assign PiecesPos_X[27] = 6;

    assign PiecesPos_Y[24] = 19;
    assign PiecesPos_Y[25] = 18;
    assign PiecesPos_Y[26] = 18;
    assign PiecesPos_Y[27] = 18;

        // I piece
    assign PiecesPos_X[28] = 4;
    assign PiecesPos_X[29] = 5;
    assign PiecesPos_X[30] = 6;
    assign PiecesPos_X[31] = 7;

    assign PiecesPos_Y[28] = 18;
    assign PiecesPos_Y[29] = 18;
    assign PiecesPos_Y[30] = 18;
    assign PiecesPos_Y[31] = 18;


    reg               write_ram;
    reg [2:0]         write_value;
    reg [11:0]        ram_query;
    wire        [3:0] ram_state;


    wire        [3:0] display_ram;


    RAMB16_S4_S4 gameState(
        .DOA  (display_ram), // Port A 4-bit Data Output
        .DOB  (ram_state), // Port B 4-bit Data Output
        .ADDRA(display_query_pos), // Port A 12-bit Address Input
        .ADDRB(ram_query), // Port B 12-bit Address Input
        .CLKA (clk), // Port A Clock
        .CLKB (clk), // Port B Clock
        .DIA  (0), // Port A 4-bit Data Input
        .DIB  (write_value), // Port B 4-bit Data Input
        .ENA  (1), // Port A RAM Enable Input
        .ENB  (1), // Port B RAM Enable Input
        .SSRA (0), // Port A Synchronous Set/Reset Input
        .SSRB (0), // Port B Synchronous Set/Reset Input
        .WEA  (0), // Port A Write Enable Input
        .WEB  (write_ram) // Port B Write Enable Input
    );


    reg signed [4:0]  current_x [3:0];
    reg signed [5:0]  current_y [3:0];
    wire signed [2:0] related_pos_x[3:0];
    wire signed [2:0] related_pos_y[3:0];
    reg               which_move = 0; // left, right
    wire signed [5:0] move_x[3:0];
    wire signed [6:0] move_y[3:0];


    wire signed [5:0] rot_right_x[3:0];
    wire signed [6:0] rot_right_y[3:0];
    wire signed [5:0] rot_left_x[3:0];
    wire signed [6:0] rot_left_y[3:0];
    reg               which_rot = 0; // left, right
    wire signed [5:0] rot_x[3:0];
    wire signed [6:0] rot_y[3:0];


    reg [2:0]         current_piece = 1;
    wire signed [8:0] piece_pos[3:0];
    wire signed [8:0] pos_down[3:0];
    wire signed [8:0] pos_move[3:0];
    wire signed [8:0] pos_rot[3:0];

    assign display_query_res = (display_query_pos == piece_pos[0]
        || display_query_pos == piece_pos[1]
        || display_query_pos == piece_pos[2]
        || display_query_pos == piece_pos[3]) ? current_piece:display_ram[2:0];

    localparam POINT_OF_ROTATION = 2;
    genvar i;
    generate
        for (i = 0; i < 4; i = i+1) begin : pos
            assign piece_pos[i] = current_y[i]*GameWidth+current_x[i];
            assign pos_down[i] = (current_y[i]-1)*GameWidth+current_x[i];

            assign move_x[i] = which_move == 0 ? current_x[i]-1:current_x[i]+1;
            assign move_y[i] = current_y[i];
            assign pos_move[i] = move_y[i]*GameWidth+move_x[i];

            assign related_pos_y[i] = current_y[i]-current_y[POINT_OF_ROTATION];

            assign related_pos_x[i] = current_x[i]-current_x[POINT_OF_ROTATION];

            assign rot_right_x[i] = current_x[POINT_OF_ROTATION]+related_pos_y[i];
            assign rot_right_y[i] = current_y[POINT_OF_ROTATION]-related_pos_x[i];

            assign rot_left_x[i] = current_x[POINT_OF_ROTATION]-related_pos_y[i];
            assign rot_left_y[i] = current_y[POINT_OF_ROTATION]+related_pos_x[i];

            assign rot_x[i] = which_rot == 0 ? rot_left_x[i]:rot_right_x[i];
            assign rot_y[i] = which_rot == 0 ? rot_left_y[i]:rot_right_y[i];
            assign pos_rot[i] = (rot_y[i]*GameWidth)+rot_x[i];
        end
    endgenerate


    localparam Ready = 0;
    localparam InReseting = 1;
    localparam CheckingWhatsDown = 2;
    localparam Falling = 3;
    localparam CheckingWhatsMove = 4;
    localparam Move = 5;
    localparam CheckingRotation = 6;
    localparam Rotate = 7;
    localparam CheckIfCleared = 8;
    localparam WaitWithClearedLines = 9;
    localparam CopyingLine = 10;
    localparam WritePiece = 11;
    localparam SpawningNewPiece = 12;
    localparam GameOver = 15;

    reg [1:0]         piece_id = 0;
    reg [4:0]         state = InReseting;
    reg               down_clear = 1;
    reg               waiting_for_read = 0;
    reg               new_piece = 0;
    reg               initiate_move = 0;
    reg               initiate_rot = 0;
    reg signed [5:0]  checking_x = 0;
    reg signed [6:0]  checking_y = 0;
    reg [2:0]         num_lines_cleared = 0;
    reg signed [5:0]  copying_x = 0;
    reg signed [6:0]  copying_y = 0;
    reg               has_read_value = 0;

    localparam ClearedLinesPeriod = 1 << 25;
    reg [27:0]        waiting_count = 0;

    reg [15:0]        rng = 42;

    integer           id;
    always @(posedge clk) begin
        // Linear feedback shift register https://en.wikipedia.org/wiki/Linear-feedback_shift_register
        rng <= (rng >> 1) | ((rng ^ (rng >> 2) ^ (rng >> 3) ^ (rng >> 5)) << 15);
        fallen <= 0;
        case (state)
            Ready: begin
                if (reset_game) begin
                    state <= InReseting;
                    ram_query <= 0;
                    write_ram <= 1;
                    write_value <= 0;
                    game_over <= 0;
                    game_lines_cleared <= 0;
                end else if (next_fall) begin
                    state <= CheckingWhatsDown;
                    piece_id <= 0;
                    ram_query <= pos_down[0];
                    waiting_for_read <= 1;
                    down_clear <= 1;
                end else if (move_piece_left || move_piece_right) begin
                    which_move <= move_piece_right == 1;
                    state <= CheckingWhatsMove;
                    initiate_move <= 1;
                end else if (rotate_left || rotate_right) begin
                    which_rot <= rotate_right == 1; // 0 if left, 1 if right
                    state <= CheckingRotation;
                    initiate_rot <= 1;
                end

            end

            InReseting: begin
                ram_query <= ram_query+1;
                //debug[1] <= 1;
                if (ram_query+1 >= GameWidth*GameHeight) begin
                    write_ram <= 0;
                    state <= SpawningNewPiece;
                    piece_id <= 0;
                end
            end

            CheckingWhatsDown: begin // requires: piece_id, waiting_for_read, down_clear
                if (waiting_for_read)
                    waiting_for_read <= 0;
                else begin
                    if (ram_state != 0 || current_y[piece_id] == 0) begin
                        down_clear <= 0;
                        state <= Falling;
                    end

                    ram_query <= pos_down[piece_id+1];
                    waiting_for_read <= 1;
                    piece_id <= piece_id+1;
                    if (piece_id+1 >= 4) begin
                        state <= Falling;
                    end
                end
            end
            Falling: begin
                if (down_clear) begin
                    for (id = 0; id < 4; id = id+1)
                        current_y[id] <= current_y[id]-1;
                    new_piece <= 0;
                    state <= Ready;
                end else begin
                    if (new_piece)
                        state <= GameOver;
                    else begin
                        fallen <= 1;
                        state <= WritePiece;
                        piece_id <= 0;
                        ram_query <= piece_pos[0];
                        write_ram <= 1;
                        write_value <= current_piece;
                    end
                end

            end

            CheckingWhatsMove: begin // requires: initiate_move
                if (initiate_move) begin
                    initiate_move <= 0;
                    piece_id <= 0;
                    ram_query <= pos_move[0];
                    waiting_for_read <= 1;
                end if (waiting_for_read)
                    waiting_for_read <= 0;
                else begin
                        if (ram_state != 0 || move_x[piece_id] < 0 || move_x[piece_id] >= GameWidth)
                            state <= Ready;
                        else begin
                            ram_query <= pos_move[piece_id+1];
                            waiting_for_read <= 1;
                            piece_id <= piece_id+1;
                            if (piece_id+1 >= 4) begin
                                state <= Move;
                            end
                        end
                    end
            end
            Move: begin
                for (id = 0; id < 4; id = id+1)
                    current_x[id] <= move_x[id];
                // TODO if going down.
                state <= Ready;
            end

            CheckingRotation: begin // requires: initiate_rot
                if (initiate_rot) begin
                    initiate_rot <= 0;
                    piece_id <= 0;
                    ram_query <= pos_rot[0];
                    waiting_for_read <= 1;
                end else if (waiting_for_read)
                    waiting_for_read <= 0;
                else begin
                    if (ram_state != 0 || rot_x[piece_id] < 0 || rot_x[piece_id] >= GameWidth
                        || rot_y[piece_id] < 0 || rot_y[piece_id] >= GameHeight) begin
                        state <= Ready;
                    end else begin
                        ram_query <= pos_rot[piece_id+1];
                        waiting_for_read <= 1;
                        piece_id <= piece_id+1;
                        if (piece_id+1 >= 4) begin
                            state <= Rotate;
                        end
                    end
                end
            end
            Rotate: begin
                for (id = 0; id < 4; id = id+1) begin
                    current_x[id] <= rot_x[id];
                    current_y[id] <= rot_y[id];
                end
                state <= Ready;
            end

            WritePiece: begin // requires: piece_id, write_ram
                piece_id <= piece_id+1;
                ram_query <= piece_pos[piece_id+1];
                if (piece_id+1 >= 4) begin
                    write_ram <= 0;
                    checking_y <= 0;
                    checking_x <= 0;
                    ram_query <= 0;
                    waiting_for_read <= 1;
                    num_lines_cleared <= 0;
                    state <= CheckIfCleared;
                end
            end

            CheckIfCleared: begin // requires: waiting_for_read, checking_x, checking_y, ram_query
                if (checking_y >= GameHeight) begin
                    state <= WaitWithClearedLines;
                    waiting_count <= 0;
                end
                else if (waiting_for_read) begin
                    waiting_for_read <= 0;
                end else if (ram_state == 0) begin // Not cleared
                    checking_y <= checking_y+1;
                    checking_x <= 0;
                    ram_query <= (checking_y+1)*GameWidth+0;
                    waiting_for_read <= 1;
                end else begin // Possibly cleared line
                    checking_x <= checking_x+1;
                    waiting_for_read <= 1;
                    ram_query <= checking_y*GameWidth+checking_x+1;
                    if (checking_x+1 >= GameWidth) begin // Cleared_line
                        game_lines_cleared <= game_lines_cleared+1;
                        checking_y <= checking_y+1;
                        checking_x <= 0;
                        ram_query <= (checking_y+1)*GameWidth+0;
                        which_lines_cleared[checking_y] <= 1;
                    end
                end
            end
            WaitWithClearedLines: begin // waiting_count
                if (which_lines_cleared == 0)
                    state <= SpawningNewPiece;
                waiting_count <= waiting_count+1;
                if (waiting_count > ClearedLinesPeriod) begin
                    num_lines_cleared <= 0;
                    copying_x <= 0;
                    copying_y <= 0;
                    waiting_for_read <= 1;
                    ram_query <= 0;
                    state <= CopyingLine;
                end

            end

            CopyingLine: begin // requires: num_lines_cleared, copying_y, waiting_for_read, copying_x, writing_copy
                debug[0] <= 1;
                if (waiting_for_read) begin
                    waiting_for_read <= 0;
                    has_read_value <= 1;
                end
                else if (has_read_value) begin
                    debug[2] <= 1;
                    write_ram <= 1;
                    write_value <= ram_state;
                    ram_query <= (copying_y-num_lines_cleared)*GameWidth+copying_x;
                    has_read_value <= 0;
                end else begin
                    debug[3] <= 1;
                    write_ram <= 0;
                    copying_x <= copying_x+1;
                    ram_query <= copying_y*GameWidth+copying_x+1;
                    waiting_for_read <= 1;
                    if (copying_x+1 >= GameWidth) begin // Copied all values.
                        debug[4] <= 1;
                        copying_y <= copying_y+1;
                        copying_x <= 0;
                        ram_query <= (copying_y+1)*GameWidth+0;
                        if (which_lines_cleared[copying_y]) begin
                            debug[5] <= 1;
                            num_lines_cleared <= num_lines_cleared+1;
                            which_lines_cleared[copying_y] <= 0;
                        end
                        if (copying_y+1 >= GameHeight) begin
                            debug[6] <= 1;
                            state <= SpawningNewPiece;
                            waiting_for_read <= 0;
                        end
                    end
                end

            end

            SpawningNewPiece: begin
                for (id = 0; id < 4; id = id+1) begin
                    current_x[id] <= PiecesPos_X[next_piece*4+id];
                    current_y[id] <= PiecesPos_Y[next_piece*4+id];
                end
                current_piece <= next_piece;
                state <= Ready;
                new_piece <= 1;
                next_piece <= rng[2:0];
                if (rng[2:0] > 7)
                    next_piece <= 1;
                if (rng[2:0] == 0)
                    next_piece <= 3;
            end
            GameOver: begin
                game_over <= 1;
                if (reset_game) begin
                    state <= InReseting;
                    ram_query <= 0;
                    write_ram <= 1;
                    write_value <= 0;
                    game_over <= 0;
                end
            end
        endcase
    end

endmodule

