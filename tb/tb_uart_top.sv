`timescale 1ns / 1ps

module tb_uart_top;

    parameter DATA_WIDTH = 8;

    // --------------------------------
    // Clock and Reset
    // --------------------------------
    reg clk;
    reg rst;

    // --------------------------------
    // TX Interface
    // --------------------------------
    reg  [DATA_WIDTH-1:0] tx_data;
    reg                   tx_start;

    wire                  tx;
    wire                  tx_busy;
    wire                  tx_done;

    // --------------------------------
    // RX Interface
    // --------------------------------
    wire                  rx;
    wire [DATA_WIDTH-1:0] rx_data;
    wire                  rx_valid;
    wire                  framing_error;


    // --------------------------------
    // UART LOOPBACK
    //
    // TX is directly connected to RX
    // --------------------------------
    assign rx = tx;


    // --------------------------------
    // Instantiate UART TOP
    // --------------------------------
    uart_top #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115200),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),

        // TX
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done),

        // RX
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error)
    );


    // --------------------------------
    // 100 MHz Clock
    // Period = 10 ns
    // --------------------------------
    always #5 clk = ~clk;


    // --------------------------------
    // Test Sequence
    // --------------------------------
    initial begin

        // Initial values
        clk      = 1'b0;
        rst      = 1'b1;
        tx_data  = 8'h00;
        tx_start = 1'b0;


        // --------------------------------
        // RESET
        // --------------------------------
        #100;

        rst = 1'b0;


        // --------------------------------
        // Wait after reset
        // --------------------------------
        #100;


        // ==================================
        // TEST 1
        // Send 0x41 = ASCII 'A'
        // ==================================
        $display("======================================");
        $display("TEST 1: Sending 0x41");
        $display("======================================");

        tx_data  = 8'h41;
        tx_start = 1'b1;

        #10;

        tx_start = 1'b0;


        // --------------------------------
        // Wait for complete transmission
        // --------------------------------
        #100000;


        // ==================================
        // TEST 2
        // Send 0x55
        // ==================================
        $display("======================================");
        $display("TEST 2: Sending 0x55");
        $display("======================================");

        tx_data  = 8'h55;
        tx_start = 1'b1;

        #10;

        tx_start = 1'b0;


        // --------------------------------
        // Wait for second transmission
        // --------------------------------
        #100000;


        // --------------------------------
        // Finish
        // --------------------------------
        $display("======================================");
        $display("UART LOOPBACK TEST COMPLETED");
        $display("======================================");

        $finish;

    end


    // --------------------------------
    // Monitor RX
    // --------------------------------
    always @(posedge clk) begin

        if (rx_valid) begin

            $display(
                "RX VALID: Time = %0t ns, Received Data = %h",
                $time,
                rx_data
            );

        end

        if (framing_error) begin

            $display(
                "FRAMING ERROR: Time = %0t ns",
                $time
            );

        end

    end


    // --------------------------------
    // Check received data
    // --------------------------------
    always @(posedge rx_valid) begin

        if (rx_data == 8'h41) begin

            $display("PASS: Received 0x41 correctly");

        end
        else if (rx_data == 8'h55) begin

            $display("PASS: Received 0x55 correctly");

        end
        else begin

            $display(
                "FAIL: Unexpected received data = %h",
                rx_data
            );

        end

    end

endmodule