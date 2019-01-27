`default_nettype none

module GraphicsCard(
    input wire        clk,      // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire        reset,    // reset button
    output wire       hsync,    // horizontal sync output
    output wire       vsync,    // vertical sync output
    output wire [2:0] VGA_R,    // 3-bit VGA red output
    output wire [2:0] VGA_G,    // 3-bit VGA green output
    output wire [2:1] VGA_B     // 2-bit VGA blue output
);

    parameter WIDTH = 320;
    parameter HEIGHT = 200;

        // wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)


    wire vclk;
        // generate a 25 MHz pixel strobe
    DCM_SP #(
    .CLKFX_DIVIDE(4),
    .CLKFX_MULTIPLY(2),
    .CLKIN_PERIOD(50),
    .CLK_FEEDBACK("NONE"),
    .STARTUP_WAIT("TRUE")
    ) dcm_vclk (
        .CLKFX(vclk),
        .CLKIN(clk)
    );


    wire [9:0]  x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0]  y;  // current pixel y position:  9-bit value: 0-511
    wire out_active;
    vga640x400 display(
        .i_clk    (clk),
        .i_pix_stb(vclk),
        .i_rst    (reset),
        .o_hs     (hsync),
        .o_vs     (vsync),
        .o_x      (x),
        .o_y      (y),
        .o_active(out_active)
    );

    // Get pixels in resolution 320x200
    wire [8:0]  real_x = x >> 1;       // 0 - 511
    wire [7:0]  real_y = y >> 1;       // 0 - 255


    wire        ram_out_t[3:0];
    wire [15:0] pixel_num = (real_y*WIDTH+real_x);
    wire [13:0] ram_addr = pixel_num[13:0];
    wire [1:0]  which_ram = pixel_num[15:14];
    wire        ram_out = ram_out_t[which_ram];

    //wire        set_pixel = ((x > 120) & (y > 40) & (x < 280) & (y < 200)) ? 1:0;
    wire        set_pixel = ((x >= 1) & (y >= 1) & (x < 640) & (y < 400)) ? 1:0;
    genvar i;

    wire use_ram = out_active;

    generate
        // We need 4 block ram
        for (i = 0; i < 4; i = i+1) begin : gen_blockram
            // We use first port for reading and second for writing.
            RAMB16_S1_S1 #(
                .INIT_00(~256'h0000000000000000000000000000000000000000000000000000000000000000),
            .INIT_3F(~256'h0000000000000000000000000000000000000000000000000000000000000000))
            ramen(
                .DOA  (ram_out_t[i]), // Port A 1-bit Data Output
                //.DOB  (DOB), // Port B 1-bit Data Output
                .ADDRA(ram_addr), // Port A 14-bit Address Input
                .ADDRB(ram_addr), // Port B 14-bit Address Input
                .CLKA (clk), // Port A Clock
                .CLKB (clk), // Port B Clock
                .DIA  (0), // Port A 1-bit Data Input
                .DIB  (0), // Port B 1-bit Data Input
                .ENA  (use_ram), // Port A RAM Enable Input
                .ENB  (0 && which_ram == i), // Port B RAM Enable Input
                //.SSRA (SSRA), // Port A Synchronous Set/Reset Input
                //.SSRB (1), // Port B Synchronous Set/Reset Input
                .WEA  (0), // Port A Write Enable Input
                .WEB  (1) // Port B Write Enable Input
            );
        end
    endgenerate

    wire pixel_value = ram_out & out_active;
    assign VGA_R[2:0] = {3{pixel_value}};
    assign VGA_G[2:0] = {3{pixel_value}};
    assign VGA_B[2:1] = {2{pixel_value}};

endmodule