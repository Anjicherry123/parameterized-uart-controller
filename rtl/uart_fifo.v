
module uart_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  wr_en,
    input  wire                  rd_en,

    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,

    output wire                  full,
    output wire                  empty
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            clog2 = i;
        end
    endfunction

    localparam ADDR_WIDTH = clog2(FIFO_DEPTH);
    localparam COUNT_WIDTH = clog2(FIFO_DEPTH + 1);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] count;

    wire do_write;
    wire do_read;

    assign full     = (count == FIFO_DEPTH);
    assign empty    = (count == 0);
    assign do_write = wr_en && !full;
    assign do_read  = rd_en && !empty;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
            data_out <= 0;
        end
        else begin

            // WRITE: store the input byte
            if (do_write) begin
                $display(
                    "FIFO WRITE: time=%0t addr=%0d data=%h",
                    $time, wr_ptr, data_in
                );

                mem[wr_ptr] <= data_in;

                if (wr_ptr == FIFO_DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // READ: registered output
            if (do_read) begin
                $display(
                    "FIFO READ: time=%0t addr=%0d data=%h",
                    $time, rd_ptr, mem[rd_ptr]
                );

                data_out <= mem[rd_ptr];

                if (rd_ptr == FIFO_DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            // Update occupancy
            case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                2'b11: count <= count;
                2'b00: count <= count;
            endcase
        end
    end

endmodule
