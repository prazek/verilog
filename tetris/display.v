`default_nettype none

module Divider_impl#(parameter BIT_NUM = 4, parameter DIVISOR_BITS = 4)
(
    input [DIVISOR_BITS:0]      dividend,
    input [DIVISOR_BITS:0]      divisor,
    output reg                  result_bit,
    output reg [DIVISOR_BITS:0] rest
);
    always @(dividend or divisor) begin
        if ((dividend >> BIT_NUM) >= divisor) begin
            result_bit = 1;
            rest = dividend-(divisor << BIT_NUM);
        end
        else begin
            result_bit = 0;
            rest = dividend;
        end
    end

endmodule


module Divider
#(parameter BITS = 4)
(

    input  [BITS-1:0] dividend,
    input  [BITS-1:0] divisor,
    output [BITS-1:0] result,
    output [BITS-1:0] rest
);

    wire [BITS-1:0] dividends[BITS:0];
    assign dividends[BITS] = dividend;
    genvar i;
    generate
        for (i = BITS-1; i >= 0; i = i-1) begin : gen_divisors
            Divider_impl#(.BIT_NUM(i), .DIVISOR_BITS(BITS)) impl(
                .dividend  (dividends[i+1]),
                .divisor   (divisor),
                .result_bit(result[i]),
                .rest      (dividends[i])
            );
        end
    endgenerate
    assign rest = dividends[0];

endmodule


module Counter(
    input wire        clk,
    input wire        reset,
    output reg [15:0] value = 0
);
    always @(posedge clk, posedge reset) begin
        if (reset)
            value <= 0;
        else
            value <= value+1;
    end

endmodule

module Segment(
    input [3:0]      digit,
    input wire       display_lines,
    output reg [6:0] seg
);
    always @(digit, display_lines) begin
        case (digit)
            0: seg = 7'h40;
            1: seg = 7'h79;
            2: seg = 7'h24;
            3: seg = 7'h30;
            4: seg = 7'h19;
            5: seg = 7'h12;
            6: seg = 7'h02;
            7: seg = 7'h78;
            8: seg = 7'h00;
            9: seg = 7'h10;
            10: seg = 7'h08;
            11: seg = 7'h03;
            12: seg = 7'h27;
            13: seg = 7'h21;
            14: seg = 7'h06;
            15: seg = 7'h0e;
            default: seg = 7'h3f;
        endcase
        if (display_lines) begin
            seg = 7'h3f;
        end
    end
endmodule

module Display(
    input wire         clk,
    input wire  [15:0] number,
    input wire         display_lines,
    output reg [3:0]   an,
    output wire [6:0]  seg,
    output wire        dp
);
    wire [15:0] value;
    reg         reset = 0;
    reg [2:0]   phase = 3'b001;
    reg [1:0]   which_seg = 0;
    reg [3:0]   current_digit = 0;
    reg [15:0]  current_number = 0;
    reg [15:0]  rest_number = 0;
    assign dp = 1;

    Counter counter(
        .clk  (clk),
        .reset(reset),
        .value(value)
    );
    Segment segment(
        .digit        (current_digit),
        .display_lines(display_lines),
        .seg          (seg)
    );

    wire [15:0] rest_number_wire;
    wire [3:0]  current_digit_wire;
    Divider#(.BITS(16)) divider(
        .dividend(current_number),
        .divisor (16),
        .result  (rest_number_wire),
        .rest    (current_digit_wire)
    );

    always @(posedge clk) begin
        current_digit = current_digit_wire;
        rest_number <= rest_number_wire;
        case (phase)
            default: begin
                phase <= 3'b001;
                reset <= 1;
                which_seg <= 0;
                an <= 4'b1111;
            end
            3'b001: begin
                an <= 4'b1111;
                reset <= 0;
                if (value > 1024) begin
                    reset <= 1;
                    phase <= 3'b010;
                end
            end
            3'b010: begin
                reset <= 0;
                an <= ~(1 << which_seg);
                if (value > 14336) begin
                    reset <= 1;
                    phase <= 3'b100;
                end
            end
            3'b100: begin
                reset <= 0;
                an <= 4'b1111;
                if (value > 1024) begin
                    reset <= 1;
                    phase <= 3'b001;
                    if (which_seg == 3) begin
                        which_seg <= 0;
                        current_number <= number;
                    end
                    else begin
                        which_seg <= which_seg+1;
                        current_number <= rest_number;
                    end
                end
            end
        endcase
    end
endmodule