`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/29 22:32:30
// Design Name: 
// Module Name: clk_divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_divider(
    input clk_100m,
    output clk_50m,
    output clk_25m,
    output clk_20m,
    output clk_12m,
    output clk_10m
    );
    
    reg oclk_25m = 0, oclk_50m = 0, oclk_12m = 0, oclk_20m = 0, oclk_10m = 0;
    wire sys_clk = 1;
    parameter multiple_10m = 10;
    parameter multiple_20m = 5;
    parameter multiple_12m = 8;
    parameter multiple_25m = 4;
    parameter multiple_50m = 2;
    integer counter_25m = 0, counter_12m = 0, counter_50m = 0, counter_10m = 0, counter_20m = 0;
    assign sys_clk = ~clk_100m;
    always @ (posedge clk_100m)
        begin
            begin
                if((counter_25m + 1) * 2 == multiple_25m)
                    begin
                        counter_25m <= 0;
                        oclk_25m <= ~oclk_25m;
                    end
                else
                    counter_25m <= counter_25m + 1;
                if((counter_50m + 1)* 2 == multiple_50m)
                    begin
                        counter_50m <= 0;
                        oclk_50m <= ~oclk_50m;
                    end
                else
                    counter_50m <= counter_50m + 1;
                if((counter_12m + 1) * 2 == multiple_12m)
                    begin
                         counter_12m <= 0;
                         oclk_12m <= ~oclk_12m;
                    end
                else
                    counter_12m <= counter_12m + 1;
                if((counter_10m + 1) * 2 == multiple_10m)
                    begin
                        counter_10m <= 0;
                        oclk_10m <= ~oclk_10m;
                    end
                    else
                        counter_10m <= counter_10m + 1;
            end
        end
    //·ÇÅ¼Êý·ÖÆµ
    always @ (posedge clk_100m or posedge sys_clk)
        begin
            if(clk_100m == 1'b1 || sys_clk == 1'b1)
                begin
                    if(counter_20m == multiple_20m - 1)
                    begin
                        oclk_20m = ~oclk_20m;
                        counter_20m <= 0;
                    end
                    else
                        begin
                            counter_20m <= counter_20m + 1'b1;
                        end
                end
        end
    assign clk_50m = oclk_50m;            
    assign clk_25m = oclk_25m;
    assign clk_20m = oclk_20m;
    assign clk_12m = oclk_12m;
    assign clk_10m = oclk_10m;
endmodule
