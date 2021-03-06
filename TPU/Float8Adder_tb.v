`timescale 1ns / 1ps

//version 1 + 3 + 4, abandon
module Float8Adder_tb;

    reg [7:0] iNum1;
    reg [7:0] iNum2;
    wire [7:0] oNum;
    wire overflow;
    
    Float8Adder inst(
        .iNum1(iNum1),
        .iNum2(iNum2),
        .oNum(oNum),
        .overflow(overflow)
    );
    
    initial begin
        iNum1 = 8'b00011101; //0.23
        iNum2 = 8'b00101100; //0.44
        
        #5;
        iNum1 = 8'b00111000; //0.77
        iNum2 = 8'b10111000; //-0.77
        
        #5;
        iNum1 = 8'b01000011; //1.2
        iNum2 = 8'b10100011; //-0.3
        
        #5;
        iNum1 = 8'b00100000; //0.25
        iNum2 = 8'b10110101; //-0.66
        
        #5;
        iNum1 = 8'b00000000; // 0
        iNum2 = 8'b10110011; //0.59375

        #5;
        iNum1 = 8'b00000001; // 15.5
        iNum2 = 8'b10000000; // 0.96875
        
        #5;
        iNum1 = 8'b00000000; // 15.5
        iNum2 = 8'b10000000; // 0.96875
    end
endmodule
