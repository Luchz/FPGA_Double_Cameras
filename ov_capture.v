`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/01/02 19:26:22
// Design Name: 
// Module Name: ov_capture
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


module ov_capture(
    input pclk,
    input rst_n,
    input href,
    input vsync,
    input [7:0] data,
    output [11:0] rgb_data,
    output reg [19:0] ram_addr,
    output reg ram_en,                   //�ֱ�ߵ��ֽ�
    output data_state
    );
    parameter line = 640;               //������
    parameter row = 480;                //����߶�
    parameter max = 480 * 640;          //����������
    wire capture_en, data_vaild;        //�ɼ�ʹ�ܣ�дʹ�ܣ�������
    reg v_head;
    reg [7:0] temp;     //���ֽ����ݻ���
    reg [15:0] out_data;//���ݻ���
    reg high_byte = 1;      //���ֽڱ��
    reg [15:0] hc,vc;    //ˮƽ/��ֱɨ�����
    //��Ҫ����Ȼ��Ļ���ֻ��640����Ҫ��������֡�ȵ�Ӱ�죬λ������ᵼ�»���ض�
    assign capture_en = (href == 1'b1) && (vsync == 1'b1);
    assign data_state = (out_data == 16'b0)?1'b0:1'b1;
    assign data_vaild = (hc < line) && (vc < row);
    assign rgb_data = {out_data[15:12],out_data[10:7],out_data[4:1]};
    //always @ (posedge pclk or negedge rst_n)
    always @ (posedge pclk)
        begin
            /*if(rst_n == 0)
                begin
                    high_byte <= 1'b1;
                    ram_addr <= 20'b0;
                    temp <= 8'b0;
                    hc <= 16'b0;
                    vc <= 16'b0;
                    v_head <= 0;
                    ram_en <= 1'b0;
                end
            else*/
            if(capture_en)
                begin
                    if(data_vaild)
                    begin
                        if(high_byte == 1'b1)
                            begin
                                temp[7:0] <= data[7:0];
                                high_byte <= 1'b0;
                                ram_en <= 1'b0;
                            end
                        else begin
                            out_data <= {temp[7:0], data[7:0]};
                            high_byte <= 1'b1;
                            hc <= hc + 1'b1;
                            v_head <= 1'b1;
                            if(hc == line - 1)
                                vc <= vc + 1'b1;
                            if(ram_addr < max && v_head)
                                begin
                                    ram_addr <= ram_addr + 1'b1;
                                    ram_en <= 1'b1;
                                end
                            else
                                ram_addr <= 20'b0;
                        end
                    end
                    else
                        begin
                            hc <= hc;
                            ram_en <= 1'b0;
                            ram_addr <= ram_addr;
                            high_byte <= 1'b1;
                        end
                end
            else if(href == 1'b0 && vsync == 1'b1)
                hc <= 16'b0;
            else
                begin
                    v_head = 1'b0;
                    vc <= 16'b0;
                    hc <= 16'b0;
                    ram_addr <= 20'b0;
                    ram_en <= 1'b0;
                    temp <= 8'b0;
                    high_byte <= 1'b1;
                end
        end
endmodule
