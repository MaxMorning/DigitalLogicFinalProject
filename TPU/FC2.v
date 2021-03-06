module full_connect2(
    input ena,
    input clk,
    input iRst_n,
    input [128 * 8 - 1:0] data_from_rom,
    input [128 * 8 - 1:0] data_from_ram,
    input [14:0] data_from_MultAdder,
    input overflow_from_MultAdder,
    
    output reg overflow,
    output reg done,
    output reg [31:0] addr_to_rom,
    // output reg [31:0] addr_to_ram,
    output reg [128 * 8 - 1:0] opr1_to_MultAdder,
    output reg [128 * 8 - 1:0] opr2_to_MultAdder,
    output reg [10 * 8 - 1:0] data_to_ram
);

    parameter   rom_addr_base = 32'h00000000,
                ram_addr_base = 32'h00001000,
                bias_addr_base = 32'h00002000;

    reg bias_get_done;
    reg bias_ask_done;
    reg [7:0] rowCnt;
    reg [128 * 8 - 1:0] biases;
    reg [3:0] status;
    reg [14:0] sum;

    always @ (posedge clk) begin
        if (!ena) begin
            overflow <= 1'bz;
            done <= 0;
            addr_to_rom <= {32{1'bz}};
            // addr_to_ram <= {32{1'bz}};
            opr1_to_MultAdder <= {1024{1'bz}};
            opr2_to_MultAdder <= {1024{1'bz}};
        end
        else if (!iRst_n) begin
            bias_get_done <= 0;
            bias_ask_done <= 0;
            overflow <= 0;
            done <= 0;
            rowCnt <= 0;
            status <= 4'b0000;
            sum <= 0;
        end
        else begin
            if (bias_ask_done == 0) begin
                addr_to_rom <= bias_addr_base;
                bias_ask_done <= 1;
            end
            else if (bias_get_done == 0) begin
                biases = data_from_rom;
                bias_get_done = 1;
            end
        end
    end

    reg [14:0] adder_opr1;
    reg [14:0] adder_opr2;

    wire [14:0] adder_sum;
    wire adder_overflow;
    Float8Adder adder(
        .iNum1(adder_opr1),
        .iNum2(adder_opr2),

        .oNum(adder_sum),
        .overflow(adder_overflow)
    );
    always @ (posedge clk) begin
        if (bias_get_done && ena && iRst_n)
            case (status)
                4'b1000: // r = 0
                    begin
                        status <= 4'b0000;
                        rowCnt <= 0;
                    end
                4'b0000: // ask w,a
                    begin
                        status <= 4'b0001;
                        addr_to_rom <= rom_addr_base + rowCnt;
                        // addr_to_ram <= ram_addr_base + rowCnt;
                    end
                4'b0001: // get w,a ; calc wa
                    begin
                        status <= 4'b0010;
                        opr1_to_MultAdder <= data_from_ram;
                        opr2_to_MultAdder <= data_from_rom;
                    end
                4'b0010: // get wa ; calc wa + b
                    begin
                        status <= 4'b0011;
                        overflow <= overflow | overflow_from_MultAdder;
                        adder_opr1 = {biases[8 * rowCnt + 7 -: 8], 7'b0000000};
                        adder_opr2 <= data_from_MultAdder;
                    end
                4'b0011: // get wa + b ; ++r
                    begin
                        status <= 4'b0100;
                        overflow = overflow | adder_overflow;
                        data_to_ram[8 * rowCnt + 7 -: 8] = adder_sum[14:7];
                        rowCnt = rowCnt + 1;
                        sum = 0;
                    end
                4'b0100: // r < 10 ?
                    begin
                        if (rowCnt < 10)
                            status <= 4'b0000;
                        else
                            status <= 4'b0101;
                    end
                4'b0101: // set done
                    begin
                        status <= 4'b0101;
                        done <= 1;
                    end
                default: 
                    status <= 4'b1000;
            endcase
    end
endmodule