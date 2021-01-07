`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/02/04
// Design Name: 
// Module Name: FSM
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

/////////////////////////////////////////
// 一段式
/////////////////////////////////////////
module FSM_OneAlways(
        input clk,
        input A,
        input reset,
        output z
    );
    parameter idle = 0;
    parameter start = 1;
    parameter stop = 2;
    reg [1:0] CurrentState;
    reg OutputReg;
    // 时序逻辑实现所有过程
    always @ (posedge clk)
    begin
        if(reset)begin
            CurrentState = idle;
            OutputReg = 1'b0;
        end
        else begin
            case(CurrentState)
            idle:begin
                if(A == 1'b0)begin
                    CurrentState = idle;
                    OutputReg = 1'b0;
                end else begin
                    CurrentState = start;
                    OutputReg = 1'b1;
                end
            end
            start:begin
                if(A == 1'b0)begin
                    CurrentState = stop;
                    OutputReg = 1'b0;
                end else begin
                    CurrentState = start;
                    OutputReg = 1'b1;
                end
            end
            stop:begin
                if(A == 1'b0)begin
                    CurrentState = idle;
                    OutputReg = 1'b0;
                end else begin
                    CurrentState = stop;
                    OutputReg = 1'b0;
                end
            end
            endcase
        end
    end
    
    assign z = OutputReg;
endmodule
//////////////////////////////////////////////
// 二段式
//////////////////////////////////////////////
module FSM_TwoAlways(
        input clk,
        input A,
        input reset,
        output z
    );
    parameter idle = 0;
    parameter start = 1;
    parameter stop = 2;
    reg [1:0] CurrentState, NextState;
    reg OutputReg;
    
    // 时序逻辑实现状态转移
    always @ (posedge clk)
    begin
        if(reset)begin
            CurrentState <= idle;
        end
        else begin
            CurrentState <= NextState;
        end
    end
    // 组合逻辑描述状态转移规律和输出规律
    always @ (CurrentState)
    begin
        if(reset)begin
            NextState = idle;
            OutputReg = 1'b0;
        end
        else begin
            case(CurrentState)
            idle:begin
                if(A == 1'b0)begin
                    NextState = idle;
                    OutputReg = 1'b0;
                end else begin
                    NextState = start;
                    OutputReg = 1'b1;
                end
            end
            start:begin
                if(A == 1'b0)begin
                    NextState = stop;
                    OutputReg = 1'b0;
                end else begin
                    NextState = start;
                    OutputReg = 1'b1;
                end
            end
            stop:begin
                if(A == 1'b0)begin
                    NextState = idle;
                    OutputReg = 1'b0;
                end else begin
                    NextState = stop;
                    OutputReg = 1'b0;
                end
            end
            endcase
        end
    end
endmodule
///////////////////////////////////////////
// 三段式
///////////////////////////////////////////
module FSM_ThreeAlways(
        input clk,
        input A,
        input reset,
        output z
    );
    parameter idle = 0;
    parameter start = 1;
    parameter stop = 2;
    reg [1:0] CurrentState, NextState;
    reg OutputReg;
    // 时序逻辑实现状态转移
    always @ (posedge clk)
    begin
        if(reset)begin
            CurrentState <= idle;
        end
        else begin
            CurrentState <= NextState;
        end
    end
    
    // 组合逻辑描述状态转移规律
    always @ (CurrentState)
    begin
        if(reset)begin
            NextState = idle;
        end
        else begin
            case(CurrentState)
            idle:if(A == 1'b0)begin
                    NextState = idle;
                end else begin
                    NextState = start;
                end
            start:if(A == 1'b0)begin
                    NextState = stop;
                end else begin
                    NextState = start;
                end
            stop:if(A == 1'b0)begin
                    NextState = idle;
                end else begin
                    NextState = stop;
                end
            endcase
        end
    end
    
    ///////////////////////////////////////////////////////
    // 以下两种输出方式任选其一
    ///////////////////////////////////////////////////////
    // 使用组合逻辑描述输出
    always @ (CurrentState)
    begin
        if(reset)begin
            OutputReg = 1'b0;
        end
        else begin
            case(CurrentState)
            idle:if(A == 1'b0)
                    OutputReg = 1'b0;
                else
                    OutputReg = 1'b1;
            start:if(A == 1'b0)
                    OutputReg = 1'b0;
                else
                    OutputReg = 1'b1;
            stop:if(A == 1'b0) 
                    OutputReg = 1'b0;
                 else 
                    OutputReg = 1'b0;
            endcase
        end
    end
    
    // 使用时序逻辑描述输出
    always @ (posedge clk)
    begin
        if(reset)begin
            OutputReg <= 1'b0;
        end
        else begin
            case(NextState)         // 根据次态寄存器NextState判断
            idle:if(A == 1'b0)
                    OutputReg <= 1'b0;
                else
                    OutputReg <= 1'b1;
            start:if(A == 1'b0)
                    OutputReg <= 1'b0;
                else
                    OutputReg <= 1'b1;
            stop:if(A == 1'b0) 
                    OutputReg <= 1'b0;
                 else 
                    OutputReg <= 1'b0;
            endcase
        end
    end
endmodule