`timescale 1ns / 1ps

module tb_uart_rx;

    parameter DATA_WIDTH = 8;

    // --------------------------------
    // Testbench signals
    // --------------------------------
    reg clk;
    reg rst;
    reg rx;

    wire [DATA_WIDTH-1:0] rx_data;
    wire rx_valid;
    wire framing_error;

    integer bit_count;


    // --------------------------------
    // UART RX
    // --------------------------------
    uart_rx #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115200),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
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
    // UART Bit Task
    //
    // 115200 baud
    // 1 bit ? 8.68 us
    // --------------------------------
    task send_bit;
        input bit_value;

        begin
            rx = bit_value;

            #8680;
        end

    endtask


    // --------------------------------
    // Send one UART byte
    // --------------------------------
    task send_uart_byte;
        input [DATA_WIDTH-1:0] data;

        integer i;

        begin

            // START BIT
            send_bit(1'b0);

            // DATA BITS - LSB first
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                send_bit(data[i]);
            end

            // STOP BIT
            send_bit(1'b1);

        end

    endtask


    // --------------------------------
    // Test Sequence
    // --------------------------------
    initial begin

        // Initial values
        clk = 1'b0;
        rst = 1'b1;
        rx  = 1'b1;


        // --------------------------------
        // Reset
        // --------------------------------
        #100;

        rst = 1'b0;


        // --------------------------------
        // Wait after reset
        // --------------------------------
        #100;


        // --------------------------------
        // Send 0x41 = ASCII 'A'
        // --------------------------------
        $display("--------------------------------------");
        $display("Sending UART data: 0x41");
        $display("--------------------------------------");

        send_uart_byte(8'h41);


        // --------------------------------
        // Wait
        // --------------------------------
        #10000;


        // --------------------------------
        // Send 0x55
        // --------------------------------
        $display("--------------------------------------");
        $display("Sending UART data: 0x55");
        $display("--------------------------------------");

        send_uart_byte(8'h55);


        // --------------------------------
        // Wait
        // --------------------------------
        #10000;


        // --------------------------------
        // Finish
        // --------------------------------
        $display("--------------------------------------");
        $display("UART RX TEST COMPLETED");
        $display("--------------------------------------");

        $finish;

    end


    // --------------------------------
    // Monitor received data
    // --------------------------------
    always @(posedge clk) begin

        if (rx_valid) begin

            $display(
                "RX VALID: Time = %0t ns, Data = %h",
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

endmodule