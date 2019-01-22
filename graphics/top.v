`default_nettype none

module top(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire [3:0]btn,         // reset button
    output wire HSYNC,       // horizontal sync output
    output wire VSYNC,       // vertical sync output
    output wire [3:0] VGA_R,    // 4-bit VGA red output
    output wire [3:0] VGA_G,    // 4-bit VGA green output
    output wire [3:0] VGA_B,     // 4-bit VGA blue output
    output wire [7:0] Led
);
    assign Led = 0;

    GraphicsCard graphics(
        .clk(CLK),
        .reset(0),
        .hsync(HSYNC),
        .vsync(VSYNC),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B)
    );


endmodule