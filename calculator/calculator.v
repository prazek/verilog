`default_nettype none

module Executor(
    input                   clk,
    input                   active,
    input [31:0]            top,
    input [31:0]            second,
    input                   no_top,
    input                   no_second,
    input [2:0]             op_code,
    output reg              error,
    output reg signed [1:0] stack_diff,
    output reg [31:0]       out_top,
    output reg [31:0]       out_second,
    output reg              second_exist
);

    always @(posedge clk) begin
        if (active) begin
            out_top <= 0;
            out_second <= 0;
            error <= 0;
            stack_diff <= 0;
            second_exist <= 0;
            case (op_code)
                3'b000: begin
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        out_top <= top+second;
                        stack_diff <= -1;
                    end
                end
                3'b001: begin
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        out_top <= top-second;
                        stack_diff <= -1;
                    end
                end
                3'b010: begin
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        out_top <= top*second;
                        stack_diff <= -1;
                    end
                end
                //TODO rest ops
                3'b101: begin // pop
                    if (no_top) begin
                        error <= 1;
                    end else begin
                        out_top <= second;
                        stack_diff <= -1;
                    end
                end
                3'b110: begin // copy top
                    if (no_top) begin
                        error <= 1;
                    end else begin
                        second_exist <= 1;
                        out_top <= top;
                        out_second <= top;
                        stack_diff <= 1;
                    end
                end
                3'b111: begin // swap
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        second_exist <= 1;
                        out_top <= second;
                        out_second <= top;
                        stack_diff <= 0;
                    end
                end
                default: begin
                    error <= 1;
                end
            endcase
        end
    end


endmodule


module Calculator(
    input             clk,
    input             push_num,
    input             shift_and_push,
    input             do_other_op,
    input             reset,
    input [7:0]       input_number,
    input [2:0]       other_op_code,
    output reg [9:0]  stack_size,
    output reg        error_bit,
    output reg [31:0] out_num,
    output            empty_stack
);

    initial stack_size = 0;

    reg [31:0]         top;
    reg [31:0]         second;
    reg                read_top = 0;
    reg                read_second = 0;
    reg                enable_write_top = 0;
    reg                enable_write_second = 0;
    reg [8:0]          top_address;
    wire        [31:0] top_load;
    wire        [31:0] second_load;


    RAMB16_S36_S36 stack(
        .DOA  (top_load), // 32-bit Data Output
        .DOB  (second_load),
        //.DOP (DOP), // 4-bit parity Output
        .ADDRA(top_address), // 9-bit Address Input
        .ADDRB(top_address-1),
        .CLKA (clk), // Clock
        .CLKB (clk),
        .DIA  (top), // 32-bit Data Input
        .DIB  (second),
        .DIPA (0), // 4-bit parity Input
        .DIPB (0),
        .ENA  (read_top | enable_write_top), // RAM Enable Input
        .ENB  (read_second | enable_write_second),
        //.SSRA (SSR), // Synchronous Set/Reset Input
        //.SSRB (SSR),
        .WEA  (enable_write_top), // Write Enable Input
        .WEB  (enable_write_second)
    );


    assign empty_stack = stack_size == 0;
    reg                active = 0;
    reg [4:0]          op_code;
    reg [5:0]          stage = 0;
    reg                no_top = 0;
    reg                no_second = 0;
    reg                executor_active = 0;
    reg                will_write_second = 0;
    wire signed [2:0]  stack_diff;
    wire        [31:0] out_top;
    wire        [31:0] out_second;
    wire               out_error_bit;
    wire               second_exists;

    Executor executor(
        .clk         (clk),
        .active      (executor_active),
        .top         (top),
        .second      (second),
        .no_top      (no_top),
        .no_second   (no_second),
        .op_code     (op_code[3:0]),
        .error       (out_error_bit),
        .stack_diff  (stack_diff),
        .out_top     (out_top),
        .out_second  (out_second),
        .second_exist(second_exists)
    );

    always @(posedge clk) begin
        if (reset) begin
            stack_size <= 0;
            op_code <= 0;
            active <= 0;
            stage <= 0;
            executor_active <= 0;
            error_bit <= 0;
            enable_write_top <= 0;
            enable_write_second <= 0;
            will_write_second <= 0;
        end
        else if (!active) begin
            if (push_num | shift_and_push | do_other_op) begin
                active <= 1;
                error_bit <= 0;
                will_write_second <= 0;
                if (push_num | shift_and_push) begin
                    op_code[2:0] <= 0;
                    op_code[3] <= push_num;
                    op_code[4] <= shift_and_push;
                end else begin
                    op_code[2:0] <= other_op_code;
                    op_code[4:3] <= 0;
                end
                stage <= 0;
            end
        end
        else begin
            case (stage)
                6'b000000: begin // initiate read data
                    top_address <= stack_size-1;
                    if (stack_size > 0) begin // TODO check for stack overflow
                        read_top <= 1;
                        no_top <= 0;
                    end else begin
                        no_top <= 1;
                    end

                    if (stack_size > 1) begin
                        read_second <= 1;
                        no_second <= 0;
                    end else begin
                        no_second <= 1;
                    end
                    stage <= 6'b000001;
                end
                6'b000001: begin // read data
                    read_top <= 0;
                    read_second <= 0;
                    stage <= stage << 1;
                end
                6'b000010: begin // copy output, start executor
                    top <= top_load;
                    second <= second_load;
                    executor_active <= !(| op_code[4:3]);
                    stage <= stage << 1;
                end
                6'b000100: begin // execute
                    stage <= stage << 1;
                    executor_active <= 0;
                end
                6'b001000: begin
                    case (op_code)
                        default: begin // get out from executor
                            top <= out_top;
                            if (second_exists) begin
                                second <= out_second;
                                will_write_second <= 1;
                            end
                            error_bit <= out_error_bit;
                            if (stack_size + stack_diff > 512)
                                error_bit <= 1;
                            else
                                stack_size <= stack_size+stack_diff;
                        end
                        5'b01000: begin // push_num
                            top <= input_number;
                            if (stack_size + 1 > 512)
                                error_bit <= 1;
                            else
                                stack_size <= stack_size+1;
                        end
                        5'b10000: begin // shift and push
                            if (no_top)
                                error_bit <= 1;
                            else begin
                                top <= top << 16 | input_number;
                            end
                        end
                    endcase
                    stage <= stage << 1;
                end
                6'b010000: begin // initialize write
                    if (!error_bit) begin
                        top_address <= stack_size-1;
                        enable_write_top <= 1;
                        if (will_write_second) begin
                            enable_write_second <= 1;
                        end
                        out_num <= top; // TODO
                    end
                    stage <= stage << 1;
                end
                6'b100000: begin // do write
                    active <= 0;
                    enable_write_top <= 0;
                    enable_write_second <= 0;
                    stage <= 0;
                end
            endcase

        end

    end

endmodule