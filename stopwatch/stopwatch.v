`default_nettype none


module divider_impl # (parameter BIT_NUM = 4, parameter DIVISOR_BITS = 4)
(
    input[DIVISOR_BITS:0] dividend,
    input[DIVISOR_BITS:0] divisor,
    output result_bit_,
    output reg[DIVISOR_BITS:0] rest
);
    reg result_bit;
    always @(dividend or divisor) begin
        if (dividend >= (divisor << BIT_NUM)) begin
            result_bit = 1;
            rest = dividend - (divisor << BIT_NUM);
        end
        else begin
            result_bit = 0;
            rest = dividend;
        end
    end

    assign result_bit_ = result_bit;

endmodule



module Divider
    #(    parameter BITS = 4 )
(

    input[BITS-1:0] dividend,
    input[BITS-1:0] divisor,
    output[BITS-1:0] result,
    output[BITS-1:0] rest
);

    wire [BITS-1:0] dividends[BITS:0];
    assign dividends[BITS] = dividend;
    genvar i;
    generate
        for (i = BITS-1; i >= 0; i = i - 1) begin : gen_divisors
            divider_impl #(.BIT_NUM(i)) impl(dividends[i + 1],
                              divisor,
                              result[i],
                              dividends[i]);
        end
    endgenerate
    assign rest = dividends[0];
    
endmodule

module Counter(
    input wire clk,
    input wire reset,
    output reg[31:0] value
);
    always @(posedge clk, posedge reset) begin
        if (reset)
            value <= 0;
        else
            value <= value + 1;
    end

endmodule

module Segment(
    input [3:0]digit,
    output reg [6:0] seg
);
    always @(digit) begin
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
            default: seg = 7'h3f;
        endcase
    end
endmodule

module Display(
    input wire clk,
    input wire [14:0]number,
    output reg [3:0] an,
    output wire [6:0] seg,
    output wire dp
);
    wire [16:0]value;
    reg reset = 0;
    reg [2:0]phase = 3'b001;
    reg [2:0] which_seg = 2;
    reg [3:0]current_digit = 0;
    reg [14:0] current_number = 0;
    reg [14:0] rest_number = 0;

    Counter counter(.clk(clk), .reset(reset), .value(value));
    Segment segment(.digit(current_digit), .seg(seg));
    Divider #(.BITS(14)) divider(
        .dividend(current_number),
        .divisor(10),
        .result(rest_number),
        .rest(current_digit));

    always @(posedge clk) begin
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
                        which_seg <= which_seg + 1;
                        current_number <= rest_number;
                    end
                end
            end
        endcase
    end


endmodule

module Stopwatch(
    input wire clk,
    input wire reset,
    input wire stop,
    input wire start_up,
    input wire start_down,
    input wire choose_clock,
    input wire [3:0] frequency,
    output wire [3:0] an,
    output wire [6:0] seg,
    output wire dp,
    output reg led_counting_down,
    output reg led_counting_up,
    output reg led_counting_overflow
);

    //wire[3:0] div_result;
    //wire [3:0]div_rest;
    //divider div(a, b, div_result, div_rest);
    Display display(.clk(clk),
                    .number(123),
                    .an(an),
                    .seg(seg),
                    .dp(dp));
    always @(reset, stop, start_up, start_down, choose_clock, frequency) begin
        led_counting_up = 1;
        led_counting_down = 1;
        led_counting_overflow = 1;
    end

    //assign an = 4'b1110;
    //assign dp = 1;
endmodule

module zad(
    input [7:0] sw,
    input [3:0] btn,
    input mclk,
    output [3:0] an,
    output [6:0] seg,
    output dp,
    output [2:0] led
    );

    Stopwatch s(
        .clk(mclk),
        .reset(btn[3]),
        .stop(btn[2]),
        .start_up(btn[1]),
        .start_down(btn[0]),
        .choose_clock(sw[7]),
        .frequency(sw[3:0]),
        .an(an),
        .seg(seg),
        .dp(dp),
        .led_counting_down(led[0]),
        .led_counting_up(led[1]),
        .led_counting_overflow(led[2])
    );

endmodule
