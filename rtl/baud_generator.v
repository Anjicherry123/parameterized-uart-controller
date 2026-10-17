`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.09.2026 12:42:23
// Design Name: 
// Module Name: baud_generator
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


module baud_generator #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire rst,
    output reg  baud_tick
);

    localparam integer BAUD_COUNT = CLK_FREQ / BAUD_RATE;

    integer count;

    always @(posedge clk) begin
        if (rst) begin
            count     <= 0;
            baud_tick <= 1'b0;
        end
        else begin
            if (count == BAUD_COUNT - 1) begin
                count     <= 0;
                baud_tick <= 1'b1;
            end
            else begin
                count     <= count + 1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule
