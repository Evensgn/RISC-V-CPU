`include "defines.v"

module ram (
    input  wire               clk   ,
    input  wire               ce    ,
    input  wire               we    ,
    input  wire [`MemAddrBus] addr  ,
    input  wire [        3:0] sel   ,
    input  wire [`MemDataBus] data_i,
    output reg  [`MemDataBus] data_o
);

    reg [`ByteBus] bank0[0:`DataMemNum-1];
    reg [`ByteBus] bank1[0:`DataMemNum-1];
    reg [`ByteBus] bank2[0:`DataMemNum-1];
    reg [`ByteBus] bank3[0:`DataMemNum-1];

    wire[`DataMemNumLog2-1:0] saddr = addr[`DataMemNumLog2+1:2];

    always @ (posedge clk) begin
        if (ce && we) begin
            $display("data into mem: %h, saddr: %d, sel: %b", data_i, saddr, sel);
            if (sel[3]) bank3[saddr] <= data_i[31:24];
            if (sel[2]) bank2[saddr] <= data_i[23:16];
            if (sel[1]) bank1[saddr] <= data_i[15:8];
            if (sel[0]) bank0[saddr] <= data_i[7:0];
        end
    end

    always @ (*) begin
        if (!ce) begin
            data_o <= 0;
        end else if (!we) begin
            $display("data out mem: %h, saddr: %d", data_o, saddr);
            data_o <= {bank3[saddr], bank2[saddr], bank1[saddr], bank0[saddr]};
        end else begin
            data_o <= 0;
        end
    end

endmodule // ram