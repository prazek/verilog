`default_nettype none

module GraphicsCard#(parameter WIDTH = 320,
                     parameter HEIGHT = 200)
(

    input wire        clk,      // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire        reset,    // reset button
    // Operations
    input       [8:0] X1,
    input       [7:0] Y1,
    input       [8:0] X2,
    input       [7:0] Y2,
    input             start_fill,
    input             fill_value,
    input             start_blit,
    input       [8:0] op_x_width,
    input       [7:0] op_y_height,
    input             start_ram_read,
    input             start_ram_write,
    input       [7:0] write_ram_byte,

    // VGA out
    output wire       hsync,    // horizontal sync output
    output wire       vsync,    // vertical sync output
    output wire [2:0] VGA_R,    // 3-bit VGA red output
    output wire [2:0] VGA_G,    // 3-bit VGA green output
    output wire [2:1] VGA_B,     // 2-bit VGA blue output
    // ops out
    output            busy,
    output            error,
    output            ram_byte_ready,
    output      [7:0] ram_byte,
    output reg [7:0]  debug
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
    vga640x400 display(
        .i_clk    (clk),
        .i_pix_stb(vclk),
        .i_rst    (reset),
        .o_hs     (hsync),
        .o_vs     (vsync),
        .o_x      (display_x),
        .o_y      (display_y),
        .o_active (out_active)
    );

    //wire       is_last_column = display_x + 1 >= WIDTH*2;
    wire [9:0] next_x = display_x & 1 ? display_x+1:display_x;


    wire [8:0] read_x = out_active ? next_x >> 1:0;
    wire [7:0] read_y = display_y >> 1;

    wire       pixel_value;

    always @(posedge clk) begin
        if (display_x == 639) begin
            debug[0] <= out_active;
            //debug <= read_x;
        end
        if (display_x == 640) begin
            debug[1] <= 1;
            debug[2] <= out_active;
        end
        if (display_x == 0) begin
            debug[3] <= 1;
            debug[4] <= out_active;
        end
    end

    wire [8:0] ram_x;
    wire [7:0] ram_y;
    wire       op_ram_enable_write;
    wire       op_ram_write_value;
    wire       op_enable_read;
    wire       op_ram_value;

    GPU_RAM#(.WIDTH(WIDTH), .HEIGHT(HEIGHT))
    gpu_ram(
        .clk          (vclk),
        .x1           (read_x),
        .y1           (read_y),
        .enable_read1 (1),
        .read_value1  (pixel_value),
        .clk2         (clk),
        .x2           (ram_x),
        .y2           (ram_y),
        .enable_read2 (op_enable_read),
        .read_value2  (op_ram_value),
        .enable_write2(op_ram_enable_write),
        .write_value  (op_ram_write_value)
    );

    GPU_Operations#(.HEIGHT(HEIGHT), .WIDTH(WIDTH))
    ops(
        .clk                (clk),
        ._X1                (X1),
        ._Y1                (Y1),
        ._X2                (X2),
        ._Y2                (Y2),
        ._start_fill        (start_fill),
        ._fill_value        (fill_value),
        ._start_blit        (start_blit),
        ._op_x_width        (op_x_width),
        ._op_y_height       (op_y_height),
        ._op_ram_value      (op_ram_value),
        ._start_ram_read    (start_ram_read),
        ._start_ram_write   (start_ram_write),
        ._write_ram_byte    (write_ram_byte),
        // outs
        .ram_x              (ram_x),
        .ram_y              (ram_y),
        .op_ram_enable_read (op_enable_read),
        .op_ram_enable_write(op_ram_enable_write),
        .op_ram_write_value (op_ram_write_value),
        .busy               (busy),
        .error              (error),
        .ram_byte_ready     (ram_byte_ready),
        .ram_byte           (ram_byte)
    );


    wire       output_value = pixel_value & out_active;
    assign VGA_R[2:0] = {3{output_value}};
    assign VGA_G[2:0] = {3{output_value}};
    assign VGA_B[2:1] = {2{output_value}};

endmodule