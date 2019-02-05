`default_nettype none

module GPU_RAM#(parameter WIDTH = 320,
                parameter HEIGHT = 200)
(
    input       clk,
    input [8:0] x1,
    input [7:0] y1,
    input       enable_read1,
    output      read_value1,

    input clk2,
    input [8:0] x2,
    input [7:0] y2,
    input       enable_read2,
    output      read_value2,
    input       enable_write2,
    input       write_value
);

    wire        ram_out_t1[3:0];
    wire [15:0] pixel_num1 = (y1*WIDTH+x1);
    wire [13:0] ram_addr1 = pixel_num1[13:0];
    reg [1:0]   which_block1;
    assign read_value1 = ram_out_t1[which_block1];

    wire        ram_out_t2[3:0];
    wire [15:0] pixel_num2 = (y2*WIDTH+x2);
    wire [13:0] ram_addr2 = pixel_num2[13:0];
    reg [1:0]   which_block2;
    wire [1:0]  which_block_writing = pixel_num2[15:14];
    assign read_value2 = ram_out_t2[which_block2];


    always @(posedge clk) begin
        // We save value for which block was the read, so that
        // we can pick right value after read is finished.
        which_block1 <= pixel_num1[15:14];
        which_block2 <= pixel_num2[15:14];
    end


    genvar i;
    generate
        // We need 4 block ram
        for (i = 0; i < 4; i = i+1) begin : gen_blockram
            // We use first port for reading and second for writing.
            RAMB16_S1_S1 //#(
                //.INIT_00(~256'h0000000000000000000000000000000000000000000000000000000000000000),
                //.INIT_3F(~256'h0000000000000000000000000000000000000000000000000000000000000000))
            ramen(
                .DOA  (ram_out_t1[i]), // Port A 1-bit Data Output
                .DOB  (ram_out_t2[i]), // Port B 1-bit Data Output
                .ADDRA(ram_addr1), // Port A 14-bit Address Input
                .ADDRB(ram_addr2), // Port B 14-bit Address Input
                .CLKA (clk), // Port A Clock
                .CLKB (clk2), // Port B Clock
                .DIA  (0), // Port A 1-bit Data Input
                .DIB  (write_value), // Port B 1-bit Data Input
                .ENA  (enable_read1), // Port A RAM Enable Input
                .ENB  (enable_read2 | enable_write2), // Port B RAM Enable Input
                //.SSRA (SSRA), // Port A Synchronous Set/Reset Input
                //.SSRB (1), // Port B Synchronous Set/Reset Input
                .WEA  (0), // Port A Write Enable Input
                .WEB  (enable_write2 & (which_block_writing == i)) // Port B Write Enable Input
            );
        end
    endgenerate

endmodule