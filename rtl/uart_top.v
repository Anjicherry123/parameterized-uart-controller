
module uart_top #(
    parameter CLK_FREQ   = 100_000_000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst,

    input wire [DATA_WIDTH-1:0] tx_data,
    input wire tx_start,

    output wire tx_busy,
    output wire tx_done,
    output wire tx,

    input wire rx,

    output reg [DATA_WIDTH-1:0] rx_data,
    output reg rx_valid,
    output wire framing_error,

    output wire tx_fifo_full,
    output wire tx_fifo_empty,
    output wire rx_fifo_full,
    output wire rx_fifo_empty
);

    // Baud generator
    wire baud_tick;

    baud_generator #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud_generator (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );

    // TX FIFO
    wire [DATA_WIDTH-1:0] tx_fifo_data_out;
    reg tx_fifo_rd_en;

    wire tx_fifo_wr_en;
    assign tx_fifo_wr_en = tx_start && !tx_fifo_full;

    uart_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_tx_fifo (
        .clk(clk),
        .rst(rst),
        .wr_en(tx_fifo_wr_en),
        .rd_en(tx_fifo_rd_en),
        .data_in(tx_data),
        .data_out(tx_fifo_data_out),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );

    // UART transmitter
    reg [DATA_WIDTH-1:0] tx_data_internal;
    reg tx_start_internal;

    wire tx_busy_internal;
    wire tx_done_internal;

    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_uart_tx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_data(tx_data_internal),
        .tx_start(tx_start_internal),
        .tx(tx),
        .tx_busy(tx_busy_internal),
        .tx_done(tx_done_internal)
    );

    assign tx_busy = tx_busy_internal;
    assign tx_done = tx_done_internal;

    // TX FIFO controller
    localparam TX_IDLE    = 3'd0;
    localparam TX_READ    = 3'd1;
    localparam TX_CAPTURE = 3'd2;
    localparam TX_START   = 3'd3;
    localparam TX_WAIT    = 3'd4;

    reg [2:0] tx_ctrl_state;

    always @(posedge clk) begin
        if (rst) begin
            tx_ctrl_state     <= TX_IDLE;
            tx_fifo_rd_en     <= 1'b0;
            tx_start_internal <= 1'b0;
            tx_data_internal  <= {DATA_WIDTH{1'b0}};
        end else begin
            tx_fifo_rd_en     <= 1'b0;
            tx_start_internal <= 1'b0;

            case (tx_ctrl_state)

                TX_IDLE: begin
                    if (!tx_fifo_empty && !tx_busy_internal) begin
                        tx_fifo_rd_en <= 1'b1;
                        tx_ctrl_state <= TX_READ;
                    end
                end

                TX_READ: begin
                    tx_ctrl_state <= TX_CAPTURE;
                end

                TX_CAPTURE: begin
                    tx_data_internal <= tx_fifo_data_out;
                    tx_ctrl_state <= TX_START;

                    $display("TX CAPTURE: time=%0t data=%h",
                             $time, tx_fifo_data_out);
                end

                TX_START: begin
                    tx_start_internal <= 1'b1;
                    tx_ctrl_state <= TX_WAIT;

                    $display("TX START: time=%0t data=%h",
                             $time, tx_data_internal);
                end

                TX_WAIT: begin
                    if (tx_busy_internal) begin
                        if (tx_done_internal)
                            tx_ctrl_state <= TX_IDLE;
                    end
                end

                default: begin
                    tx_ctrl_state <= TX_IDLE;
                end

            endcase
        end
    end

    // UART receiver
    wire [DATA_WIDTH-1:0] rx_data_internal;
    wire rx_valid_internal;
    wire framing_error_internal;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(rx_data_internal),
        .rx_valid(rx_valid_internal),
        .framing_error(framing_error_internal)
    );

    assign framing_error = framing_error_internal;

    // RX FIFO
    wire [DATA_WIDTH-1:0] rx_fifo_data_out;
    reg rx_fifo_wr_en;
    reg rx_fifo_rd_en;

    uart_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_rx_fifo (
        .clk(clk),
        .rst(rst),
        .wr_en(rx_fifo_wr_en),
        .rd_en(rx_fifo_rd_en),
        .data_in(rx_data_internal),
        .data_out(rx_fifo_data_out),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty)
    );

    // RX FIFO controller
    localparam RX_IDLE    = 2'd0;
    localparam RX_READ    = 2'd1;
    localparam RX_CAPTURE = 2'd2;

    reg [1:0] rx_ctrl_state;

    always @(posedge clk) begin
        if (rst) begin
            rx_fifo_wr_en <= 1'b0;
            rx_fifo_rd_en <= 1'b0;
            rx_ctrl_state <= RX_IDLE;
            rx_data       <= {DATA_WIDTH{1'b0}};
            rx_valid      <= 1'b0;
        end else begin
            rx_fifo_wr_en <= 1'b0;
            rx_fifo_rd_en <= 1'b0;
            rx_valid      <= 1'b0;

            // Queue received data
            if (rx_valid_internal && !rx_fifo_full) begin
                rx_fifo_wr_en <= 1'b1;
                $display("RX FIFO QUEUE: time=%0t data=%h",
                         $time, rx_data_internal);
            end

            case (rx_ctrl_state)

                RX_IDLE: begin
                    if (!rx_fifo_empty) begin
                        rx_fifo_rd_en <= 1'b1;
                        rx_ctrl_state <= RX_READ;
                    end
                end

                RX_READ: begin
                    rx_ctrl_state <= RX_CAPTURE;
                end

                RX_CAPTURE: begin
                    rx_data <= rx_fifo_data_out;
                    rx_valid <= 1'b1;
                    rx_ctrl_state <= RX_IDLE;

                    $display("RX OUTPUT: time=%0t data=%h",
                             $time, rx_fifo_data_out);
                end

                default: begin
                    rx_ctrl_state <= RX_IDLE;
                end

            endcase
        end
    end

endmodule
