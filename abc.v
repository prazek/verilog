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
        if ((dividend >> BIT_NUM) >= divisor) begin
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



module divider
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
            divider_impl #(.BIT_NUM(i), .DIVISOR_BITS(BITS)) impl(dividends[i + 1],
                              divisor,
                              result[i],
                              dividends[i]);
        end
    endgenerate
    assign rest = dividends[0];


endmodule

module mini_calculator(
    input [3:0] a,
    input [3:0] b,
    input [3:0] btn,
    output reg[7:0] led
);

    wire[3:0] div_result;
    wire [3:0]div_rest;
    divider div(a, b, div_result, div_rest);

    always @(btn, a, b, div_result, div_rest) begin
        led = 0;
        if (btn[0]) begin
            led[7:4] = a + b;
            led[3:0] = a - b;
        end
        if (btn[1]) begin
            if (a > b) begin
                led[7:4] = b;
                led[3:0] = a;
            end
            else begin
                led[7:4] = a;
                led[3:0] = b;
            end
        end
        if (btn[2])
            led = a * b;
        if (btn[3]) begin
            led[7:4] = div_result;
            led[3:0] = div_rest;
        end
    end

endmodule

module zad(
    input [7:0] sw,
    input [3:0] btn,
    output [7:0] led
    );

    mini_calculator calculator(sw[7:4], sw[3:0], btn, led);

endmodule
