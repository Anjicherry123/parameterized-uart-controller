`timescale 1ns / 1ps

module tb_uart_top_fifo;

    parameter CLK_FREQ   = 100_000_000;
    parameter BAUD_RATE  = 115200;
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // =========================================================
    // CLOCK AND RESET
    // =========================================================

    reg clk;
    reg rst;

    // =========================================================
    // TX INTERFACE
    // =========================================================

    reg  [DATA_WIDTH-1:0] tx_data;
    reg                   tx_start;

    wire                  tx_busy;
    wire                  tx_done;

    // =========================================================
    // UART SERIAL
    // =========================================================

    wire tx;
    wire rx;

    // UART loopback
    assign rx = tx;

    // =========================================================
    // RX INTERFACE
    // =========================================================

    wire [DATA_WIDTH-1:0] rx_data;
    wire                  rx_valid;
    wire                  framing_error;

    // =========================================================
    // FIFO STATUS
    // =========================================================

    wire tx_fifo_full;
    wire tx_fifo_empty;

    wire rx_fifo_full;
    wire rx_fifo_empty;

    // =========================================================
    // EXPECTED DATA
    // =========================================================

    reg [7:0] expected_data [0:3];

    integer rx_count;
    integer errors;


    // =========================================================
    // UART TOP
    // =========================================================

    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) uut (

        .clk(clk),
        .rst(rst),

        .tx_data(tx_data),
        .tx_start(tx_start),

        .tx_busy(tx_busy),
        .tx_done(tx_done),

        .tx(tx),
        .rx(rx),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error),

        .tx_fifo_full(tx_fifo_full),
        .tx_fifo_empty(tx_fifo_empty),

        .rx_fifo_full(rx_fifo_full),
        .rx_fifo_empty(rx_fifo_empty)
    );


    // =========================================================
    // 100 MHz CLOCK
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // RX MONITOR
    //
    // Check after the design's nonblocking assignments
    // have settled.
    // =========================================================

    always @(posedge clk) begin

        #2;

        if (rx_valid) begin

            $display("");
            $display("--------------------------------------");
            $display(
                "RX VALID: Time = %0t ns",
                $time
            );

            $display(
                "Expected Data = %h",
                expected_data[rx_count]
            );

            $display(
                "Received Data = %h",
                rx_data
            );

            $display("--------------------------------------");


            if (rx_count < 4) begin

                if (rx_data === expected_data[rx_count]) begin

                    $display(
                        "PASS: Received 0x%h correctly",
                        rx_data
                    );

                end

                else begin

                    $display(
                        "FAIL: Expected 0x%h, Received 0x%h",
                        expected_data[rx_count],
                        rx_data
                    );

                    errors = errors + 1;

                end

            end

            else begin

                $display("FAIL: Unexpected extra RX data");

                errors = errors + 1;

            end


            rx_count = rx_count + 1;

        end

    end


    // =========================================================
    // SEND BYTE TASK
    // =========================================================

    task send_byte;

        input [7:0] data;

        begin

            // Wait for TX FIFO to have space
            wait (tx_fifo_full == 1'b0);

            @(posedge clk);

            tx_data  <= data;
            tx_start <= 1'b1;

            @(posedge clk);

            tx_start <= 1'b0;

            $display("");
            $display("======================================");
            $display(
                "Sending UART data: 0x%h",
                data
            );
            $display("======================================");

        end

    endtask


    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        // --------------------------------
        // Initial values
        // --------------------------------

        clk      = 1'b0;
        rst      = 1'b1;

        tx_data  = 8'h00;
        tx_start = 1'b0;

        rx_count = 0;
        errors   = 0;


        // --------------------------------
        // Expected data
        // --------------------------------

        expected_data[0] = 8'h41;
        expected_data[1] = 8'h55;
        expected_data[2] = 8'hA5;
        expected_data[3] = 8'h3C;


        // --------------------------------
        // Reset
        // --------------------------------

        #100;

        rst = 1'b0;

        #100;


        // =====================================================
        // SEND FOUR BYTES
        // =====================================================

        send_byte(8'h41);

        send_byte(8'h55);

        send_byte(8'hA5);

        send_byte(8'h3C);


        // =====================================================
        // WAIT FOR UART TRANSMISSION
        // =====================================================

        $display("");
        $display("--------------------------------------");
        $display("Waiting for UART transmission...");
        $display("--------------------------------------");
        $display("");

        #450000;


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("======================================");
        $display("FINAL UART FIFO TEST RESULT");
        $display("======================================");

        $display(
            "Expected bytes : 4"
        );

        $display(
            "Received bytes : %0d",
            rx_count
        );

        $display(
            "Errors         : %0d",
            errors
        );


        if ((errors == 0) && (rx_count == 4)) begin

            $display("");
            $display(
                "PASS: ALL 4 BYTES RECEIVED CORRECTLY"
            );

        end

        else begin

            $display("");
            $display(
                "FAIL: UART FIFO LOOPBACK TEST"
            );

        end


        $display("======================================");
        $display("UART FIFO LOOPBACK TEST COMPLETED");
        $display("======================================");

        $finish;

    end

endmodule