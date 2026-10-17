
module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire baud_tick,

    input wire [DATA_WIDTH-1:0] tx_data,
    input wire tx_start,

    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

    localparam IDLE       = 3'd0;
    localparam WAIT_START = 3'd1;
    localparam START_BIT  = 3'd2;
    localparam DATA_BITS  = 3'd3;
    localparam STOP_BIT   = 3'd4;

    reg [2:0] state;
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [$clog2(DATA_WIDTH)-1:0] bit_count;

    always @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            tx           <= 1'b1;
            tx_busy      <= 1'b0;
            tx_done      <= 1'b0;
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            bit_count    <= 0;
        end else begin
            tx_done <= 1'b0;

            case (state)

                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;

                    if (tx_start) begin
                        tx_shift_reg <= tx_data;
                        bit_count <= 0;
                        tx_busy <= 1'b1;
                        state <= WAIT_START;

                        $display(
                            "UART TX ACCEPT: time=%0t data=%h",
                            $time, tx_data
                        );
                    end
                end

                WAIT_START: begin
                    tx <= 1'b1;

                    if (baud_tick) begin
                        tx <= 1'b0;
                        state <= START_BIT;
                    end
                end

                START_BIT: begin
                    tx <= 1'b0;

                    if (baud_tick) begin
                        tx <= tx_shift_reg[0];
                        tx_shift_reg <= tx_shift_reg >> 1;
                        bit_count <= 1;
                        state <= DATA_BITS;
                    end
                end

                DATA_BITS: begin
                    if (baud_tick) begin
                        if (bit_count == DATA_WIDTH-1) begin
                            tx <= 1'b1;
                            state <= STOP_BIT;
                        end else begin
                            tx <= tx_shift_reg[0];
                            tx_shift_reg <= tx_shift_reg >> 1;
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end

                STOP_BIT: begin
                    tx <= 1'b1;

                    if (baud_tick) begin
                        tx_done <= 1'b1;
                        tx_busy <= 1'b0;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    tx_done <= 1'b0;
                end

            endcase
        end
    end

endmodule
