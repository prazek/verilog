`default_nettype none

module GPU_Operations#(parameter WIDTH = 320,
                       parameter HEIGHT = 200)
(
    input            clk,
    input [8:0]      _X1,
    input [7:0]      _Y1,
    input [8:0]      _X2,
    input [7:0]      _Y2,
    input            _start_fill,
    input            _fill_value,
    input            _start_blit,
    input [8:0]      _op_x_width,
    input [7:0]      _op_y_height,
    input            _op_ram_value,
    input            _start_ram_read,
    input            _start_ram_write,
    input [7:0]      _write_ram_byte,

    output reg [8:0] ram_x,
    output reg [7:0] ram_y,
    output reg       op_ram_enable_read,
    output reg       op_ram_enable_write,
    output reg       op_ram_write_value,
    output           busy,
    output reg       error,
    output reg [7:0] ram_byte,
    output reg       ram_byte_ready,
    output reg [7:0] debug_cnt = 0
);

    initial op_ram_enable_write = 0;
    initial op_ram_write_value = 0;
    initial op_ram_enable_read = 0;

    localparam READY_STATE = 0;
    localparam FILL_IN_PROGRESS = 1;
    localparam BLIT_IN_PROGESS = 2;
    localparam RAM_READING_IN_PROGRESS = 3;
    localparam RAM_WRITING_IN_PROGRESS = 4;


    reg [4:0]  state = READY_STATE;
    assign busy = state != READY_STATE;

        // Copy of input values.
    reg [8:0]  opX1;
    reg [7:0]  opY1;
    reg [8:0]  opX2;
    reg [7:0]  opY2;
    reg [8:0]  op_x_width;
    reg [7:0]  op_y_height;
    reg [7:0]  op_write_ram_byte;
    wire [3:0] which_bit_of_ram = ram_x-opX1;

    reg [8:0]  blit_x_offset;
    reg [7:0]  blit_y_offset;
    reg        wait_for_read = 0;
    wire       leftToRight = (_X1 > _X2);
    wire       topToDown = (_Y1 > _Y2);
    wire       change_line = leftToRight ? (blit_x_offset+1 == op_x_width):(blit_x_offset == 0);
    wire       finished_lines = topToDown ? (blit_y_offset+1 == op_y_height):(blit_y_offset == 0);

    always @(posedge clk) begin
        case (state)
            READY_STATE: begin
                op_ram_write_value <= 0;
                op_ram_enable_write <= 0;
                op_ram_enable_read <= 0;
                ram_byte_ready <= 0;
                // Copy values so that they won't change while executing
                opX1 <= _X1;
                opX2 <= _X2;
                opY1 <= _Y1;
                opY2 <= _Y2;
                op_x_width <= _op_x_width;
                op_y_height <= _op_y_height;

                if (_start_fill | _start_blit) begin
                    error <= 0;
                    if (_X1 > WIDTH || _X2 > WIDTH || _Y1 > HEIGHT || _Y2 > HEIGHT) begin
                        error <= 1;
                    end else if (_start_fill) begin
                        state <= FILL_IN_PROGRESS;
                        ram_x <= _X1;
                        ram_y <= _Y1;
                        op_ram_write_value <= _fill_value;
                        op_ram_enable_write <= 1;
                        debug_cnt <= debug_cnt | 1;
                    end else if (_start_blit) begin
                        state <= BLIT_IN_PROGESS;
                        ram_x <= _X1;
                        ram_y <= _Y1;
                        blit_x_offset <= leftToRight ? 0:_op_x_width-1;
                        blit_y_offset <= topToDown ? 0:_op_y_height-1;
                        op_ram_enable_read <= 1;
                        wait_for_read <= 1;
                        debug_cnt <= debug_cnt | 2;
                    end
                end else if (_start_ram_read) begin
                    state <= RAM_READING_IN_PROGRESS;
                    op_ram_enable_read <= 1;
                    ram_x <= _X1;
                    ram_y <= _Y1;
                    wait_for_read <= 1;
                end else if (_start_ram_write) begin
                    state <= RAM_WRITING_IN_PROGRESS;
                    ram_x <= _X1;
                    ram_y <= _Y1;
                    op_write_ram_byte <= _write_ram_byte;
                    op_ram_write_value <= _write_ram_byte[0];
                    op_ram_enable_write <= 1;
                end
            end
            FILL_IN_PROGRESS: begin
                ram_x <= ram_x+1;
                if (ram_x+1 > opX1+op_x_width) begin
                    ram_x <= opX1;
                    ram_y <= ram_y+1;
                    if (ram_y+1 > opY1+op_y_height) begin
                        op_ram_enable_write <= 0;
                        state <= READY_STATE;
                    end
                end
            end
            BLIT_IN_PROGESS: begin
                if (op_ram_enable_read) begin
                    if (wait_for_read)
                        wait_for_read <= 0;
                    else begin
                        op_ram_enable_read <= 0;
                        // Has read bit from first square, now save it to second one
                        op_ram_enable_write <= 1;
                        op_ram_write_value <= _op_ram_value;
                        ram_x <= opX2+blit_x_offset;
                        ram_y <= opY2+blit_y_offset;
                    end
                end else begin
                    // Wrote last bit, now read next one
                    op_ram_enable_read <= 1;
                    wait_for_read <= 1;
                    op_ram_enable_write <= 0;

                    ram_y <= opY1+blit_y_offset;
                    blit_x_offset <= blit_x_offset+(leftToRight ? 1:-1);
                    ram_x <= opX1+blit_x_offset+(leftToRight ? 1:-1);
                    if (change_line) begin
                        blit_x_offset <= leftToRight ? 0:op_x_width-1;
                        ram_x <= opX1+leftToRight ? 0:op_x_width-1;

                        blit_y_offset <= blit_y_offset+(topToDown ? 1:-1);
                        ram_y <= opY1+blit_y_offset+(topToDown ? 1:-1);
                        if (finished_lines) begin
                            op_ram_enable_read <= 0;
                            state <= READY_STATE;
                        end
                    end
                end
            end
            RAM_READING_IN_PROGRESS: begin
                ram_x <= ram_x+1;
                // We wait one cycle for the reads to catch up.
                if (wait_for_read) begin
                    wait_for_read <= 0;
                end else begin
                    if (which_bit_of_ram+1 == 8)
                        op_ram_enable_read <= 0;

                    // Save previous bit
                    ram_byte[which_bit_of_ram-1] <= _op_ram_value;
                    // if saved all bits:
                    if (which_bit_of_ram == 8) begin
                        state <= READY_STATE;
                        ram_byte_ready <= 1;
                    end
                end
            end
            RAM_WRITING_IN_PROGRESS: begin
                ram_x <= ram_x + 1;
                op_ram_write_value <= op_write_ram_byte[which_bit_of_ram + 1];
                if (which_bit_of_ram + 1 == 8) begin
                    state <= READY_STATE;
                    op_ram_enable_write <= 0;
                end

            end
        endcase
    end




endmodule