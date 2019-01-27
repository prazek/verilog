`default_nettype none

module GraphicsCard(
    input wire        clk,      // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire        reset,    // reset button
    // Operations
    input       [8:0] X1,
    input       [7:0] Y1,
    input       [8:0] X2,
    input       [7:0] Y2,
    input             start_fill,
    input             fill_value,
    // VGA out
    output wire       hsync,    // horizontal sync output
    output wire       vsync,    // vertical sync output
    output wire [2:0] VGA_R,    // 3-bit VGA red output
    output wire [2:0] VGA_G,    // 3-bit VGA green output
    output wire [2:1] VGA_B     // 2-bit VGA blue output
);

    wire       vclk;
        // generate a 25 MHz pixel strobe
    DCM_SP#(
    .CLKFX_DIVIDE(4),
    .CLKFX_MULTIPLY(2),
    .CLKIN_PERIOD(50),
    .CLK_FEEDBACK("NONE"),
    .STARTUP_WAIT("TRUE")
    ) dcm_vclk(
        .CLKFX(vclk),
        .CLKIN(clk)
    );

    wire [9:0] display_x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0] display_y;  // current pixel y position:  9-bit value: 0-511
    wire       out_active;
    wire       out_blanking;
    vga640x400 display(
        .i_clk     (clk),
        .i_pix_stb (vclk),
        .i_rst     (reset),
        .o_hs      (hsync),
        .o_vs      (vsync),
        .o_x       (display_x),
        .o_y       (display_y),
        .o_blanking(out_blanking),
        .o_active  (out_active)
    );

    wire       pixel_value;
    wire [8:0] real_disp_x = display_x >> 1;       // 0 - 511
    wire [7:0] real_disp_y = display_y >> 1;       // 0 - 255

    reg        ram_enable_write;
    reg        ram_write_value;

    reg [8:0]  current_x = 0;
    reg [7:0]  current_y = 0;

    GPU_RAM gpuram(
        .clk          (clk),
        .x1           (real_disp_x),
        .y1           (real_disp_y),
        .enable_read1 (out_active),
        .read_value1  (pixel_value),
        .x2           (current_x),
        .y2           (current_y),
        .enable_read2 (0),
        .enable_write2(ram_enable_write),
        .write_value  (ram_write_value)
    );

    wire       output_value = pixel_value & out_active;
    assign VGA_R[2:0] = {3{output_value}};
    assign VGA_G[2:0] = {3{output_value}};
    assign VGA_B[2:1] = {2{output_value}};

    localparam READY_STATE = 0;
    localparam INITIATE_FILL_STATE = 1;
    localparam FILL_IN_PROGRESS = 2;

    reg [4:0]  state = READY_STATE;

    reg        op_fill_value = 0;
    reg [8:0]  opX1;
    reg [7:0]  opY1;
    reg [8:0]  opX2;
    reg [7:0]  opY2;

    always @(posedge clk) begin
        case (state)
            READY_STATE: begin
                if (start_fill) begin
                    state <= INITIATE_FILL_STATE;
                    opX1 <= X1;
                    opX2 <= X2;
                    opY1 <= Y1;
                    opY2 <= Y2;
                    op_fill_value <= fill_value;
                end
            end
            INITIATE_FILL_STATE: begin
                if (opX1 <= opX2 && opY1 <= opY2) begin
                    state <= FILL_IN_PROGRESS;
                    current_x <= opX1;
                    current_y <= opY1;
                    ram_write_value <= op_fill_value;
                    ram_enable_write <= 1;
                end else // invalid fill values
                    state <= READY_STATE;
            end
            FILL_IN_PROGRESS: begin
                current_x <= current_x+1;
                if (current_x+1 > opX2) begin
                    current_x <= opX1;
                    current_y <= current_y+1;
                    if (current_y+1 > opY2) begin
                        ram_enable_write <= 0;
                        state <= READY_STATE;
                    end
                end

            end

        endcase
    end

endmodule