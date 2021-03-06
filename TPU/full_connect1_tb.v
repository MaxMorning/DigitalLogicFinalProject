`timescale 1ns / 1ps

module full_connect1_tb;

    reg ena;
    reg clk;
    reg iRst_n;
    reg [128 * 8 - 1:0] data_from_rom;
    reg [128 * 8 - 1:0] data_from_ram;
    reg [14:0] data_from_MultAdder;
    reg overflow_from_MultAdder;
    
    wire overflow;
    wire done;
    wire [31:0] addr_to_rom;
    wire [2:0] addr_to_ram;
    wire [128 * 8 - 1:0] opr1_to_MultAdder;
    wire [128 * 8 - 1:0] opr2_to_MultAdder;
    wire [128 * 8 - 1:0] data_to_ram;

    full_connect1 inst(
        .ena(ena),
        .clk(clk),
        .iRst_n(iRst_n),
        .data_from_rom(data_from_rom),
        .data_from_ram(data_from_ram),
        .data_from_MultAdder(data_from_MultAdder),
        .overflow_from_MultAdder(overflow_from_MultAdder),

        .overflow(overflow),
        .done(done),
        .addr_to_rom(addr_to_rom),
        .addr_to_ram(addr_to_ram),
        .opr1_to_MultAdder(opr1_to_MultAdder),
        .opr2_to_MultAdder(opr2_to_MultAdder),
        .data_to_ram(data_to_ram)
    );

    initial begin
        clk = 0;
        forever
            #5 clk = ~clk;
    end

    initial begin
        ena = 1;
        iRst_n = 0;

        #14
        iRst_n = 1;
        data_from_rom = {128{8'b00000001}};
        data_from_ram = {128{8'b00000010}};
        data_from_MultAdder = 15'b000000101000011;
        overflow_from_MultAdder = 0;
        
        #60000
        ena = 0;
    end
    
endmodule
