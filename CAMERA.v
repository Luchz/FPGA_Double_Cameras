`timescale 1ns / 1ps


module sccb_interface(
    input clk,
    input rst_n,

    input wr_en,
    input rd_en,
    input [8-1:0] id_addr,
    input [8-1:0] reg_addr,
    input [8-1:0] wr_data,
    output reg [8-1:0] rd_data,
    output reg rd_vld,
    output rdy,

    output reg sio_c,
    output reg sio_out_en,
    output reg sio_out,
    input sio_in
    );

    parameter CYC = 500;
    //parameter CYC = 4;

localparam  IDLE = 0 ;
localparam  START = 1 ;
localparam  WRI_ID = 2 ;
localparam  WRI_REG = 3 ;
localparam  WRI_DATA = 4;
localparam  RD_DATA = 5;
localparam  STOP = 6 ;

//计数器
reg [ (9-1):0]  div_cnt     ;
wire        add_div_cnt ;
wire        end_div_cnt ;
reg [ (5-1):0]  bit_cnt     ;
wire        add_bit_cnt ;
wire        end_bit_cnt ;
reg [5-1:0] N;
(*DONT_TOUCH = "TRUE"*)reg [7-1:0] state_c,state_n;
wire idle2start,start2wri_id,wri_id2wri_reg,wri_id2rd_data, wri_reg2wri_data,wri_reg2stop,wri_data2stop,rd_data2stop,stop2start,stop2idle;
wire [9-1:0] regaddr;
reg [8-1:0] reg_addr_tmp;
reg [8-1:0] wr_data_tmp;
wire [9-1:0] idaddr_nc;
reg [8-1:0] id_addr_tmp;
reg rd_oper,rd_flag;
wire [9-1:0] wdata_nc;
wire [8-1:0] id_rwCtrl;


assign rdy = state_c == IDLE && !wr_en && !rd_en;

always @(posedge clk or negedge rst_n) begin 
    if (rst_n==0) begin
        div_cnt <= 0; 
    end
    else if(add_div_cnt) begin
        if(end_div_cnt)
            div_cnt <= 0; 
        else
            div_cnt <= div_cnt+1 ;
   end
end
assign add_div_cnt = (state_c != IDLE);
assign end_div_cnt = add_div_cnt  && div_cnt == (CYC)-1 ;//5000ns,200KHZ

always @(posedge clk or negedge rst_n) begin 
    if (rst_n==0) begin
        bit_cnt <= 0; 
    end
    else if(add_bit_cnt) begin
        if(end_bit_cnt)
            bit_cnt <= 0; 
        else
            bit_cnt <= bit_cnt+1 ;
   end
end
assign add_bit_cnt = (end_div_cnt);
assign end_bit_cnt = add_bit_cnt  && bit_cnt == (N)-1 ;
//数据位数限制
always@(*)begin
    case(state_c)
        START:                  N = 1;
        WRI_REG:                N = 9; //(8+1)*2 = 18
        WRI_ID,WRI_DATA,RD_DATA:N = 9;//8+1
        STOP:                   N = 2;
        default:;
    endcase
end

//FSM:IDLE START WRI_ID WRI_REG STOP
always @(posedge clk or negedge rst_n) begin 
    if (rst_n==0) begin
        state_c <= IDLE ;
    end
    else begin
        state_c <= state_n;
   end
end
//write:IDLE START WRI_ID WRI_REG WRI_DATA STOP IDLE...
//read: IDLE START WRI_ID WRI_REG STOP      START WRI_ID RD_DATA STOP IDLE...

always @(*) begin 
    case(state_c)  
        IDLE :begin                             //0
            if(idle2start) 
                state_n = START ;
            else 
                state_n = state_c ;
        end
        START :begin                            //1
            if(start2wri_id) 
                state_n = WRI_ID ;
            else 
                state_n = state_c ;
        end
        WRI_ID :begin                           //2
            if(wri_id2wri_reg) 
                state_n = WRI_REG ;
            else if(wri_id2rd_data)
                state_n = RD_DATA;
            else 
                state_n = state_c ;
        end
        WRI_REG :begin                          //3
            if(wri_reg2wri_data)
                state_n = WRI_DATA;
            else if(wri_reg2stop) 
                state_n = STOP ;
            else 
                state_n = state_c ;
        end
        WRI_DATA:begin                          //4
            if(wri_data2stop)
                state_n = STOP;
            else 
                state_n = state_c;
        end 
        RD_DATA:begin                           //5
            if(rd_data2stop)
                state_n = STOP;
            else
                state_n = state_c;
        end
        STOP :begin                             //6
            if(stop2start)
                state_n = START;
            else if(stop2idle) 
                state_n = IDLE ;
            else 
                state_n = state_c ;
        end
        default : state_n = IDLE ;
    endcase
end

assign idle2start           = state_c==IDLE         && (wr_en || rd_en);
assign start2wri_id         = state_c==START        && (end_bit_cnt);
assign wri_id2wri_reg       = state_c==WRI_ID       && (end_bit_cnt && !rd_oper);
assign wri_id2rd_data       = state_c==WRI_ID       && (end_bit_cnt && rd_oper);
assign wri_reg2wri_data     = state_c==WRI_REG      && (end_bit_cnt && !rd_flag);
assign wri_reg2stop         = state_c==WRI_REG      && (end_bit_cnt && rd_flag);
assign wri_data2stop        = state_c==WRI_DATA     && (end_bit_cnt);
assign rd_data2stop         = state_c==RD_DATA      && (end_bit_cnt);
assign stop2start           = state_c==STOP         && (end_bit_cnt && rd_flag && !rd_oper);
assign stop2idle            = state_c==STOP         && (end_bit_cnt && (!rd_flag || rd_oper));

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rd_oper <= 0;
    end
    else if(stop2start)begin
        rd_oper <= 1;
    end
    else if(rd_oper && stop2idle)
        rd_oper <= 0;
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rd_flag <= 0;
    end
    else if(idle2start && rd_en)begin
        rd_flag <= 1;
    end
    else if(stop2idle)
        rd_flag <= 0;
end

//SCCB时钟
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)
        sio_c <= 1'b1;
    else if(add_div_cnt && div_cnt == CYC/4-1)
        sio_c <= 1;
    else if(add_div_cnt && div_cnt == CYC/4+CYC/2-1)
        sio_c <= 0;
    else if(state_c == IDLE)
        sio_c <= 1;//空闲状态sioc为1
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        sio_out <= 1;
    end
    else if(state_c == START && div_cnt == CYC/2-1)
        sio_out <= 0;//开始条件
    else if(state_c == WRI_ID)
        sio_out <= idaddr_nc[9-1-bit_cnt];
    else if(wri_reg2stop || wri_data2stop || rd_data2stop)
        sio_out <= 0;
    else if(state_c == WRI_REG)
        sio_out <= regaddr[9-1-bit_cnt];
    else if(state_c == WRI_DATA)
        sio_out <= wdata_nc[9-1-bit_cnt];
    else if(state_c == RD_DATA && bit_cnt == 9-1)
        sio_out <= 1;//NACK
    else if(state_c == STOP && div_cnt == CYC/2-1 && bit_cnt == 0)
        sio_out <= 1;//结束条件
end

assign idaddr_nc = {id_rwCtrl,1'b1};
assign regaddr = {reg_addr_tmp[7:0],1'b1};
assign wdata_nc = {wr_data_tmp,1'b1};

assign id_rwCtrl = rd_oper ? {id_addr[7:1],1'b1} : id_addr;

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        reg_addr_tmp <= 0;
        wr_data_tmp <= 0;
    end
    else if(wr_en || rd_en)begin
        reg_addr_tmp <= reg_addr;
        wr_data_tmp <= wr_data;
    end
end

//SIO_D使能
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        sio_out_en <= 0;
    end
    else begin
        case(state_c)
            START,STOP:begin
                sio_out_en <= 1;
            end
            WRI_ID,WRI_DATA:begin
                if(bit_cnt != 9-1)
                    sio_out_en <= 1;
                else
                    sio_out_en <= 0;
            end
            WRI_REG:begin
                if(bit_cnt != 9-1)
                    sio_out_en <= 1;
                else
                    sio_out_en <= 0;
            end
            RD_DATA:begin
                if(bit_cnt == 9-1)
                    sio_out_en <= 1;
                else
                    sio_out_en <= 0;
            end 
            default:sio_out_en <= 1;
        endcase
    end
end

//read data
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rd_data <= 0;
    end
    else if(state_c == RD_DATA && bit_cnt != 9-1 && div_cnt == CYC/2-1)begin
        rd_data[8-1-bit_cnt] <= sio_in;
    end
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rd_vld <= 0;
    end
    else if(rd_data2stop)begin
        rd_vld <= 1;
    end
    else 
        rd_vld <= 0;
end
endmodule

module reg_config(
    input           clk,
    input           rst_n,

    input           en,
    output          finish,

    inout           sio_d,
    output          sio_c,
    output [7:0]    data_output,
    output          read_state
    );

localparam WR_ID = 8'h60;
localparam WR_CTRL = 2'b10;//读
localparam RD_CTRL = 2'b01;//写
wire sio_out_en;
wire sio_out;
wire sio_in;
reg [9-1:0] reg_cnt;
wire add_reg_cnt,end_reg_cnt;
reg config_flag;
reg [18-1:0] op_reg_data;
wire rdy;//读写预备
reg wr_en;//读写使能
reg [8-1:0] reg_addr;//寄存器
reg [8-1:0] wr_data;//数据
reg config_done;//配置完成
reg [ (2-1):0]  rw_cnt     ;
wire        add_rw_cnt ;
wire        end_rw_cnt ;
reg rd_en;
(*DONT_TOUCH = "TRUE"*)wire [8-1:0] rd_data;
(*DONT_TOUCH = "TRUE"*)wire rd_vld;

sccb_interface sccb_interface(
    .clk    (clk) ,
    .rst_n     (rst_n) ,
    .wr_en     (wr_en) ,
    .rd_en     (rd_en),
    .id_addr   (WR_ID) ,
    .reg_addr  (reg_addr) ,
    .wr_data   (wr_data) ,
    .rd_data   (rd_data),
    .rd_vld    (rd_vld),
    .rdy       (rdy) ,
    .sio_c     (sio_c) ,
    .sio_out_en(sio_out_en) ,
    .sio_out   (sio_out) ,
    .sio_in    (sio_in) 
    );

    assign sio_d = sio_out_en ? sio_out : 1'bz;//三态
    assign sio_in = sio_d;//三态输入
    assign data_output[7:0] = rd_data[7:0];
    assign read_state = add_reg_cnt;

    always @(posedge clk or negedge rst_n) begin 
        if (rst_n==0) begin
            rw_cnt <= 0; 
        end
        else if(add_rw_cnt) begin
            if(end_rw_cnt)
                rw_cnt <= 0; 
            else
                rw_cnt <= rw_cnt+1 ;
        end
    end
    assign add_rw_cnt = (config_flag && rdy);
    assign end_rw_cnt = add_rw_cnt  && rw_cnt == 2 - 1 ;//0 write 1 read

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            reg_cnt <= 0;
        end
        else if(add_reg_cnt)begin
            if(end_reg_cnt)
                reg_cnt <= 0;
            else
                reg_cnt <= reg_cnt + 1;
        end
    end

    assign add_reg_cnt = end_rw_cnt;       
    assign end_reg_cnt = add_reg_cnt && reg_cnt == 183;   

    //配置指令
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_en <= 0;
            reg_addr <= 0;
            wr_data <= 0;
        end
        else if(add_rw_cnt && rw_cnt == 0)begin
            wr_en    <= op_reg_data[17];
            reg_addr <= op_reg_data[15:8];
            wr_data  <= op_reg_data[7:0];
            rd_en    <= op_reg_data[16];
        end
        else begin
            wr_en <= 0;
            rd_en <= 0;
        end
    end


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            config_flag <= 0;
        end
        else if(en && !config_flag && !config_done)begin
            config_flag <= 1;
        end
        else if(end_reg_cnt)
            config_flag <= 0;
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            config_done <= 0;
        end
        else if(end_reg_cnt)begin
            config_done <= 1;
        end
    end

    assign finish = config_done && rdy;

always@(*)   
 begin//op_reg_data [17] wr  [16] rd  [15:8] reg_addr  [7:0] wr_data     
    case(reg_cnt)
    //SXGA(1600*1200)
    1:op_reg_data=   {WR_CTRL, 16'hFF01};//Select Sensor_Reg
    2:op_reg_data=   {WR_CTRL, 16'h1280};//Software reset
    3:op_reg_data=   {RD_CTRL, 16'h1CFF};//Read high_byte of the MID
    4:op_reg_data=   {RD_CTRL, 16'h1DFF};//Read low_byte of the MID
    5:op_reg_data=   {RD_CTRL, 16'h0Aff};//Read high_byte of the HID
    6:op_reg_data=   {RD_CTRL, 16'h0Bff};//Read low_byte of the HID
    7:op_reg_data = {WR_CTRL, 16'hff01};
    8:op_reg_data = {WR_CTRL, 16'h1280};
    9:op_reg_data = {WR_CTRL, 16'hff00};
    10:op_reg_data = {WR_CTRL, 16'h2cff};
    11:op_reg_data = {WR_CTRL, 16'h2edf};
    12:op_reg_data = {WR_CTRL, 16'hff01};
    13:op_reg_data = {WR_CTRL, 16'h3c32};
    14:op_reg_data = {WR_CTRL, 16'h1101};
    15:op_reg_data = {WR_CTRL, 16'h0902};
    16:op_reg_data = {WR_CTRL, 16'h0420};
    17:op_reg_data = {WR_CTRL, 16'h13e5};
    18:op_reg_data = {WR_CTRL, 16'h1448};
    19:op_reg_data = {WR_CTRL, 16'h2c0c};
    20:op_reg_data = {WR_CTRL, 16'h3378};
    21:op_reg_data = {WR_CTRL, 16'h3a33};
    22:op_reg_data = {WR_CTRL, 16'h3bfb};
    23:op_reg_data = {WR_CTRL, 16'h3e00};
    24:op_reg_data = {WR_CTRL, 16'h4311};
    25:op_reg_data = {WR_CTRL, 16'h1610};
    26:op_reg_data = {WR_CTRL, 16'h3992};
    27:op_reg_data = {WR_CTRL, 16'h35da};
    28:op_reg_data = {WR_CTRL, 16'h221a};
    29:op_reg_data = {WR_CTRL, 16'h37c3};
    30:op_reg_data = {WR_CTRL, 16'h2300};
    31:op_reg_data = {WR_CTRL, 16'h34c0};
    32:op_reg_data = {WR_CTRL, 16'h361a};
    33:op_reg_data = {WR_CTRL, 16'h0688};
    34:op_reg_data = {WR_CTRL, 16'h07c0};
    35:op_reg_data = {WR_CTRL, 16'h0d87};
    36:op_reg_data = {WR_CTRL, 16'h0e41};
    37:op_reg_data = {WR_CTRL, 16'h4c00};
    38:op_reg_data = {WR_CTRL, 16'h4800};
    39:op_reg_data = {WR_CTRL, 16'h5b00};
    40:op_reg_data = {WR_CTRL, 16'h4203};
    41:op_reg_data = {WR_CTRL, 16'h4a81};
    42:op_reg_data = {WR_CTRL, 16'h2199};
    43:op_reg_data = {WR_CTRL, 16'h2440};
    44:op_reg_data = {WR_CTRL, 16'h2538};
    45:op_reg_data = {WR_CTRL, 16'h2682};
    46:op_reg_data = {WR_CTRL, 16'h5c00};
    47:op_reg_data = {WR_CTRL, 16'h6300};
    48:op_reg_data = {WR_CTRL, 16'h4600};
    49:op_reg_data = {WR_CTRL, 16'h0c3c};
    50:op_reg_data = {WR_CTRL, 16'h6170};
    51:op_reg_data = {WR_CTRL, 16'h6280};
    52:op_reg_data = {WR_CTRL, 16'h7c05};
    53:op_reg_data = {WR_CTRL, 16'h2080};
    54:op_reg_data = {WR_CTRL, 16'h2830};
    55:op_reg_data = {WR_CTRL, 16'h6c00};
    56:op_reg_data = {WR_CTRL, 16'h6d80};
    57:op_reg_data = {WR_CTRL, 16'h6e00};
    58:op_reg_data = {WR_CTRL, 16'h7002};
    59:op_reg_data = {WR_CTRL, 16'h7194};
    60:op_reg_data = {WR_CTRL, 16'h73c1};
    61:op_reg_data = {WR_CTRL, 16'h1240};
    62:op_reg_data = {WR_CTRL, 16'h1711};
    63:op_reg_data = {WR_CTRL, 16'h1843};
    64:op_reg_data = {WR_CTRL, 16'h1900};
    65:op_reg_data = {WR_CTRL, 16'h1a4b};
    66:op_reg_data = {WR_CTRL, 16'h3209};
    67:op_reg_data = {WR_CTRL, 16'h37c0};
    68:op_reg_data = {WR_CTRL, 16'h4fca};
    69:op_reg_data = {WR_CTRL, 16'h50a8};
    70:op_reg_data = {WR_CTRL, 16'h5a23};
    71:op_reg_data = {WR_CTRL, 16'h6d00};
    72:op_reg_data = {WR_CTRL, 16'h3d38};
    73:op_reg_data = {WR_CTRL, 16'hff00};
    74:op_reg_data = {WR_CTRL, 16'he57f};
    75:op_reg_data = {WR_CTRL, 16'hf9c0};
    76:op_reg_data = {WR_CTRL, 16'h4124};
    77:op_reg_data = {WR_CTRL, 16'he014};
    78:op_reg_data = {WR_CTRL, 16'h76ff};
    79:op_reg_data = {WR_CTRL, 16'h33a0};
    80:op_reg_data = {WR_CTRL, 16'h4220};
    81:op_reg_data = {WR_CTRL, 16'h4318};
    82:op_reg_data = {WR_CTRL, 16'h4c00};
    83:op_reg_data = {WR_CTRL, 16'h87d5};
    84:op_reg_data = {WR_CTRL, 16'h883f};
    85:op_reg_data = {WR_CTRL, 16'hd703};
    86:op_reg_data = {WR_CTRL, 16'hd910};
    87:op_reg_data = {WR_CTRL, 16'hd382};
    88:op_reg_data = {WR_CTRL, 16'hc808};
    89:op_reg_data = {WR_CTRL, 16'hc980};
    90:op_reg_data = {WR_CTRL, 16'h7c00};
    91:op_reg_data = {WR_CTRL, 16'h7d00};
    92:op_reg_data = {WR_CTRL, 16'h7c03};
    93:op_reg_data = {WR_CTRL, 16'h7d48};
    94:op_reg_data = {WR_CTRL, 16'h7d48};
    95:op_reg_data = {WR_CTRL, 16'h7c08};
    96:op_reg_data = {WR_CTRL, 16'h7d20};
    97:op_reg_data = {WR_CTRL, 16'h7d10};
    98:op_reg_data = {WR_CTRL, 16'h7d0e};
    99:op_reg_data = {WR_CTRL, 16'h9000};
    100:op_reg_data = {WR_CTRL, 16'h910e};
    101:op_reg_data = {WR_CTRL, 16'h911a};
    102:op_reg_data = {WR_CTRL, 16'h9131};
    103:op_reg_data = {WR_CTRL, 16'h915a};
    104:op_reg_data = {WR_CTRL, 16'h9169};
    105:op_reg_data = {WR_CTRL, 16'h9175};
    106:op_reg_data = {WR_CTRL, 16'h917e};
    107:op_reg_data = {WR_CTRL, 16'h9188};
    108:op_reg_data = {WR_CTRL, 16'h918f};
    109:op_reg_data = {WR_CTRL, 16'h9196};
    110:op_reg_data = {WR_CTRL, 16'h91a3};
    111:op_reg_data = {WR_CTRL, 16'h91af};
    112:op_reg_data = {WR_CTRL, 16'h91c4};
    113:op_reg_data = {WR_CTRL, 16'h91d7};
    114:op_reg_data = {WR_CTRL, 16'h91e8};
    115:op_reg_data = {WR_CTRL, 16'h9120};
    116:op_reg_data = {WR_CTRL, 16'h9200};
    117:op_reg_data = {WR_CTRL, 16'h9306};
    118:op_reg_data = {WR_CTRL, 16'h93e3};
    119:op_reg_data = {WR_CTRL, 16'h9305};
    120:op_reg_data = {WR_CTRL, 16'h9305};
    121:op_reg_data = {WR_CTRL, 16'h9300};
    122:op_reg_data = {WR_CTRL, 16'h9304};
    123:op_reg_data = {WR_CTRL, 16'h9300};
    124:op_reg_data = {WR_CTRL, 16'h9300};
    125:op_reg_data = {WR_CTRL, 16'h9300};
    126:op_reg_data = {WR_CTRL, 16'h9300};
    127:op_reg_data = {WR_CTRL, 16'h9300};
    128:op_reg_data = {WR_CTRL, 16'h9300};
    129:op_reg_data = {WR_CTRL, 16'h9300};
    130:op_reg_data = {WR_CTRL, 16'h9600};
    131:op_reg_data = {WR_CTRL, 16'h9708};
    132:op_reg_data = {WR_CTRL, 16'h9719};
    133:op_reg_data = {WR_CTRL, 16'h9702};
    134:op_reg_data = {WR_CTRL, 16'h970c};
    135:op_reg_data = {WR_CTRL, 16'h9724};
    136:op_reg_data = {WR_CTRL, 16'h9730};
    137:op_reg_data = {WR_CTRL, 16'h9728};
    138:op_reg_data = {WR_CTRL, 16'h9726};
    139:op_reg_data = {WR_CTRL, 16'h9702};
    140:op_reg_data = {WR_CTRL, 16'h9798};
    141:op_reg_data = {WR_CTRL, 16'h9780};
    142:op_reg_data = {WR_CTRL, 16'h9700};
    143:op_reg_data = {WR_CTRL, 16'h9700};
    144:op_reg_data = {WR_CTRL, 16'hc3ed};
    145:op_reg_data = {WR_CTRL, 16'ha400};
    146:op_reg_data = {WR_CTRL, 16'ha800};
    147:op_reg_data = {WR_CTRL, 16'hc511};
    148:op_reg_data = {WR_CTRL, 16'hc651};
    149:op_reg_data = {WR_CTRL, 16'hbf80};
    150:op_reg_data = {WR_CTRL, 16'hc710};
    151:op_reg_data = {WR_CTRL, 16'hb666};
    152:op_reg_data = {WR_CTRL, 16'hb8a5};
    153:op_reg_data = {WR_CTRL, 16'hb764};
    154:op_reg_data = {WR_CTRL, 16'hb97c};
    155:op_reg_data = {WR_CTRL, 16'hb3af};
    156:op_reg_data = {WR_CTRL, 16'hb497};
    157:op_reg_data = {WR_CTRL, 16'hb5ff};
    158:op_reg_data = {WR_CTRL, 16'hb0c5};
    159:op_reg_data = {WR_CTRL, 16'hb194};
    160:op_reg_data = {WR_CTRL, 16'hb20f};
    161:op_reg_data = {WR_CTRL, 16'hc45c};
    162:op_reg_data = {WR_CTRL, 16'hc064};
    163:op_reg_data = {WR_CTRL, 16'hc14b};
    164:op_reg_data = {WR_CTRL, 16'h8c00};
    165:op_reg_data = {WR_CTRL, 16'h863d};
    166:op_reg_data = {WR_CTRL, 16'h5000};
    167:op_reg_data = {WR_CTRL, 16'h51c8};
    168:op_reg_data = {WR_CTRL, 16'h5296};
    169:op_reg_data = {WR_CTRL, 16'h5300};
    170:op_reg_data = {WR_CTRL, 16'h5400};
    171:op_reg_data = {WR_CTRL, 16'h5500};
    172:op_reg_data = {WR_CTRL, 16'h5ac8};
    173:op_reg_data = {WR_CTRL, 16'h5b96};
    174:op_reg_data = {WR_CTRL, 16'h5c00};
    175:op_reg_data = {WR_CTRL, 16'hd382};
    176:op_reg_data = {WR_CTRL, 16'hc3ed};
    177:op_reg_data = {WR_CTRL, 16'h7f00};
    178:op_reg_data = {WR_CTRL, 16'hda08};
    179:op_reg_data = {WR_CTRL, 16'he51f};
    180:op_reg_data = {WR_CTRL, 16'he167};
    181:op_reg_data = {WR_CTRL, 16'he000};
    182:op_reg_data = {WR_CTRL, 16'hdd7f};
    183:op_reg_data = {WR_CTRL, 16'h0500};
    184:op_reg_data = {WR_CTRL, 16'hff01};
    185:op_reg_data = {WR_CTRL, 16'h243e};
    186:op_reg_data = {WR_CTRL, 16'h2538};
    187:op_reg_data = {WR_CTRL, 16'h2681};
     default:op_reg_data={WR_CTRL, 16'h0000};
    endcase      
end     
endmodule

module setup(
    input clk,//100MHZ
    input rst_n,
    output reg init_en,

    output reg ov_pwdn,
    output reg ov_rst
    );
    //parameter MS_CYC = 5;
    parameter MS_CYC = 50_000;
    //parameter MS_CYC = 100_000;
    reg [15:0] ms_cnt = 0;
    wire en_ms_cnt;         //毫秒计数使能
    wire ms_cnt_break;        //毫秒计数中断
    reg [4:0]  delay_cnt = 0;
    wire  en_delay_cnt ;    //延迟计数使能
    wire  delay_cnt_break;   //延迟计数中断
    reg [4:0] ms_delay;     //毫秒级延迟终点
    reg [(2-1):0]  task_cnt = 0;    //状态计数
    wire en_task_cnt;       //状态计数使能
    wire task_cnt_break;    //状态计数中断


    //ms计数时序，等同于分频
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            ms_cnt <= 0;
        end
        else if(en_ms_cnt)begin
        if(ms_cnt_break)
            ms_cnt <= 0;
        else
            ms_cnt <= ms_cnt + 1;
        end
    end

    assign en_ms_cnt = !init_en;       
    assign ms_cnt_break = en_ms_cnt && ms_cnt== MS_CYC-1; //100_000_000/50_000 = 2_000  
    //毫秒延迟时序
    always @(posedge clk or negedge rst_n) 
    begin 
        if (rst_n==0) begin
            delay_cnt <= 0; 
        end
        else if(en_delay_cnt) begin
            if(delay_cnt_break)
                delay_cnt <= 0; 
            else
                delay_cnt <= delay_cnt + 1'b1;
        end
    end
    assign en_delay_cnt = ms_cnt_break;
    assign delay_cnt_break = en_delay_cnt  && delay_cnt == ms_delay-1 ;
    //状态计数时序
    always @(posedge clk or negedge rst_n) begin 
        if (rst_n==0) begin
            task_cnt <= 0; 
    end
    else if(en_task_cnt) begin
        if(task_cnt_break)
            task_cnt <= 0; 
        else
            task_cnt <= task_cnt+1 ;
       end
    end
    assign en_task_cnt = delay_cnt_break;
    assign task_cnt_break = en_task_cnt  && task_cnt == (3)-1 ;

    always@(*)begin
        case(task_cnt)
            0:ms_delay = 10;    //从通电到唤醒间隔10ms
            1:ms_delay = 10;    //从唤醒到硬件复位间隔10ms
            2:ms_delay = 20;    //从硬件复位到开始配置间隔20ms
        //仿真用数据
        /*0:N = 1;
        1:N = 1;
        2:N = 1;*/
            default:;
        endcase
    end

//信号逻辑
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            ov_pwdn <= 1;
        end
        else if(en_task_cnt && task_cnt == 0)begin
            ov_pwdn <= 0;       //摄像头唤醒，进入工作状态
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            ov_rst <= 0;    
        end
        else if(en_task_cnt && task_cnt == 1)begin
            ov_rst <= 1;        //硬件复位拉高，复位完成
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            init_en <= 0;       //标志位置0，重新上电时重新执行初始化操作
        end
        else if(task_cnt_break)begin
            init_en <= 1;       //上电时序结束，开始配置寄存器
        end
    end
endmodule

module ov2640(
/* system interface */
    input clk,
    input rst_n,
    output finish,
    output init_en,
    output capture_state,
/* ov2640 interface */
    input pclk,
    output xclk,
    inout  sio_d,
    output sio_c,
    output ov_pwdn,
    output ov_rst,
    input [7:0] ov_data,       //来自摄像头的8位数据
    input  ov_href,
    input  ov_vsync,
    output [20-1:0] wr_addr,     //写寄存器地址
    output [12-1:0] wr_data,     //写寄存器数据
    output          wr_en       //写寄存器使能
    );
    
    wire clk_25m,clk_50m,clk_20m,clk_12m,clk_10m;
    wire [7:0] num_data;
    assign xclk = clk_25m;
    //clk_wiz_2 clk_inst_2(.clk_in1(clk),.clk_18m(clk_18m),.clk_100m(clk_100m));
    reg_config reg_init(
    .clk(clk),
    .rst_n(rst_n),
    .en(init_en),
    .finish(finish),
    .sio_d(sio_d),
    .sio_c(sio_c),
    .data_output(num_data),
    .read_state(state)
    );
    setup setup_init(
    .clk(clk),//100MHZ
    .rst_n(rst_n),
    .init_en(init_en),
    .ov_pwdn(ov_pwdn),
    .ov_rst(ov_rst)
    );
    clk_divider divider(
    .clk_100m(clk),
    .clk_50m(clk_50m),
    .clk_25m(clk_25m),
    .clk_20m(clk_20m),
    .clk_12m(clk_12m),
    .clk_10m(clk_10m)
    );
    
    ov_capture capture_inst(
    .pclk(pclk),
    .rst_n(rst_n),
    .href(ov_href),
    .vsync(ov_vsync),
    .data(ov_data),
    .rgb_data(wr_data),
    .ram_addr(wr_addr),
    .ram_en(wr_en),
    .data_state(capture_state)
    );
//    display_test tset_inst(
//    .clk(clk),
//    .data(test_data)
//        );
endmodule
