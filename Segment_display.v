`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/29 10:37:18
// Design Name: 
// Module Name: Segment_display
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


module display_test(
    input clk,
    output [7:0] data
    );
        parameter MS_CYC = 50_000_000;
            //parameter MS_CYC = 100_000;
        reg [32-1:0] ms_cnt = 0;
        reg [3:0]  wait_cnt = 0;
            reg [3:0] display_num;
        wire add_ms_cnt;
        wire end_ms_cnt;
        wire add_wait_cnt ;
        wire end_wait_cnt ;
    always @(posedge clk)begin
            if(add_ms_cnt)begin
                if(end_ms_cnt)
                    ms_cnt <= 0;
                else
                    ms_cnt <= ms_cnt + 1;
            end
        end
            
            assign add_ms_cnt = 1'b1;       
            assign end_ms_cnt = add_ms_cnt && ms_cnt== MS_CYC-1; //1_000_000/20 = 50_000  
            
            always @(posedge clk) begin 
                if(add_wait_cnt) begin
                    if(end_wait_cnt)
                        wait_cnt <= 0; 
                    else
                        wait_cnt <= wait_cnt+1;
               end
            end
            assign add_wait_cnt = (end_ms_cnt);
            assign end_wait_cnt = add_wait_cnt  && wait_cnt == 16 - 1 ;
            assign data = {4'b0000,wait_cnt};
endmodule

module display7(
    input [3:0] iData,
    output [6:0] oData
    );
    wire [15:0] num;
    assign num[15] = iData[3] & iData[2] & iData[1] & iData[0];
    assign num[14] = iData[3] & iData[2] & iData[1] & !iData[0];
    assign num[13] = iData[3] & iData[2] & !iData[1] & iData[0];
    assign num[12] = iData[3] & iData[2] & !iData[1] & !iData[0];
    assign num[11] = iData[3] & !iData[2] & iData[1] & iData[0];
    assign num[10] = iData[3] & !iData[2] & iData[1] & !iData[0];
    assign num[9] = iData[3] & !iData[2] & !iData[1] & iData[0];
    assign num[8] = iData[3] & !iData[2] & !iData[1] & !iData[0];
    assign num[7] = !iData[3] & iData[2] & iData[1] & iData[0];
    assign num[6] = !iData[3] & iData[2] & iData[1] & !iData[0];
    assign num[5] = !iData[3] & iData[2] & !iData[1] & iData[0];
    assign num[4] = !iData[3] & iData[2] & !iData[1] & !iData[0];
    assign num[3] = !iData[3] & !iData[2] & iData[1] & iData[0];
    assign num[2] = !iData[3] & !iData[2] & iData[1] & !iData[0];
    assign num[1] = !iData[3] & !iData[2] & !iData[1] & iData[0];
    assign num[0] = !iData[3] & !iData[2] & !iData[1] & !iData[0];
    assign oData[6] = num[0] | num[1] | num[7] | num[12];
    assign oData[5] = num[2] | num[1] | num[7] | num[3] | num[13];
    assign oData[4] = num[3] | num[1] | num[7] | num[5] | num[4] | num[9];
    assign oData[3] = num[4] | num[1] | num[7] | num[10] | num[15];
    assign oData[2] = num[2] | num[12] | num[14] | num[15];
    assign oData[1] = num[5] | num[6] | num[11] | num[12] | num[14] | num[15];
    assign oData[0] = num[1] | num[4] | num[11] | num[13];
endmodule

module Segment_display(
    input clk,
    input rst_n,
    input en,
    input clk_en,
    input [15:0] iData,
    output [6:0] dis_data,
    output [7:0] seg_en
    );
    reg [31:0] seg_data;
    wire [3:0] data_block[7:0];
    
        //parameter MS_CYC = 5;
    parameter MS_CYC = 50_000;
        //parameter MS_CYC = 100_000;
    reg [16-1:0] ms_cnt = 0;
    reg [3:0]  wait_cnt = 0;
        reg [3:0] display_num;
    wire add_ms_cnt;
    wire end_ms_cnt;
    wire add_wait_cnt ;
    wire end_wait_cnt ;
    wire [7:0] num_data;
    assign data_block[0]=seg_data[3:0];
    assign data_block[1]=seg_data[7:4];
    assign data_block[2]=seg_data[11:8];
    assign data_block[3]=seg_data[15:12];
    assign data_block[4]=seg_data[19:16];
    assign data_block[5]=seg_data[23:20];
    assign data_block[6]=seg_data[27:24];
    assign data_block[7]=seg_data[31:28];
    
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            ms_cnt <= 0;
        end
        else if(add_ms_cnt)begin
            if(end_ms_cnt)
                ms_cnt <= 0;
            else
                ms_cnt <= ms_cnt + 1;
        end
    end
        
        assign add_ms_cnt = clk_en;       
        assign end_ms_cnt = add_ms_cnt && ms_cnt== MS_CYC-1; //1_000_000/20 = 50_000  
        
        always @(posedge clk or negedge rst_n) begin 
            if (rst_n==0) begin
                wait_cnt <= 0; 
            end
            else if(add_wait_cnt) begin
                if(end_wait_cnt)
                    wait_cnt <= 0; 
                else
                    wait_cnt <= wait_cnt+1;
           end
        end
        assign add_wait_cnt = (end_ms_cnt);
        assign end_wait_cnt = add_wait_cnt  && wait_cnt == 8 - 1 ;
        always @(posedge clk or negedge rst_n) begin 
                if (rst_n==0) begin
                    display_num <= 4'b0000;
                    end
                else
                    begin
                        display_num <= data_block[wait_cnt];
                    end
        end
        assign seg_en= 8'b11111111^1<<wait_cnt;
        //assign display_data[0] = num_data[(wait_cnt) * 4];
        display7 display_1(.iData(display_num),.oData(dis_data));
    always @ (posedge clk or negedge rst_n)
        begin
            if(rst_n == 0)
                seg_data <= 32'b0;
            else if(en)
                if(seg_data[15:0] != iData[15:0])
                begin    
                    seg_data[31:16] <= seg_data[15:0];
                    seg_data[15:0] <= iData[15:0];
                end
        end
         
endmodule
