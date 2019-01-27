`default_nettype none

module top(
    input            CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input      [3:0] btn,         // reset button
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
    assign Led = 0;

    wire        start_fill;
    wire        fill_value;
    wire [15:0] X1;
    wire [15:0] Y1;
    wire [15:0] X2;
    wire [15:0] Y2;


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
        // out
        .hsync     (HSYNC),
        .vsync     (VSYNC),
        .VGA_R     (VGA_R),
        .VGA_G     (VGA_G),
        .VGA_B     (VGA_B)
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
        .start_fill(start_fill),
        .fill_value(fill_value)
    );


endmodule