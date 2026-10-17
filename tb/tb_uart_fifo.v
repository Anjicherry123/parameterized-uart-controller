`timescale 1ns / 1ps

module tb_uart_fifo;

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // --------------------------------
    // Testbench signals
    // --------------------------------
    reg clk;
    reg rst;

    reg wr_en;
    reg rd_en;

    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;

    wire full;
    wire empty;


    // --------------------------------
    // Instantiate FIFO
    // --------------------------------
    uart_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) uut (
        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .data_in(data_in),
        .data_out(data_out),

        .full(full),
        .empty(empty)
    );


    // --------------------------------
    // 100 MHz Clock
    // --------------------------------
    always #5 clk = ~clk;


    // --------------------------------
    // Test Sequence
    // --------------------------------
    initial begin

        // Initial values
        clk     = 1'b0;
        rst     = 1'b1;

        wr_en   = 1'b0;
        rd_en   = 1'b0;

        data_in = 8'h00;


        // --------------------------------
        // RESET
        // --------------------------------
        #100;

        rst = 1'b0;

        #20;


        // ==================================
        // TEST 1: Check EMPTY
        // ==================================
        $display("--------------------------------------");
        $display("TEST 1: FIFO EMPTY CHECK");
        $display("--------------------------------------");

        if (empty)
            $display("PASS: FIFO is EMPTY");
        else
            $display("FAIL: FIFO should be EMPTY");


        // ==================================
        // TEST 2: Write 0x41
        // ==================================
        $display("--------------------------------------");
        $display("TEST 2: WRITE 0x41");
        $display("--------------------------------------");

        data_in = 8'h41;
        wr_en   = 1'b1;

        #10;

        wr_en   = 1'b0;

        #10;


        // ==================================
        // TEST 3: Write 0x55
        // ==================================
        $display("--------------------------------------");
        $display("TEST 3: WRITE 0x55");
        $display("--------------------------------------");

        data_in = 8'h55;
        wr_en   = 1'b1;

        #10;

        wr_en   = 1'b0;

        #10;


        // ==================================
        // TEST 4: Read first byte
        // ==================================
        $display("--------------------------------------");
        $display("TEST 4: READ FIRST BYTE");
        $display("--------------------------------------");

        rd_en = 1'b1;

        #10;

        rd_en = 1'b0;

        #10;

        $display("DATA OUT = %h", data_out);


        if (data_out == 8'h41)
            $display("PASS: First FIFO data correct");
        else
            $display("FAIL: Expected 41, Got %h", data_out);


        // ==================================
        // TEST 5: Read second byte
        // ==================================
        $display("--------------------------------------");
        $display("TEST 5: READ SECOND BYTE");
        $display("--------------------------------------");

        rd_en = 1'b1;

        #10;

        rd_en = 1'b0;

        #10;

        $display("DATA OUT = %h", data_out);


        if (data_out == 8'h55)
            $display("PASS: Second FIFO data correct");
        else
            $display("FAIL: Expected 55, Got %h", data_out);


        // ==================================
        // TEST 6: Check EMPTY again
        // ==================================
        $display("--------------------------------------");
        $display("TEST 6: FIFO EMPTY AFTER READ");
        $display("--------------------------------------");

        if (empty)
            $display("PASS: FIFO is EMPTY");
        else
            $display("FAIL: FIFO should be EMPTY");


        // ==================================
        // TEST COMPLETE
        // ==================================
        $display("======================================");
        $display("UART FIFO TEST COMPLETED");
        $display("======================================");

        $finish;

    end

endmodule