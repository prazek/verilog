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

    parameter WIDTH = 200;
    parameter HEIGHT = 320;

        // wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)

        // generate a 25 MHz pixel strobe
    reg [15:0]  cnt = 0;
    reg         pix_stb;
    always @(posedge clk)
        {pix_stb, cnt} <= cnt+16'h4000;  // divide by 4: (2^16)/4 = 0x4000

    wire [9:0]  x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0]  y;  // current pixel y position:  9-bit value: 0-511

    vga640x480 display(
        .i_clk    (clk),
        .i_pix_stb(pix_stb),
        .i_rst    (reset),
        .o_hs     (hsync),
        .o_vs     (vsync),
        .o_x      (x),
        .o_y      (y)
    );


    wire [8:0]  real_x = x >> 1;
    wire [7:0]  real_y = y >> 1;


    wire        ram_out_t[3:0];
    wire [15:0] pixel_num = (real_y*WIDTH+real_x);
    wire [13:0] ram_addr = pixel_num[13:0];
    wire [2:0]  which_ram = pixel_num[15:13];
    wire        ram_out = ram_out_t[which_ram];

    wire        set_pixel = ((x > 120) & (y > 40) & (x < 280) & (y < 200)) ? 1:0;

    genvar i;
    generate
        // We need 4 block ram
        for (i = 0; i < 4; i = i+1) begin : gen_blockram
            // We use first port for reading and second for writing.
            RAMB16_S1_S1 ramen(
                .DOA  (ram_out_t[i]), // Port A 1-bit Data Output
                //.DOB  (DOB), // Port B 1-bit Data Output
                .ADDRA(ram_addr), // Port A 14-bit Address Input
                // TODO
                .ADDRB(0), // Port B 14-bit Address Input
                .CLKA (clk), // Port A Clock
                .CLKB (clk), // Port B Clock
                .DIA  (0), // Port A 1-bit Data Input
                .DIB  (set_pixel), // Port B 1-bit Data Input
                .ENA  (1), // Port A RAM Enable Input
                .ENB  (1), // Port B RAM Enable Input
                //.SSRA (SSRA), // Port A Synchronous Set/Reset Input
                //.SSRB (SSRB), // Port B Synchronous Set/Reset Input
                .WEA  (0), // Port A Write Enable Input
                .WEB  (1) // Port B Write Enable Input
            );
        end
    endgenerate

    assign VGA_R[2:0] = {ram_out, ram_out, ram_out};
    assign VGA_G[2:0] = {ram_out, ram_out, ram_out};
    assign VGA_B[2:1] = {ram_out, ram_out};

endmodule