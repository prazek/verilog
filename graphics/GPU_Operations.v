`default_nettype none

module GPU_Operations(
    input            clk,
    input [8:0]      X1,
    input [7:0]      Y1,
    input [8:0]      X2,
    input [7:0]      Y2,
    input            start_fill,
    input            fill_value,
    input            start_blt,


    output reg [8:0] op_x,
    output reg [7:0] op_y,
    output reg       op_ram_enable_write,
    output reg       op_ram_write_value
);

    initial op_ram_enable_write = 0;
    initial op_ram_write_value = 0;

    localparam READY_STATE = 0;
    localparam INITIATE_FILL_STATE = 1;
    localparam FILL_IN_PROGRESS = 2;

    reg [4:0] state = READY_STATE;
    reg       op_fill_value = 0;
    reg [8:0] opX1;
    reg [7:0] opY1;
    reg [8:0] opX2;
    reg [7:0] opY2;

    always @(posedge clk) begin
        case (state)
            READY_STATE: begin
                op_ram_write_value <= 0;
                op_ram_enable_write <= 0;
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
                    op_x <= opX1;
                    op_y <= opY1;
                    op_ram_write_value <= op_fill_value;
                    op_ram_enable_write <= 1;
                end else // invalid fill values
                    state <= READY_STATE;
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

        endcase
    end




endmodule