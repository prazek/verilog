`default_nettype none

module EPP(
    input            clk,
    input            EppAstb,
    input            EppDstb,
    input            EppWR,
    output reg       EppWait,
    inout wire [7:0] EppDB,

    output     [8:0] X1,
    output     [7:0] Y1,
    output     [8:0] X2,
    output     [7:0] Y2,
    output     [8:0] op_width,
    output     [7:0] op_height,
    output reg       start_blit,
    output reg       start_fill,
    output reg       fill_value,
    output reg [7:0] debug = 0,
    input            status
);
    reg [7:0]  address;
    reg [7:0]  registers [11:0];

    reg [7:0]  writeEppDB = 0;
    wire read_enable = EppWR == 0;
    wire [7:0] data_in;
    assign EppDB = read_enable ? writeEppDB : 8'bz;
    assign data_in = EppDB;


    assign X1 = {registers[1], registers[0]};
    assign Y1 = registers[2];
    assign X2 = {registers[5], registers[4]};
    assign Y2 = registers[6];
    assign op_width = {registers[9], registers[8]};
    assign op_height = registers[10];

    /*reg        do_op = 1;
    reg        do_blit = 1;
    reg [31:0] cnt = 0;*/

    always @(posedge clk) begin

        start_blit <= 0;
        start_fill <= 0;
        fill_value <= 0;
        //cnt <= cnt+1;
        /*if (do_op & cnt == 400) begin
            registers[0] <= 20;
            registers[2] <= 40;
            registers[4] <= 100;
            registers[6] <= 100;
            start_fill <= 1;
            fill_value <= 1;
        end
        if (do_op & cnt == 30000) begin
            registers[0] <= 0;
            registers[2] <= 0;
            {registers[5], registers[4]} <= 320;
            {registers[7], registers[6]} <= 200;
            start_fill <= 1;
            fill_value <= 1;
            do_op <= 0;
        end

        if (do_blit & cnt == 444000) begin
            registers[0] <= 0;
            registers[2] <= 0;
            registers[4] <= 40;
            registers[6] <= 40;
            registers[8] <= 100;
            registers[10] <= 100;
            start_blit <= 1;
            do_blit <= 0;
        end*/

        EppWait <= 0;
        if (EppAstb == 0) begin
            EppWait <= 1;
            if (EppWR == 0) begin
                debug <= debug | 1;
                address <= data_in;
            end else
                writeEppDB <= address;
        end
        else if (EppDstb == 0) begin
            EppWait <= 1;
            if (address <= 11) begin
                if (EppWR == 0) begin
                    debug <= debug | 2;
                    registers[address] <= data_in;
                end else
                    writeEppDB <= registers[address];
            end else begin
                if (address == 12) begin//&& EppWR == 0)
                    start_blit <= 1;
                    debug <= debug | 8;
                end
                else if (address == 13) begin//&& EppWR == 0) begin
                    debug <= debug | 4;
                    start_fill <= 1;
                    fill_value <= data_in[0:0];
                end else if (address == 14) begin
                    debug <= debug | (1 << 5);

                end else if (address == 15) begin
                    debug <= debug | 16;
                    writeEppDB <= status;
                end else if (address > 15) begin
                    debug <= debug | 16;
                end

            end

        end
    end

endmodule
