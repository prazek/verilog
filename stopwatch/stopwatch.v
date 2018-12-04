`default_nettype none


module Divider_impl # (parameter BIT_NUM = 4, parameter DIVISOR_BITS = 4)
(
    input[DIVISOR_BITS:0] dividend,
    input[DIVISOR_BITS:0] divisor,
    output reg result_bit,
    output reg[DIVISOR_BITS:0] rest
);
    always @(dividend or divisor) begin
        if ((dividend >> BIT_NUM) >= divisor) begin
            result_bit = 1;
            rest = dividend - (divisor << BIT_NUM);
        end
        else begin
            result_bit = 0;
            rest = dividend;
        end
    end

endmodule



module Divider
#(    parameter BITS = 4 )
(

    input[BITS-1:0] dividend,
    input[BITS-1:0] divisor,
    output [BITS-1:0] result,
    output [BITS-1:0] rest
);

    wire [BITS-1:0] dividends[BITS:0];
    assign dividends[BITS] = dividend;
    genvar i;
    generate
        for (i = BITS-1; i >= 0; i = i - 1) begin : gen_divisors
            Divider_impl #(.BIT_NUM(i), .DIVISOR_BITS(BITS)) impl(dividends[i + 1],
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
    output reg[32:0] value = 0
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
    wire [32:0]value;
    reg reset = 0;
    reg [2:0]phase = 3'b001;
    reg [2:0] which_seg = 0;
    reg [3:0]current_digit = 0;
    reg [14:0] current_number = 0;
    reg [14:0] rest_number = 0;
    assign dp = 1;

    Counter counter(.clk(clk), .reset(reset), .value(value));
    Segment segment(.digit(current_digit), .seg(seg));

    wire [14:0] rest_number_wire;
    wire [3:0] current_digit_wire;
    Divider #(.BITS(14)) divider(
        .dividend(current_number),
        .divisor(10),
        .result(rest_number_wire),
        .rest(current_digit_wire));

    always @(posedge clk) begin
        current_digit = current_digit_wire;
        rest_number = rest_number_wire;
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

module Clock(
    input clk,
    input [4:0]frequency,
    input reset,
    input signed[2:0] diff,
    output reg [14:0] out = 0,
    output reg overflow = 0
);
    wire [32:0] value;
    reg reset_counter = 1;
    Counter counter(.clk(clk), .reset(reset_counter), .value(value));

    always @(posedge clk) begin
        if (reset) begin
            reset_counter <= 1;
            out <= 0;
            overflow <= 0;
        end
        if ((value >> frequency) > 0) begin
            reset_counter <= 1;
            if (out + diff > 9999) begin
                out <= 9999;
                overflow <= 1;
            end
            else if (out + diff < 0) begin
                out <= 0;
                overflow <= 1;
            end
            else begin
                out <= out + diff;
                overflow <= 0;
            end
        end
        else begin
            reset_counter <= 0;
        end
    end
endmodule


module Stopwatch(
    input wire clk,
    input wire reset,
    input wire stop,
    input wire start_up,
    input wire start_down,
    input wire [4:0] frequency,
    output wire [3:0] an,
    output wire [6:0] seg,
    output wire dp,
    output reg led_counting_down,
    output reg led_counting_up,
    output reg led_counting_overflow
);

    wire [14:0]current_number;
    reg signed [2:0] diff = 0;
    wire overflow;
    Clock clock(
        .clk(clk),
        .frequency(frequency),
        .reset(reset),
        .diff(diff),
        .out(current_number),
        .overflow(overflow)
    );
    reg [14:0]current_number_reg;
    Display display(.clk(clk),
                    .number(current_number_reg),
                    .an(an),
                    .seg(seg),
                    .dp(dp));
    always @(posedge clk) begin
        current_number_reg <= current_number;
        led_counting_overflow <= overflow;
        if (stop | reset) begin
            diff <= 0;
        end
        if (stop | reset | overflow) begin
            led_counting_up <= 0;
            led_counting_down <= 0;
        end
        if (start_up) begin
            diff <= 1;
            led_counting_up <= 1;
            led_counting_down <= 0;
        end
        else if (start_down) begin
            diff <= -1;
            led_counting_up <= 0;
            led_counting_down <= 1;
        end

    end


endmodule

module Synchronizer #(parameter BIT_NUM = 1)
(
    input[BIT_NUM-1:0] in,
    input wire clk,
    output reg[BIT_NUM-1:0] out
);
    reg tmp1, tmp2;
    always @(posedge clk) begin
        tmp1 <= in;
        tmp2 <= tmp1;
        out <= tmp2;
    end

endmodule


module zad(
    input [7:0] sw,
    input [3:0] btn,
    input mclk,
    input uclk,
    output [3:0] an,
    output [6:0] seg,
    output dp,
    output [2:0] led
    );

    wire clk;
    reg change_clock = 0, tmp1, tmp2;
    always @(posedge clk) begin
        tmp1 <= sw[7];
        tmp2 <= tmp1;
        change_clock <= tmp2;
    end
    BUFGMUX choose_clock(.I0(mclk), .I1(uclk), .S(change_clock), .O(clk));

    wire reset;
    wire stop;
    wire start_up;
    wire start_down;
    wire [4:0]frequency;
    Synchronizer reset_synch(btn[3], clk, reset);
    Synchronizer stop_synch(btn[2], clk, stop);
    Synchronizer up_synch(btn[1], clk, start_up);
    Synchronizer down_synch(btn[0], clk, start_down);
    Synchronizer  #(.BIT_NUM(5)) freq_synch(sw[4:0], clk, frequency);


    Stopwatch s(
        .clk(clk),
        .reset(reset),
        .stop(stop),
        .start_up(start_up),
        .start_down(start_down),
        .frequency(sw[4:0]),
        .an(an),
        .seg(seg),
        .dp(dp),
        .led_counting_down(led[0]),
        .led_counting_up(led[1]),
        .led_counting_overflow(led[2])
    );


endmodule
