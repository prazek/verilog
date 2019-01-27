`default_nettype none

module EPP(
    input             clk,
    input             EppAstb,
    input             EppDstb,
    input             EppWR,
    input             EppWait,
    inout wire [7:0]  EppDB,


    output     [15:0] X1,
    output     [15:0] Y1,
    output     [15:0] X2,
    output     [15:0] Y2,
    output     [15:0] op_width,
    output     [15:0] op_height,
    output reg        start_blit,
    output reg        start_fill,
    output reg        fill_value

);
    reg [7:0]  address;
    reg [7:0]  registers [16:0];

    assign X1 = {registers[1], registers[0]};
    assign Y1 = {registers[3], registers[2]};
    assign X2 = {registers[5], registers[4]};
    assign Y2 = {registers[7], registers[6]};
    assign op_width = {registers[9], registers[8]};
    assign op_height = {registers[11], registers[10]};

    reg        do_op = 1;
    reg [10:0] cnt = 0;
    always @(posedge clk) begin

        start_blit <= 0;
        start_fill <= 0;
        fill_value <= 0;
        cnt <= cnt+1;
        if (do_op & cnt == 400) begin
            registers[0] <= 20;
            registers[2] <= 40;
            registers[4] <= 150;
            registers[6] <= 160;
            start_fill <= 1;
            fill_value <= 1;
            do_op <= 0;
        end


        if (EppAstb == 0)
            address <= EppDB;
        else if (EppDstb == 0) begin
            if (address <= 11)
                registers[address] <= EppDB;
            else begin
                if (address == 12)
                    start_blit <= 1;
                else if (address == 13) begin
                    start_fill <= 1;
                    fill_value <= EppDB[0:0];
                end
            end

        end
    end
    
endmodule
