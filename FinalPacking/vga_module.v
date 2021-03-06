module vga_module(
    input iBusClk, // Bus Clock
    input iRstN, // Async reset signal
    input wire mouseClk, // mouse clk , 5MHz
    input wire clkVga, // VGA clock, 40MHz
    inout ps2clk, // ps2 Clock Bus
    inout ps2data, // ps2 Data Bus
    output reg [3:0] oRed, // red signal
    output reg [3:0] oGreen, // green signal
    output reg [3:0] oBlue, // blue signal
    output oHs, // Hori sync
    output oVs, // Vert sync
    output wire [32 * 32 - 1:0] image 
);
    reg [32 * 32 - 1:0] ori_image;
    wire [32 * 32 - 1:0] show_image;
    image_process process_inst(
        .in_image(ori_image),
        .show_image(show_image),
        .out_image(image)
    );

    // 800 * 600
    parameter   C_H_SYNC_PULSE   = 128, 
                C_H_BACK_PORCH   = 88,
                C_H_ACTIVE_TIME  = 800,
                C_H_FRONT_PORCH  = 40,
                C_H_LINE_PERIOD  = 1056;
    
    parameter   C_V_SYNC_PULSE   = 4, 
                C_V_BACK_PORCH   = 23,
                C_V_ACTIVE_TIME  = 600,
                C_V_FRONT_PORCH  = 1,
                C_V_FRAME_PERIOD = 628;

    reg [10:0] hCnt; // Hori Counter
    reg [10:0] vCnt; // Vert Counter
    wire isActive;
    
    reg [16:0] cursor_x = 0;
    reg [16:0] cursor_y = 0;
    reg [2:0]  but_stat;
    wire [8:0] mouse_x;
    wire [8:0] mouse_y;
    wire [2:0] button;
    wire done_sig;
    
    wire [16:0] x_next;
    wire [16:0] y_next;
    wire [2:0] b_next;
    reg do_something;
    
    assign x_next = (~done_sig) ? cursor_x : (mouse_x[7] == 0 ? (cursor_x[16:8] > 510 ? cursor_x : cursor_x + mouse_x[7:0]) : (cursor_x[16:8] < 2 ? cursor_x : cursor_x - ~{9'b111111111, mouse_x[7:0]} - 1));
    assign y_next = (~done_sig) ? cursor_y : (mouse_y[7] == 0 ? (cursor_y[16:8] < 2 ? cursor_y : cursor_y - mouse_y[7:0]) : (cursor_y[16:8] > 510 ? cursor_y : cursor_y + ~{9'b111111111, mouse_y[7:0]} + 1));
    assign b_next = (~done_sig) ? 3'b000 : but_stat;
    always @ ( negedge iBusClk ) begin
        if (!iRstN) begin
            cursor_x <= 0;
            cursor_y <= 0;
            but_stat <= 0;
            do_something <= 0;
        end
        else begin
            cursor_x <= x_next;
            cursor_y <= y_next;
            but_stat <= b_next;
        end
    end
        
    mouse mouse_inst(
        .clk(mouseClk),
        .reset(iRstN),
        .ps2data(ps2data),
        .ps2clk(ps2clk),
        .xm(mouse_x),
        .ym(mouse_y),
        .button(button),
        .done_sig(done_sig)
    );

    // Hori
    always @ (posedge clkVga or negedge iRstN) begin
        if (!iRstN || hCnt == C_H_LINE_PERIOD - 1)
            hCnt <= 11'd0;
        else
            hCnt <= hCnt + 1;
    end

    assign oHs = (hCnt < C_H_SYNC_PULSE) ? 1'b0 : 1'b1;


    //Vert
    always @ (posedge oHs or negedge iRstN) begin
        if (!iRstN || vCnt == C_V_FRAME_PERIOD - 1)
            vCnt <= 11'd0;
        else
            vCnt <= vCnt + 1;
    end

    assign oVs = (vCnt < C_V_SYNC_PULSE) ? 1'b0 : 1'b1;

    assign isActive =   (hCnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH                  ))  &&
                        (hCnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME))  && 
                        (vCnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH                  ))  &&
                        (vCnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME))  ;

    reg [10:0] rowCnt;
    
    wire [10:0] hPos;
    wire [10:0] vPos;
    assign hPos = hCnt - (C_H_SYNC_PULSE + C_H_BACK_PORCH);
    assign vPos = vCnt - (C_V_SYNC_PULSE + C_V_BACK_PORCH);
    always @ (posedge clkVga or negedge iRstN) begin
        if (!iRstN) begin
            oRed <= 4'b0000;
            oGreen <= 4'b0000;
            oBlue <= 4'b0000;
            // image <= 1024'd0;
            for (rowCnt = 0;rowCnt < 1024; rowCnt = rowCnt + 1)
                ori_image[rowCnt] = 0;
        end
        else if (isActive) begin
            if (hPos <= cursor_x[16:8] + 8 && hPos + 8 >= cursor_x[16:8] && vPos <= cursor_y[16:8] + 8 && vPos + 8 >= cursor_y[16:8]) begin
                if (button[2]) begin 
                    oRed <= 4'b0000;
                    oBlue <= 4'b0000;
                    oGreen <= 4'b1111;
                end
                else if (button[1]) begin 
                    oRed <= 4'b0000;
                    oBlue <= 4'b1111;
                    oGreen <= 4'b0000;
                end
                else begin
                    oRed <= 4'b1111;
                    oBlue <= 4'b0000;
                    oGreen <= 4'b0000;
                end
            end
            else begin

                if (hPos < 512 && vPos < 512 && show_image[{vPos[8:4], hPos[8:4]}] == 1) begin
                    oRed <= 4'b1111;
                    oGreen <= 4'b0000;
                    oBlue <= 4'b1111;
                end
                else if (hPos < 512 && vPos < 512) begin 
                    oRed <= 4'b1111;
                    oGreen <= 4'b1111;
                    oBlue <= 4'b1111;
                end
                else begin 
                    oRed <= 4'b0011;
                    oGreen <= 4'b0011;
                    oBlue <= 4'b1111;
                end
                
            end
            
            if (button[1] && !ori_image[{cursor_y[16:12], cursor_x[16:12]}]) begin
                ori_image[{cursor_y[16:12], cursor_x[16:12]}] = 1;
            end
            else
                do_something = 1;
        end
        else begin
            oRed <= 4'b0010;
            oGreen <= 4'b0010;
            oBlue <= 4'b0010;
        end
    end
endmodule