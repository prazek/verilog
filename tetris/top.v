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
    ActionGenerator move_right_action(
        .in (syn_btn[0]),
        .clk(CLK),
        .out(move_right)
    );

    wire       move_left;
    ActionGenerator move_left_action(
        .in (syn_btn[1]),
        .clk(CLK),
        .out(move_left)
    );

    wire       rotate_right;
    ActionGenerator rotate_right_action(
        .in (syn_btn[2]),
        .clk(CLK),
        .out(rotate_right)
    );

    wire       rotate_left;
    ActionGenerator rotate_left_action(
        .in (syn_btn[3]),
        .clk(CLK),
        .out(rotate_left)
    );

    wire reset_game;
    ActionGenerator reset_game_action(
        .in (syn_btn[0] & syn_btn[1]),
        .clk(CLK),
        .out(reset_game)
    );
    wire game_over;

    tetris game(
        .clk       (CLK),
        .reset_game  (reset_game & game_over),
        // vga outs
        .hsync     (HSYNC),
        .vsync     (VSYNC),
        .VGA_R     (VGA_R),
        .VGA_G     (VGA_G),
        .VGA_B     (VGA_B),
        .move_right(move_right),
        .move_left (move_left),
        .rotate_right(rotate_right),
        .rotate_left(rotate_left),
        .game_over(game_over),
        .debug     (Led[7:0])
    );


    wire       start_fill;
    wire       start_blit;
    wire       fill_value;
    wire       start_ram_read;
    wire       start_ram_write;
    wire [8:0] X1;
    wire [7:0] Y1;
    wire [8:0] X2;
    wire [7:0] Y2;
    wire [8:0] op_width;
    wire [7:0] op_height;
    wire       error;
    wire       status;
    wire       ram_byte_ready;
    wire [7:0] ram_byte;
    wire [7:0] write_ram_byte;

    EPP epp(
        .clk            (CLK),
        .EppAstb        (EppAstb),
        .EppDstb        (EppDstb),
        .EppWR          (EppWR),
        .EppWait        (EppWait),
        .EppDB          (EppDB),
        .X1             (X1),
        .Y1             (Y1),
        .X2             (X2),
        .Y2             (Y2),
        .op_width       (op_width),
        .op_height      (op_height),
        .start_fill     (start_fill),
        .fill_value     (fill_value),
        .start_blit     (start_blit),
        .start_read_ram (start_ram_read),
        .status         (status),
        .ram_byte_ready (ram_byte_ready),
        .ram_byte       (ram_byte),
        .write_ram_byte (write_ram_byte),
        .start_write_ram(start_ram_write)
    );

endmodule





/*
    wire       start_fill;
    wire       start_blit;
    wire       fill_value;
    wire       start_ram_read;
    wire       start_ram_write;
    wire [8:0] X1;
    wire [7:0] Y1;
    wire [8:0] X2;
    wire [7:0] Y2;
    wire [8:0] op_width;
    wire [7:0] op_height;
    wire       error;
    wire       status;
    wire       ram_byte_ready;
    wire [7:0] ram_byte;
    wire [7:0] write_ram_byte;

        //assign Led = {8{error}};
        //assign Led = 0;


    assign Led[7] = btn[0];


    EPP epp(
        .clk            (CLK),
        .EppAstb        (EppAstb),
        .EppDstb        (EppDstb),
        .EppWR          (EppWR),
        .EppWait        (EppWait),
        .EppDB          (EppDB),
        .X1             (X1),
        .Y1             (Y1),
        .X2             (X2),
        .Y2             (Y2),
        .op_width       (op_width),
        .op_height      (op_height),
        .start_fill     (start_fill),
        .fill_value     (fill_value),
        .start_blit     (start_blit),
        .start_read_ram (start_ram_read),
        .status         (status),
        .ram_byte_ready (ram_byte_ready),
        .ram_byte       (ram_byte),
        .write_ram_byte (write_ram_byte),
        .start_write_ram(start_ram_write)
    );


endmodule*/