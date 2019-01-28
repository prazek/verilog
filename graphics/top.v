`default_nettype none

module top(
    input            CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input            EppAstb,
    input            EppDstb,
    input            EppWR,
    input            EppWait,
    inout wire [7:0] EppDB,

    output           HSYNC,       // horizontal sync output
    output           VSYNC,       // vertical sync output
    output     [2:0] VGA_R,    // 3-bit VGA red output
    output     [2:0] VGA_G,    // 3-bit VGA green output
    output     [2:1] VGA_B,     // 2-bit VGA blue output
    output     [7:0] Led
);

    wire        start_fill;
    wire        start_blit;
    wire        fill_value;
    wire [8:0] X1;
    wire [7:0] Y1;
    wire [8:0] X2;
    wire [7:0] Y2;
    wire [8:0] op_width;
    wire [7:0] op_height;
    wire error;


   // assign Led = {8{error}};
    GraphicsCard graphics(
        .clk       (CLK),
        .reset     (0),
        // ops
        .X1        (X1),
        .Y1        (Y1),
        .X2        (X2),
        .Y2        (Y2),
        .start_fill(start_fill),
        .fill_value(fill_value),
        .start_blit(start_blit),
        .blit_x_width(op_width),
        .blit_y_height(op_height),
        // out
        .hsync     (HSYNC),
        .vsync     (VSYNC),
        .VGA_R     (VGA_R),
        .VGA_G     (VGA_G),
        .VGA_B     (VGA_B),
        .error(error),
        .debug_cnt(Led)
    );


    EPP epp(
        .clk       (CLK),
        .EppAstb   (EppAstb),
        .EppDstb   (EppDstb),
        .EppWR     (EppWR),
        .EppWait   (EppWait),
        .EppDB     (EppDB),
        .X1        (X1),
        .Y1        (Y1),
        .X2        (X2),
        .Y2        (Y2),
        .op_width(op_width),
        .op_height(op_height),
        .start_fill(start_fill),
        .fill_value(fill_value),
        .start_blit(start_blit)
    );


endmodule