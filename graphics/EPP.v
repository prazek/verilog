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
    output reg       start_read_ram,
    output reg       start_write_ram,
    output reg [7:0] write_ram_byte,

    output reg [7:0] debug = 128,

    input            status,
    input            ram_byte_ready,
    input      [7:0] ram_byte
);

    localparam BLIT_REGISTER = 12;
    localparam FILL_REGISTER = 13;
    localparam DMA_REGISTER = 14;
    localparam STATUS_REGISTER = 15;

    reg [7:0]  address;
    reg [7:0]  registers [11:0];
    wire       epp_write_command = EppWR == 0;
    reg [7:0]  writeEppDB = 0;
    wire [7:0] data_in;

    assign EppDB = ~epp_write_command ? writeEppDB:8'bz;
    assign data_in = EppDB;


    assign X1 = {registers[1], registers[0]};
    assign Y1 = registers[2];
    assign X2 = {registers[5], registers[4]};
    assign Y2 = registers[6];
    assign op_width = {registers[9], registers[8]};
    assign op_height = registers[10];


    reg        is_waiting_for_ram = 0;
    always @(posedge clk) begin
        start_blit <= 0;
        start_fill <= 0;
        fill_value <= 0;
        start_read_ram <= 0;
        start_write_ram <= 0;

        if (is_waiting_for_ram) begin
            if (ram_byte_ready) begin
                is_waiting_for_ram <= 0;
                writeEppDB <= ram_byte;
            end
        end else begin
            EppWait <= 0;
            is_waiting_for_ram <= 0;
        end


        if (EppAstb == 0) begin
            EppWait <= 1;
            if (epp_write_command) begin
                address <= data_in;
            end else
                writeEppDB <= address;
        end
        else if (EppDstb == 0) begin
            EppWait <= 1;
            if (address <= 11) begin
                if (epp_write_command) begin
                    registers[address] <= data_in;
                end else
                    writeEppDB <= registers[address];
            end else if (address == BLIT_REGISTER && epp_write_command) begin
                start_blit <= 1;
            end else if (address == FILL_REGISTER && epp_write_command) begin
                start_fill <= 1;
                fill_value <= data_in[0:0];
            end else if (address == DMA_REGISTER) begin
                // Only start when GPU not busy
                if (status == 0) begin
                    if (epp_write_command) begin
                        start_write_ram <= 1;
                        write_ram_byte <= data_in;
                    end else begin
                        start_read_ram <= 1;
                        is_waiting_for_ram <= 1;
                    end
                end
            end else if (address == STATUS_REGISTER && !epp_write_command) begin
                writeEppDB <= status;
            end else begin // Invalid values
                EppWait <= 0;
                debug <= debug | 16;
            end
        end
    end


endmodule
