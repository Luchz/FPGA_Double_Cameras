`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/01/02 18:02:47
// Design Name: 
// Module Name: Control
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


module Control(
    //SYS_INPUT
    input clk,
    //USER_INPUT
    input rst_n,
    //STATE_OUTPUT
    output vga_state,
    output init_state,
    output setup_state,
    output capture_state,
    output [6:0] segment_data,
    output [7:0] segment_en,
    //OV2640_INPUT
    input ov_pclk,
    input ov_href,
    input ov_vsync,
    input [7:0] ov_data,
    //OV2640_OUTPUT
    inout ov_sio_d,
    output ov_sio_c,
    output ov_xclk,
    output ov_rst,
    output ov_pwdn,
    //VGA_INPUT
    input mode,
    input adjust_down,
    input adjust_up,
    input seg_en,
    //VGA_OUTPUT
    output vga_hs,
    output vga_vs,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b
    );
    
    wire bram_portA_en;
    wire [19:0] bram_wraddr,bram_rdaddr;
    wire [11:0] bram_wrdata,bram_rddata;
    wire [15:0] median;
    wire clk_25m,clk_50m,clk_12m,clk_10m;
    
    clk_divider Central_divider(
    .clk_100m(clk),
    .clk_50m(clk_50m),
    .clk_25m(clk_25m),
    .clk_12m(clk_12m),
    .clk_20m(clk_20m),
    .clk_10m(clk_10m)
    );
    
    ov2640 ov2640_inst(
    .clk(clk),
    .rst_n(rst_n),
    .finish(init_state),
    .init_en(setup_state),
    .capture_state(capture_state),
    .pclk(ov_pclk),
    .xclk(ov_xclk),
    .sio_d(ov_sio_d),
    .sio_c(ov_sio_c),
    .ov_pwdn(ov_pwdn),
    .ov_rst(ov_rst),
    .ov_data(ov_data),       //来自摄像头的8位数据
    .ov_href(ov_href),
    .ov_vsync(ov_vsync),
    .wr_addr(bram_wraddr),     //写寄存器地址
    .wr_data(bram_wrdata),     //写寄存器数据
    .wr_en(bram_portA_en));       //写寄存器使能
    
    vga_display vga_inst(
    .clk_25m(clk_25m),
    .rst_n(rst_n),
    .display_data(bram_rddata),      // 从BRAM中读得的数据
    .red(vga_r),           // 红色分量
    .green(vga_g),         // 绿色分量
    .blue(vga_b),          // 蓝色分量
    .addr(bram_rdaddr),
    .hs(vga_hs),                  // 行同步信号
    .vs(vga_vs),                  // 场同步信号
    .led(vga_state),                  // 状态指示
    .mode(mode),
    .adjust_up(adjust_up),
    .adjust_down(adjust_down),
    .median_adjust(median)
    );
    
    blk_mem_gen_0 ram_u0 (
      .clka(clk),    // input wire clka
      .wea(bram_portA_en),      // input wire [0 : 0] wea
      .addra(bram_wraddr),  // input wire [15 : 0] addra
      .dina(bram_wrdata),    // input wire [15 : 0] dina
      .clkb(clk_25m),    // input wire clkb
      .addrb(bram_rdaddr),  // input wire [15 : 0] addrb
      .doutb(bram_rddata)  // output wire [15 : 0] doutb
    );
    
    Segment_display Display_inst(
    .clk(clk),
    .rst_n(1'b1),
    .en(seg_en),
    .clk_en(1'b1),
    .iData(median),
    .dis_data(segment_data),
    .seg_en(segment_en)
    );
endmodule
