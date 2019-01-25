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

    GraphicsCard graphics(
        .clk  (CLK),
        .reset(0),
        .hsync(HSYNC),
        .vsync(VSYNC),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B)
    );

    EPP epp(
        .clk    (CLK),
        .EppAstb(EppAstb),
        .EppDstb(EppDstb),
        .EppWR  (EppWR),
        .EppWait(EppWait),
        .EppDB  (EppDB)
    );


endmodule