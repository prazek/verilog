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
    input [8:0]      _blit_x_width,
    input [7:0]      _blit_y_height,
    input            _op_ram_value,

    output reg [8:0] op_x,
    output reg [7:0] op_y,
    output reg       op_ram_enable_read,
    output reg       op_ram_enable_write,
    output reg       op_ram_write_value,
    output reg       error
);

    initial op_ram_enable_write = 0;
    initial op_ram_write_value = 0;
    initial op_ram_enable_read = 0;

    localparam READY_STATE = 0;
    localparam FILL_IN_PROGRESS = 1;
    localparam BLIT_IN_PROGESS = 2;

    reg [4:0] state = READY_STATE;

        // Copy of input values.
    reg [8:0] opX1;
    reg [7:0] opY1;
    reg [8:0] opX2;
    reg [7:0] opY2;
    reg [8:0] op_blit_x_width;
    reg [7:0] op_blit_y_height;

    reg [8:0] blit_x_offset;
    reg [7:0] blit_y_offset;

    always @(posedge clk) begin
        case (state)
            READY_STATE: begin
                op_ram_write_value <= 0;
                op_ram_enable_write <= 0;
                op_ram_enable_read <= 0;
                // Copy values so that they won't change while executing
                opX1 <= _X1;
                opX2 <= _X2;
                opY1 <= _Y1;
                opY2 <= _Y2;
                op_blit_x_width <= _blit_x_width;
                op_blit_y_height <= _blit_y_height;

                if (_start_fill | _start_blit) begin
                    error <= 0;
                    if (!(_X1 <= _X2 && _Y1 <= _Y2) || _X1 > WIDTH || _X2 > WIDTH || _Y1 > HEIGHT || _Y2 > HEIGHT) begin
                        error <= 1;
                    end else if (_start_fill) begin
                        state <= FILL_IN_PROGRESS;
                        op_x <= _X1;
                        op_y <= _Y1;
                        op_ram_write_value <= _fill_value;
                        op_ram_enable_write <= 1;
                    end else if (_start_blit) begin
                        state <= BLIT_IN_PROGESS;
                        op_x <= _X1;
                        op_y <= _Y1;
                        blit_x_offset <= 0;
                        blit_y_offset <= 0;
                        op_ram_enable_read <= 1;
                    end
                end
            end
            FILL_IN_PROGRESS: begin
                op_x <= op_x+1;
                if (op_x+1 > opX2) begin
                    op_x <= opX1;
                    op_y <= op_y+1;
                    if (op_y+1 > opY2) begin
                        op_ram_enable_write <= 0;
                        state <= READY_STATE;
                    end
                end
            end
            BLIT_IN_PROGESS: begin
                if (op_ram_enable_read) begin
                    // Has read bit from first square, now save it to second one
                    op_ram_enable_read <= 0;
                    op_ram_enable_write <= 1;
                    op_ram_write_value <= 1; //_op_ram_value;
                    op_x <= opX2 + blit_x_offset;
                    op_y <= opY2 + blit_y_offset;
                end else begin
                    // Wrote last bit, now read next one
                    op_ram_enable_read <= 1;
                    op_ram_enable_write <= 0;

                    blit_x_offset <= blit_x_offset + 1;
                    op_x <= opX1 + blit_x_offset + 1;
                    op_y <= opY1 + blit_y_offset;
                    if (blit_x_offset + 1 > op_blit_x_width) begin
                        blit_x_offset <= 0;
                        op_x <= opX1 + 0;

                        blit_y_offset <= blit_y_offset + 1;
                        op_y <= opY1 + blit_y_offset + 1;
                        if (blit_y_offset + 1 > op_blit_y_height) begin
                            op_ram_enable_read <= 0;
                            state <= READY_STATE;
                        end
                    end
                end

            end

        endcase
    end




endmodule