module Float16Mult(
    input wire signed [(16 - 1):0] iNum1,
    input wire signed [(16 - 1):0] iNum2,
    output reg signed [(2 * 16 - 2):0] oNum
    );
    
    always @ ( * ) begin
        oNum = iNum1 * iNum2;
    end
endmodule
