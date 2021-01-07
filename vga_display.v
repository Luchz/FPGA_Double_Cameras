`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/12 20:40:50
// Design Name: 
// Module Name: vga_display
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
/*
2018.12.31被注释，原因：整合后由控制模块为VGA提供时钟信号，该分频器失效
module divider(
    input I_CLK,
    input rst,
    output O_CLK
    );
    reg oclk = 0;
    parameter multiple = 4;
    integer counter = 0;
    always @ (posedge I_CLK or posedge rst)
        begin
            if(rst == 1)
                begin
                    counter <= 0;
                    oclk <= 0;
                end
            else if((counter + 1) * 2 == multiple)
                    begin
                        counter <= 0;
                        oclk <= ~oclk;
                    end
            else
                counter <= counter + 1;
        end
    assign O_CLK = oclk;
endmodule
*/
module vga_display(
    input clk_25m,
    input rst_n,
    input [11:0] display_data,      // 从BRAM中读得的数据
    input mode,
    input adjust_up,
    input adjust_down,
    output [3:0] red,           // 红色分量
    output [3:0] green,         // 绿色分量
    output [3:0] blue,          // 蓝色分量
    output reg [19:0] addr,
    output [15:0] median_adjust,
    output hs,                  // 行同步信号
    output vs,                  // 场同步信号
    output led                  // 状态指示
    );
    //640*480的vga时序参数
    //被注释的是800*600的VGA时序，可能由于时钟不合适，并没能正常显示
    /*parameter Hor_Sync = 128;
    parameter Hor_Back_Porch = 88;
    parameter Hor_Active_Video = 800;
    parameter Hor_Front_Porch = 40;
    parameter Hor_Scan_Time = 1056;*/
       parameter Hor_Sync = 96;
       parameter Hor_Back_Porch = 48;
       parameter Hor_Active_Video = 640;
       parameter Hor_Front_Porch = 16;
       parameter Hor_Scan_Time = 800;
    /*parameter Ver_Sync = 4;
    parameter Ver_Back_Porch = 23;
    parameter Ver_Active_Video = 600;
    parameter Ver_Front_Porch = 1;
    parameter Ver_Scan_Time = 628;*/
       parameter Ver_Sync = 2;
       parameter Ver_Back_Porch = 33;
       parameter Ver_Active_Video = 480;
       parameter Ver_Front_Porch = 10;
       parameter Ver_Scan_Time = 525;
    //wire clk_d;
    parameter max = 640 * 480;
    parameter high = 480;
    parameter width = 640;
    wire dis_flag, vaild;
    wire gray;
    reg [15:0] hor_c = 0, ver_c = 0;
    reg [3:0] red_reg, green_reg, blue_reg;
    reg [15:0] median;
    //reg [11:0] internal_data;   //数据读进来后缓存至此，复位时清空（2019.1.2被注释，原因：疑似造成图像偏暗）
    //判断是否在有效范围内
    /*assign dis_flag =   (hor_c >= (Hor_Sync + Hor_Back_Porch)) &&
                        (hor_c < (Hor_Sync + Hor_Back_Porch + Hor_Active_Video)) &&
                        (ver_c >= (Ver_Sync + Ver_Back_Porch)) &&
                        (ver_c < (Ver_Sync + Ver_Back_Porch + Ver_Active_Video));*/
    assign vaild = (hor_c >= (Hor_Sync + Hor_Back_Porch + (Hor_Active_Video - width)/2))&&
                    (hor_c < (Hor_Sync + Hor_Back_Porch + Hor_Active_Video - (Hor_Active_Video - width)/2))&&
                    (ver_c >= (Ver_Sync + Ver_Back_Porch + (Ver_Active_Video - high)/2))&&
                    (ver_c < (Ver_Sync + Ver_Back_Porch + Ver_Active_Video - (Ver_Active_Video - high)/2));
    //一开始学习使用VGA时直接输入系统时钟，需要先分频再使用，加入摄像头后由控制模块分配时钟
    //divider vga_divider(.I_CLK(clk),.rst(!rst_n),.O_CLK(clk_25m));
    assign hs = hor_c<Hor_Sync?1'b0:1'b1;       //行同步拉低，行数据准备传送
    assign vs = ver_c<Ver_Sync?1'b0:1'b1;       //场信号拉低，帧数据准备传送
    assign led = (red == 4'b0 || green == 4'b0 || blue == 4'b0) ? 1'b0 : 1'b1;   //所有颜色寄存器数据非零时亮灯，检查色偏
    //行扫描时序
    assign gray = mode == 1 && (red_reg * 30 + green_reg * 59 + blue_reg * 11 + 50) >median[15:0];
    assign red = (mode == 1'b1)?4'b1111 * gray:red_reg;
    assign green = (mode == 1'b1)?4'b1111 * gray:green_reg;
    assign blue = (mode == 1'b1)?4'b1111 * gray:blue_reg;
    initial median = 16'd650;
    assign median_adjust = median[15:0];
    //手动调整阈值
(*DONT_TOUCH = "TRUE"*)always @ (posedge adjust_up or posedge adjust_down)
        begin
            if(adjust_up == 1'b1 && median < 16'd1000)
                median <= median + 16'd20;
            if(adjust_down == 1'b1 && median > 16'd200)
                median <= median - 16'd20;
       end
    always @ (posedge clk_25m)
        begin
            if(hor_c == Hor_Scan_Time - 1)
                    hor_c <= 16'b0;
            else hor_c <= hor_c + 1'b1;
        end
     //场扫描时序
     always @ (posedge clk_25m)
        begin
            if(hor_c == Hor_Scan_Time - 1)
                begin 
                if(ver_c == Ver_Scan_Time - 1)
                    begin
                     ver_c <= 16'b0;
                    end
                else ver_c <= ver_c + 1'b1;
                end
        end
    //从ram中读取数据
    always @ (posedge clk_25m or negedge rst_n)
        begin
            if(vaild)
                begin
                    if(!rst_n)
                    begin
                        red_reg = 4'b0;           //每个像素点的前4位表示红色分量
                        green_reg = 4'b0;          //每个像素点的中间4位表示绿色分量
                        blue_reg = 4'b0;           //每个像素点的后4位表示蓝色分量
                    end
                    else
                    begin
                        red_reg = display_data[11:8];           //每个像素点的前4位表示红色分量
                        green_reg = display_data[7:4];          //每个像素点的中间4位表示绿色分量
                        blue_reg = display_data[3:0];           //每个像素点的后4位表示蓝色分量
                    end
                    if(addr == max - 1)
                        addr <= 20'b0;
                    else
                        addr <= addr + 1'b1;
                end
            else
                begin
                    red_reg = 4'b0;
                    green_reg = 4'b0;
                    blue_reg = 4'b0;
                end
        end
endmodule
/*最开始写的OV2640驱动时序，只完成了SCCB协议的读写状态机，sioc的跳动过于随意，内部划分太乱，决定重写
module camera(
    input [7:0] data,
    input pclk,
    input href,
    input vsync,
    input clk,
    input rst_n,
    inout sio_d,
    output reg sio_c,
    output pwdn,
    output rst
    );
    reg [3:0] ps, ns, sdat_p;
    reg [9:0] clk_count;
    reg [7:0] wr_data;
    reg w_flag, r_flag, fin_flag, restart, sccb, wrclk;
    parameter await = 0, start = 1, w_id = 2, w_addr = 3, w_data = 4, r_data = 5, stop = 6;
    parameter T_wr = 1000;
    always @ (posedge clk or negedge rst_n)
        begin
            if(rst_n == 1'b1)
                begin
                    clk_count <= clk_count + 1;
                    if(clk_count == T_wr - 1)
                        wrclk <= 1;
                    if(wrclk == 1)
                        begin
                            wrclk <= 0;
                            clk_count <= 0;
                        end
                 end
            else
                begin
                    clk_count <= 0;
                    wrclk <= 0;
                end
        end
                        
    always @ (posedge wrclk or negedge rst_n)
        begin
            if(rst_n == 1'b0)
                begin
                    ps <= await;
                end
            else
                ps <= ns;
        end
        
    always @ (*)
    begin
        case(ps)
            await:begin
                if(w_flag == 1 || r_flag == 1)
                    ns = start;
                else begin
                    if(w_flag == 0 && r_flag == 0 && fin_flag == 1)
                        fin_flag = 0;
                    ns = await; end
                end
            start:begin
                if(sio_c == 1 && sio_d == 0)
                begin
                    if(restart == 1'b0)
                        ns = w_id;
                    else
                        ns = r_data;
                end
                else
                    ns = start;
                end
            w_id:begin
                if(sdat_p == 4'b1000)
                    ns = w_addr;
                else
                    ns = w_id;
                end
            w_addr:begin
                if(sdat_p == 4'b1000)
                    begin
                    if(w_flag == 1)
                        ns = w_data;
                    else if(r_data == 1)
                        begin
                        ns = stop;
                        restart = 1'b1;
                        end
                    end
                else
                    ns = w_addr;
                end
            w_data:begin
                if(sdat_p == 4'b1000)
                begin
                    ns = stop;
                end
                else
                    ns = w_data;
                end
            r_data:begin
                if(sdat_p == 4'b1000)
                begin
                    restart = 0;
                    ns = stop;
                end
                else
                    ns = r_data;
                end
            stop:begin
                if(sio_c == 1 && sio_d == 1)
                begin
                    if(restart == 0)
                        ns = await;
                    else
                        ns = start;
                end
                else
                    ns = stop;
                end
        endcase
    end
    
    always @ (posedge wrclk)
        begin
            case(ps)
                start:begin
                    if(sio_c == 0 && sccb == 0)
                        sccb <= 1;
                    else
                        sio_c <= 1;
                    end
                stop:begin
                    if(sio_c == 0 && sccb == 1)
                        sccb <= 0;
                    else if(sio_c == 0)
                        sio_c <= 1;
                    else
                        sccb <= 1;
                    end
                r_data:begin
                    if(sdat_p <4'b1111)
                        sdat_p <= sdat_p + 1;
                        case(sdat_p)
                            4'd0:sio_c <= 1;
                            4'd1:begin wr_data[7] <= sio_d;sio_c <= 0; end
                            4'd2:sio_c <= 1;
                            4'd3:begin wr_data[6] <= sio_d;sio_c <= 0; end
                            4'd4:sio_c <= 1;
                            4'd5:begin wr_data[5] <= sio_d;sio_c <= 0; end
                            4'd6:sio_c <= 1;
                            4'd7:begin wr_data[4] <= sio_d;sio_c <= 0; end
                            4'd8:sio_c <= 1;
                            4'd9:begin wr_data[3] <= sio_d;sio_c <= 0; end
                            4'HA:sio_c <= 1;
                            4'HB:begin wr_data[2] <= sio_d;sio_c <= 0; end
                            4'HC:sio_c <= 1;
                            4'HD:begin wr_data[1] <= sio_d;sio_c <= 0; end
                            4'HE:sio_c <= 1;
                            4'HF:begin wr_data[0] <= sio_d;sio_c <= 0; end
                            default:;
                        endcase
                end
                default:
                    if(ns == w_data || ns == w_id || ns == w_addr)begin
                    if(sdat_p <4'b1000)
                        sdat_p <= sdat_p + 1;
                    case(sdat_p)
                        4'b0000:sccb <= wr_data[0];
                        4'b0001:sccb <= wr_data[1];
                        4'b0010:sccb <= wr_data[2];
                        4'b0011:sccb <= wr_data[3];
                        4'b0100:sccb <= wr_data[4];
                        4'b0101:sccb <= wr_data[5];
                        4'b0110:sccb <= wr_data[6];
                        4'b0111:sccb <= wr_data[7];
                        4'b1000:sccb <= 1'b1;
                        default:;
                    endcase
                    end
            endcase
        end            
    reg [7:0] wreg, wdata, rdata;
    reg [3:0] wpos, rpos;
    reg wflag, rflag, sccb, wbflag, rbflag;
    assign sio_d = sccb;
    task sccb_start;
        sccb = 1'b1;
    endtask
    task write_reg;
        input [7:0] reg_address;
        input [7:0] reg_data;
        sccb_start;
        
    endtask
    //write_data
    always @ (posedge clk)
        begin
            if(wflag == 1)
                begin
                    wpos <= 4'b1000;
                    wbflag <= 1;
                    wdata[7:0] <= wreg[7:0];
                end
            if(wbflag == 1 && wpos == 0)
                wbflag <= 0;
            if(wpos > 0)
                begin
                if(wdata[wpos - 1'b1] == 1)
                    sccb <= 1'b1;
                else
                    sccb <= 1'b0;
                wpos <= wpos - 1'b1; 
                end
        end
    //read data
    always @ (posedge clk)
        begin
            if(rflag == 1)
                begin
                    rpos <= 4'b1000;
                    rbflag <= 1'b1;
                end
            if(rbflag == 1 && rpos == 4'b0)
                rbflag <= 0;
            if(rpos > 0)
                begin
                    if(sio_d == 1)
                        rdata[rpos - 1'b1] <= 1'b1;
                    else
                        rdata[rpos - 1'b1] <= 1'b0;
                    rpos <= rpos - 1'b1;
                end
         end
endmodule
*/