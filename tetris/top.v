`default_nettype none

module Synchronizer#(parameter BIT_NUM = 1, DEFAULT_VAL = 0)
(
    input [BIT_NUM-1:0]      in,
    input wire               clk,
    output reg [BIT_NUM-1:0] out
);
    reg [BIT_NUM-1:0] tmp1 = DEFAULT_VAL;
    reg [BIT_NUM-1:0] tmp2 = DEFAULT_VAL;
    always @(posedge clk) begin
        tmp1 <= in;
        tmp2 <= tmp1;
        out <= tmp2;
    end

endmodule

module ActionGenerator(
    input wire in,
    input wire clk,
    output reg out
);
    reg previous_state = 0;
    always @(posedge clk) begin
        out <= 0;
        if (in != previous_state) begin
            previous_state <= in;
            out <= in;
        end
    end
endmodule


module top(
    input            CLK,    // board clock: 50 MHz on Arty/Basys3/Nexys
    input            EppAstb,
    input            EppDstb,
    input            EppWR,
    output           EppWait,
    inout wire [7:0] EppDB,

    output           HSYNC,    // horizontal sync output
    output           VSYNC,    // vertical sync output
    output     [2:0] VGA_R,    // 3-bit VGA red output
    output     [2:0] VGA_G,    // 3-bit VGA green output
    output     [2:1] VGA_B,    // 2-bit VGA blue output
    output     [7:0] Led,

    input      [3:0] btn
);

    wire [3:0] syn_btn;
    Synchronizer#(.BIT_NUM(4)) btn_syn(
        .in (btn),
        .clk(CLK),
        .out(syn_btn)
    );

    wire       move_right;
    ActionGenerator move_right_action(syn_btn[0], CLK, move_right);
    wire       move_left;
    ActionGenerator move_left_action(syn_btn[1], CLK, move_left);
    wire       rotate_right;
    ActionGenerator rotate_right_action(syn_btn[2], CLK, rotate_right);
    wire       rotate_left;
    ActionGenerator rotate_left_action(syn_btn[3], CLK,rotate_left);
    wire       reset_game;
    ActionGenerator reset_game_action(syn_btn[0] & syn_btn[1], CLK, reset_game);
    wire       game_over;

    wire       epp_move_left, epp_move_right, epp_move_down, epp_drop, epp_rotate_right, epp_rotate_left;
    wire       epp_moving_left, epp_moving_right, epp_moving_down, epp_dropping, epp_rotating_right, epp_rotating_left;

    ActionGenerator action_epp_move_left(epp_move_left, CLK, epp_moving_left);
    ActionGenerator action_epp_move_right(epp_move_right, CLK, epp_moving_right);
    ActionGenerator action_epp_move_down(epp_move_down, CLK, epp_moving_down);
    ActionGenerator action_epp_drop(epp_drop, CLK, epp_dropping);
    ActionGenerator action_epp_rotate_right(epp_rotate_right, CLK, epp_rotating_right);
    ActionGenerator action_epp_rotate_left(epp_rotate_left, CLK, epp_rotating_left);

    tetris game(
        .clk         (CLK),
        .reset_game  (reset_game & game_over),
        // vga outs
        .hsync       (HSYNC),
        .vsync       (VSYNC),
        .VGA_R       (VGA_R),
        .VGA_G       (VGA_G),
        .VGA_B       (VGA_B),
        .move_right  (move_right | epp_moving_right),
        .move_left   (move_left | epp_moving_left),
        .move_down   (epp_moving_down),
        .drop        (epp_dropping),
        .rotate_right(rotate_right | epp_rotating_right),
        .rotate_left (rotate_left | epp_rotating_left),
        .game_over   (game_over),
        .debug       (Led[7:0])
    );

    EPP epp(
        .clk         (CLK),
        .EppAstb     (EppAstb),
        .EppDstb     (EppDstb),
        .EppWR       (EppWR),
        .EppWait     (EppWait),
        .EppDB       (EppDB),
        .move_left   (epp_move_left),
        .move_right  (epp_move_right),
        .move_down   (epp_move_down),
        .drop        (epp_drop),
        .rotate_left (epp_rotate_left),
        .rotate_right(epp_rotate_right)
    );

endmodule
