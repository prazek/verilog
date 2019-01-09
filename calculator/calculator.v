`default_nettype none

module SynchronousDividerImpl
#(parameter BITS = 32)
(
    input [BITS-1:0]      dividend,
    input [BITS-1:0]      divisor,
    input [10:0]          bitidx,
    output reg            result_bit,
    output reg [BITS-1:0] rest
);
    wire [BITS*2-1:0] extended_divisor = divisor << bitidx;
    always @ (* ) begin
    if (dividend >= extended_divisor) begin
    result_bit = 1;
    rest = dividend-extended_divisor;
    end
    else begin
    result_bit = 0;
    rest = dividend;
    end
    end

endmodule

module UnsignedSynchronousDivider
#(parameter BITS = 32)
(
    input                 clk,
    input                 start,
    input [BITS-1:0]      dividend,
    input [BITS-1:0]      divisor,
    output reg [BITS-1:0] result,
    output reg [BITS-1:0] rest,
    output                finished
);
    reg             active = 0;
    reg [10:0]      bitidx = 0;
    wire            result_bit;
    wire [BITS-1:0] out;
    assign finished = !active;

    SynchronousDividerImpl#(.BITS(BITS)) impl(
        .dividend  (rest),
        .divisor   (divisor),
        .bitidx    (bitidx),
        .result_bit(result_bit),
        .rest      (out)
    );

    always @(posedge clk) begin
        if (!active) begin
            if (start) begin
                result <= 0;
                rest <= dividend;
                active <= 1;
                bitidx <= BITS-1;
            end
        end else begin
            rest <= out;
            result[bitidx] <= result_bit;
            if (bitidx == 0)
                active <= 0;
            bitidx <= bitidx-1;
        end
    end

endmodule

module SynchronousDivider#(parameter BITS = 32)
(
    input             clk,
    input             start,
    input  [BITS-1:0] dividend,
    input  [BITS-1:0] divisor,
    output [BITS-1:0] result,
    output [BITS-1:0] rest,
    output            finished
);

    wire            is_dividend_positive = dividend[BITS-1];
    wire            is_divisor_positive = divisor[BITS-1];
    wire [BITS-1:0] positive_dividend = is_dividend_positive ?
        ~dividend+1:dividend;
    wire [BITS-1:0] positive_divisor = is_divisor_positive ?
        ~divisor+1:divisor;


    wire [BITS-1:0] positive_result;
    wire [BITS-1:0] positive_rest;
    wire            should_negate_results = is_dividend_positive ^ is_divisor_positive;

    wire            is_dividend_min_int = dividend == ~dividend+1;
    wire            is_divisor_minus_one = divisor == ~0;

        // return 0 for MIN_INT / -1 as -MIN_INT is not representable in U2
    assign result = is_dividend_min_int & is_divisor_minus_one ? 0:(should_negate_results ?
        ~positive_result+1:positive_result);
    assign rest = should_negate_results ?
        ~positive_rest+1:positive_rest;

    UnsignedSynchronousDivider#(.BITS(BITS)) divider(
        .clk     (clk),
        .start   (start),
        .dividend(positive_dividend),
        .divisor (positive_divisor),
        .result  (positive_result),
        .rest    (positive_rest),
        .finished(finished)
    );

endmodule


module Executor(
    input                   clk,
    input                   start,
    input [31:0]            top,
    input [31:0]            second,
    input [7:0]             input_number,
    input                   no_top,
    input                   no_second,
    input [4:0]             op_code,
    output reg              error,
    output reg signed [1:0] stack_diff,
    output reg [31:0]       out_top,
    output reg [31:0]       out_second,
    output reg              second_exist,
    output                  finished
);

    reg         active = 0;
    assign finished = !active;
    wire [31:0] div_result;
    wire [31:0] div_rest;
    wire        divider_finished;
    SynchronousDivider#(.BITS(32)) divider(
        .clk     (clk),
        .start   (start),
        .dividend(top),
        .divisor (second),
        .result  (div_result),
        .rest    (div_rest),
        .finished(divider_finished)
    );

    always @(posedge clk) begin
        if (!active) begin
            if (start) begin
                active <= 1;
                out_top <= 0;
                out_second <= 0;
                error <= 0;
                stack_diff <= 0;
                second_exist <= 0;
            end
        end else begin
            active <= 0;
            case (op_code)
                5'b00000: begin // +
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        out_top <= top+second;
                        stack_diff <= -1;
                    end
                end
                5'b00001: begin // -
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        out_top <= top-second;
                        stack_diff <= -1;
                    end
                end
                5'b00010: begin // *
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        out_top <= top*second;
                        stack_diff <= -1;
                    end
                end
                5'b00011: begin // /
                    if (no_top | no_second | second == 0) begin
                        error <= 1;
                    end else begin
                        if (divider_finished) begin
                            active <= 0;
                            out_top <= div_result;
                            stack_diff <= -1;
                        end else
                            active <= 1;
                    end
                end
                5'b00100: begin // %
                    if (no_top | no_second | second == 0) begin
                        error <= 1;
                    end else begin
                        if (divider_finished) begin
                            active <= 0;
                            out_top <= div_rest;
                            stack_diff <= -1;
                        end else
                            active <= 1;
                    end
                end
                5'b00101: begin // pop
                    if (no_top) begin
                        error <= 1;
                    end else begin
                        out_top <= second;
                        stack_diff <= -1;
                    end
                end
                5'b00110: begin // copy top
                    if (no_top) begin
                        error <= 1;
                    end else begin
                        second_exist <= 1;
                        out_top <= top;
                        out_second <= top;
                        stack_diff <= 1;
                    end
                end
                5'b00111: begin // swap
                    if (no_top | no_second) begin
                        error <= 1;
                    end else begin
                        second_exist <= 1;
                        out_top <= second;
                        out_second <= top;
                        stack_diff <= 0;
                    end
                end
                5'b01000: begin // push num
                    out_top <= input_number;
                    stack_diff <= 1;
                end
                5'b10000: begin // shift and push
                    if (no_top)
                        error <= 1;
                    else begin
                        out_top <= top << 8 | input_number;
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

    parameter STACK_MAX_SIZE = 5;
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
    reg                start_executor = 0;
    reg                will_write_second = 0;
    wire signed [2:0]  stack_diff;
    wire        [31:0] out_top;
    wire        [31:0] out_second;
    wire               out_error_bit;
    wire               second_exists;
    wire               executor_finished;
    Executor executor(
        .clk         (clk),
        .start       (start_executor),
        .top         (top),
        .second      (second),
        .input_number(input_number),
        .no_top      (no_top),
        .no_second   (no_second),
        .op_code     (op_code),
        .error       (out_error_bit),
        .stack_diff  (stack_diff),
        .out_top     (out_top),
        .out_second  (out_second),
        .second_exist(second_exists),
        .finished    (executor_finished)
    );

    always @(posedge clk) begin
        if (reset) begin
            stack_size <= 0;
            op_code <= 0;
            active <= 0;
            stage <= 0;
            start_executor <= 0;
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
                op_code[2:0] <= push_num | shift_and_push ? 0:other_op_code;
                op_code[3] <= push_num;
                op_code[4] <= shift_and_push;
                stage <= 0;
            end
        end
        else begin
            case (stage)
                6'b000000: begin // initiate read data
                    top_address <= stack_size-1;
                    if (stack_size > 0) begin
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
                    start_executor <= 1;
                    stage <= stage << 1;
                end
                6'b000100: begin // execute
                    stage <= stage << 1;
                    start_executor <= 0;
                end
                6'b001000: begin // get out from executor
                    if (executor_finished) begin
                        top <= out_top;
                        if (second_exists) begin
                            second <= out_second;
                            will_write_second <= 1;
                        end
                        error_bit <= out_error_bit;
                        if (stack_size+stack_diff > STACK_MAX_SIZE)
                            error_bit <= 1;
                        else
                            stack_size <= stack_size+stack_diff;
                        stage <= stage << 1;
                    end
                end
                6'b010000: begin // initialize write
                    if (!error_bit) begin
                        top_address <= stack_size-1;
                        enable_write_top <= 1;
                        if (will_write_second) begin
                            enable_write_second <= 1;
                        end
                        out_num <= top;
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