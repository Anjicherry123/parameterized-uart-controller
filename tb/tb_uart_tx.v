`timescale 1ns / 1ps

module tb_uart_tx;

    parameter DATA_WIDTH = 8;

    reg clk;
    reg rst;
    reg baud_tick;

    reg [DATA_WIDTH-1:0] tx_data;
    reg tx_start;

    wire tx;
    wire tx_busy;
    wire tx_done;

    integer baud_counter;

    // --------------------------------
    // UART TX
    // --------------------------------
    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // --------------------------------
    // 100 MHz Clock
    // --------------------------------
    always #5 clk = ~clk;

    // --------------------------------
    // 115200 Baud Tick
    // --------------------------------
    always @(posedge clk) begin

        if (rst) begin
            baud_counter <= 0;
            baud_tick    <= 1'b0;
        end
        else begin

            if (baud_counter == 867) begin
                baud_counter <= 0;
                baud_tick    <= 1'b1;
            end
            else begin
                baud_counter <= baud_counter + 1;
                baud_tick    <= 1'b0;
            end

        end

    end

    // --------------------------------
    // Test
    // --------------------------------
    initial begin

        clk      = 1'b0;
        rst      = 1'b1;
        tx_data  = 8'h00;
        tx_start = 1'b0;

        // Reset
        #100;
        rst = 1'b0;

        // Wait
        #100;

        // Send ASCII 'A'
        tx_data  = 8'h41;
        tx_start = 1'b1;

        #10;
        tx_start = 1'b0;

        // Wait for complete UART frame
        #100000;

        $display("================================");
        $display("UART TX TEST COMPLETE");
        $display("TX DONE = %b", tx_done);
        $display("================================");

        $finish;

    end

endmodule