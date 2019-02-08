`default_nettype none

module EPP(
    input            clk,
    input            EppAstb,
    input            EppDstb,
    input            EppWR,
    output reg       EppWait,
    inout wire [7:0] EppDB,


    output reg       move_left = 0,
    output reg       move_right = 0,
    output reg       move_down = 0,
    output reg       drop = 0,
    output reg       rotate_left = 0,
    output reg       rotate_right = 0,
    output reg       restart = 0
);


    reg [7:0]  address;
    wire       epp_write_command = EppWR == 0;
    reg [7:0]  writeEppDB = 0;
    wire [7:0] data_in;

    assign EppDB = ~epp_write_command ? writeEppDB:8'bz;
    assign data_in = EppDB;

    always @(posedge clk) begin
        move_left <= 0;
        move_right <= 0;
        move_down <= 0;
        drop <= 0;
        rotate_left <= 0;
        rotate_right <= 0;
        EppWait <= 0;
        restart <= 0;

        if (EppAstb == 0) begin
            EppWait <= 1;
            if (epp_write_command) begin
                address <= data_in;
            end else
                writeEppDB <= address;
        end else if (EppDstb == 0) begin
            EppWait <= 1;
            if (address == 0) begin
                if (epp_write_command) begin
                    if (data_in[0])
                        move_right <= 1;
                    else if (data_in[2])
                        move_left <= 1;
                    else if (data_in[3])
                        move_down <= 1;
                    else if (data_in[4])
                        drop <= 1;
                    else if (data_in[5])
                        rotate_right <= 1;
                    else if (data_in[6])
                        rotate_left <= 1;
                    else if (data_in[7])
                        restart <= 1;
                end else
                    writeEppDB <= 0;
            end else begin // Invalid values
                EppWait <= 0;
            end
        end
    end


endmodule
