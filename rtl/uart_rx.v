module uart_rx #(
    parameter CLK_FREQ   = 100_000_000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 rx,

    output reg [DATA_WIDTH-1:0] rx_data,
    output reg                 rx_valid,
    output reg                 framing_error
);

    // --------------------------------
    // Clock count for one UART bit
    // --------------------------------
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

    // --------------------------------
    // States
    // --------------------------------
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] state;

    reg [31:0] clk_count;
    reg [3:0]  bit_count;

    reg [DATA_WIDTH-1:0] rx_shift_reg;

    // --------------------------------
    // UART RX
    // --------------------------------
    always @(posedge clk) begin

        if (rst) begin

            state         <= IDLE;
            clk_count     <= 32'd0;
            bit_count     <= 4'd0;
            rx_shift_reg  <= {DATA_WIDTH{1'b0}};

            rx_data       <= {DATA_WIDTH{1'b0}};
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;

        end

        else begin

            // Default
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;

            case (state)

                // -------------------------
                // IDLE
                // -------------------------
                IDLE: begin

                    clk_count <= 32'd0;
                    bit_count <= 4'd0;

                    // Detect start bit
                    if (rx == 1'b0) begin
                        state     <= START;
                        clk_count <= 32'd0;
                    end

                end


                // -------------------------
                // START BIT
                // -------------------------
                START: begin

                    if (clk_count == HALF_BIT - 1) begin

                        clk_count <= 32'd0;

                        // Confirm start bit
                        if (rx == 1'b0) begin
                            state     <= DATA;
                            bit_count <= 4'd0;
                        end
                        else begin
                            state <= IDLE;
                        end

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                // -------------------------
                // DATA BITS
                // -------------------------
                DATA: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 32'd0;

                        // Receive LSB first
                        rx_shift_reg[bit_count] <= rx;

                        if (bit_count == DATA_WIDTH - 1) begin
                            bit_count <= 4'd0;
                            state     <= STOP;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                        end

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                // -------------------------
                // STOP BIT
                // -------------------------
                STOP: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 32'd0;

                        // Stop bit must be HIGH
                        if (rx == 1'b1) begin

                            rx_data  <= rx_shift_reg;
                            rx_valid <= 1'b1;

                        end
                        else begin

                            framing_error <= 1'b1;

                        end

                        state <= IDLE;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule