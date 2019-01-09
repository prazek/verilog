`default_nettype none

module Synchronizer#(parameter BIT_NUM = 1, DEFAULT_VAL = 0)
(
    input [BIT_NUM-1:0]      in,
    input wire               clk,
    output reg [BIT_NUM-1:0] out
);
    reg [BIT_NUM-1:0] tmp1 = DEFAULT_VAL;
    reg [BIT_NUM-1:0] tmp2 = DEFAULT_VAL;
    always @(posedge clk) begin
        tmp1 <= in;
        tmp2 <= tmp1;
        out <= tmp2;
    end

endmodule

module ActionGenerator(
    input wire in,
    input wire clk,
    output reg out
);
    reg previous_state = 0;
    always @(posedge clk) begin
        out <= 0;
        if (in != previous_state) begin
            previous_state <= in;
            out <= in;
        end
    end
endmodule

module top(
    input        clk,
    input  [3:0] btn,
    input  [7:0] sw,
    output [7:0] led,
    output [3:0] an,
    output [6:0] seg,
    output       dp
);

    wire [3:0]  syn_btn;
    wire [7:0]  syn_sw;
    Synchronizer#(.BIT_NUM(4)) btn_syn(
        .in (btn),
        .clk(clk),
        .out(syn_btn)
    );
    Synchronizer#(.BIT_NUM(8)) sw_syn(
        .in (sw),
        .clk(clk),
        .out(syn_sw)
    );

    wire        show_upper;
    wire        push_num;
    wire        shift_and_push;
    wire        do_other_op;
    wire        do_reset;

    ActionGenerator push_num_action(
        .in (syn_btn[1]),
        .clk(clk),
        .out(push_num)
    );
    ActionGenerator shift_and_push_action(
        .in (syn_btn[2]),
        .clk(clk),
        .out(shift_and_push)
    );
    ActionGenerator do_other_op_action(
        .in (syn_btn[3]),
        .clk(clk),
        .out(do_other_op)
    );
    ActionGenerator rest_action(
        .in (syn_btn[0] & syn_btn[3]),
        .clk(clk),
        .out(do_reset)
    );
    assign show_upper = syn_btn[0] & !syn_btn[3];

    wire        empty_stack;
    wire [31:0] calc_top;
    reg [15:0]  output_num;

    Calculator calc(
        .clk           (clk),
        .push_num      (push_num),
        .shift_and_push(shift_and_push),
        .do_other_op   (do_other_op),
        .reset         (do_reset),
        .input_number  (syn_sw),
        .other_op_code (syn_sw[2:0]),
        .stack_size    (led[6:0]),
        .error_bit     (led[7]),
        .out_num       (calc_top),
        .empty_stack   (empty_stack)
    );


    Display display(
        .clk          (clk),
        .number       (output_num),
        .display_lines(empty_stack),
        .an           (an),
        .seg          (seg),
        .dp           (dp)
    );

    always @(posedge clk) begin
        if (show_upper)
            output_num <= calc_top >> 16;
        else
            output_num <= calc_top;
    end

endmodule