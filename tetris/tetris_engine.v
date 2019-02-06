`default_nettype none

module tetris_engine(
    input            clk,
    input            reset,
    input            next_fall,
    // User inputs
    input            move_piece_right,
    input            move_piece_left,

    input  [11:0]    display_query_pos,

    output reg [2:0] next_piece = 1,
    output [2:0]     display_query_res,
    output           game_over,
    output reg [7:0] debug = 0
);
    localparam GameWidth = 10;
    localparam GameHeight = 20;
    localparam NumPieces = 7;
        // Numerate pieces from 1 to 8
    wire [3:0] PiecesPos_X[4+4*NumPieces-1:4];
    wire [4:0] PiecesPos_Y[4+4*NumPieces-1:4];
        // Z piece
    assign PiecesPos_X[4] = 5;
    assign PiecesPos_X[5] = 6;
    assign PiecesPos_X[6] = 6;
    assign PiecesPos_X[7] = 7;

    assign PiecesPos_Y[4] = 19;
    assign PiecesPos_Y[5] = 19;
    assign PiecesPos_Y[6] = 18;
    assign PiecesPos_Y[7] = 18;

        // T piece
    assign PiecesPos_X[8] = 6;
    assign PiecesPos_X[9] = 5;
    assign PiecesPos_X[10] = 6;
    assign PiecesPos_X[11] = 7;

    assign PiecesPos_Y[8] = 19;
    assign PiecesPos_Y[9] = 18;
    assign PiecesPos_Y[10] = 18;
    assign PiecesPos_Y[11] = 18;

        // S piece
    assign PiecesPos_X[12] = 6;
    assign PiecesPos_X[13] = 7;
    assign PiecesPos_X[14] = 5;
    assign PiecesPos_X[15] = 6;

    assign PiecesPos_Y[12] = 19;
    assign PiecesPos_Y[13] = 18;
    assign PiecesPos_Y[14] = 18;
    assign PiecesPos_Y[15] = 18;

        // O piece
    assign PiecesPos_X[16] = 6;
    assign PiecesPos_X[17] = 7;
    assign PiecesPos_X[18] = 6;
    assign PiecesPos_X[19] = 7;

    assign PiecesPos_Y[16] = 19;
    assign PiecesPos_Y[17] = 19;
    assign PiecesPos_Y[18] = 18;
    assign PiecesPos_Y[19] = 18;

        // L piece
    assign PiecesPos_X[20] = 7;
    assign PiecesPos_X[21] = 5;
    assign PiecesPos_X[22] = 6;
    assign PiecesPos_X[23] = 7;

    assign PiecesPos_Y[20] = 19;
    assign PiecesPos_Y[21] = 18;
    assign PiecesPos_Y[22] = 18;
    assign PiecesPos_Y[23] = 18;

        // J piece
    assign PiecesPos_X[24] = 5;
    assign PiecesPos_X[25] = 5;
    assign PiecesPos_X[26] = 6;
    assign PiecesPos_X[27] = 7;

    assign PiecesPos_Y[24] = 19;
    assign PiecesPos_Y[25] = 18;
    assign PiecesPos_Y[26] = 18;
    assign PiecesPos_Y[27] = 18;

        // I piece
    assign PiecesPos_X[28] = 5;
    assign PiecesPos_X[29] = 6;
    assign PiecesPos_X[30] = 7;
    assign PiecesPos_X[31] = 8;

    assign PiecesPos_Y[28] = 18;
    assign PiecesPos_Y[29] = 18;
    assign PiecesPos_Y[30] = 18;
    assign PiecesPos_Y[31] = 18;


    reg        write_ram;
    reg [2:0]  write_value;
    reg [11:0] ram_query;
    wire [3:0] ram_state;


    wire [3:0] display_ram;


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


    reg [3:0]  current_x [3:0];
    reg [4:0]  current_y [3:0];
    reg [2:0]  current_piece = 1;
    wire [7:0] piece_pos[3:0];
    wire [7:0] pos_down[3:0];
    wire [7:0] pos_right[3:0];
    wire [7:0] pos_left[3:0];

    assign display_query_res = (display_query_pos == piece_pos[0]
        || display_query_pos == piece_pos[1]
        || display_query_pos == piece_pos[2]
        || display_query_pos == piece_pos[3]) ? current_piece:display_ram[2:0];

    genvar i;
    generate
        for (i = 0; i < 4; i = i+1) begin : pos
            assign piece_pos[i] = current_y[i]*GameWidth+current_x[i];
            assign pos_down[i] = (current_y[i]-1)*GameWidth+current_x[i];
            assign pos_right[i] = (current_y[i])*GameWidth+current_x[i]+1;
            assign pos_left[i] = (current_y[i])*GameWidth+current_x[i]-1;
        end
    endgenerate


    localparam Ready = 0;
    localparam InReseting = 1;
    localparam CheckingWhatsDown = 2;
    localparam Falling = 3;
    localparam CheckingWhatsRight = 4;
    localparam MoveRight = 5;
    localparam WritePiece = 6;
    localparam SpawningNewPiece = 7;


    reg [1:0]  piece_id = 0;
    reg [4:0]  state = InReseting;
    reg        down_clear = 1;
    reg        waiting_for_read = 0;

    always @(posedge clk) begin
        debug[state] <= 1;
        case (state)
            Ready: begin
                if (reset) begin
                    state <= InReseting;
                    ram_query <= 0;
                    write_ram <= 1;
                    write_value <= 0;
                end else if (next_fall) begin
                    state <= CheckingWhatsDown;
                    piece_id <= 0;
                    ram_query <= pos_down[0];
                    waiting_for_read <= 1;
                    down_clear <= 1;
                end else if (move_piece_right) begin
                    state <= CheckingWhatsRight;
                    piece_id <= 0;
                    ram_query <= pos_right[0];
                    waiting_for_read <= 1;
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
                        current_piece <= next_piece;
                        state <= Falling;
                    end
                end
            end
            Falling: begin
                if (down_clear) begin
                    current_y[0] <= current_y[0]-1;
                    current_y[1] <= current_y[1]-1;
                    current_y[2] <= current_y[2]-1;
                    current_y[3] <= current_y[3]-1;
                    state <= Ready;
                end else begin
                    state <= WritePiece;
                    piece_id <= 0;
                    ram_query <= piece_pos[0];
                    write_ram <= 1;
                    write_value <= current_piece;
                end

            end

            CheckingWhatsRight: begin // requires: piece_id, waitint_for_read
                if (waiting_for_read)
                    waiting_for_read <= 0;
                else begin
                    if (ram_state != 0 || current_x[piece_id] == GameWidth - 1) begin
                        state <= Ready;
                    end

                    ram_query <= pos_right[piece_id+1];
                    waiting_for_read <= 1;
                    piece_id <= piece_id+1;
                    if (piece_id+1 >= 4) begin
                        current_piece <= next_piece;
                        state <= MoveRight;
                    end
                end
            end
            MoveRight: begin
                current_x[0] <= current_x[0] + 1;
                current_x[1] <= current_x[1] + 1;
                current_x[2] <= current_x[2] + 1;
                current_x[3] <= current_x[3] + 1;
                state <= Ready;
            end

            WritePiece: begin // requires: piece_id, write_ram
                piece_id <= piece_id+1;
                ram_query <= piece_pos[piece_id+1];
                if (piece_id+1 >= 4) begin
                    write_ram <= 0;
                    state <= SpawningNewPiece;
                end
            end

            SpawningNewPiece: begin // requires: piece_id
                current_x[piece_id] <= PiecesPos_X[next_piece*4+piece_id];
                current_y[piece_id] <= PiecesPos_Y[next_piece*4+piece_id];

                piece_id <= piece_id+1;
                if (piece_id+1 >= 4) begin
                    current_piece <= next_piece;
                    state <= Ready;
                    next_piece <= next_piece+1;
                    if (next_piece+1 > 7)
                        next_piece <= 1;
                end
            end

        endcase
    end


endmodule

