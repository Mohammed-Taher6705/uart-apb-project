module APB #(
    parameter BAUD_DIV   = 16'd10417,
    parameter BAUD_WIDTH = 16
)(
    input         PCLK,
    input         PRESETn,
    input  [31:0] PADDR,
    input         PSEL,
    input         PENABLE,
    input         PWRITE,
    input  [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output reg    PREADY,
    input  uart_rx,
    output uart_tx
);

    localparam ADDR_CTRL   = 3'h0;
    localparam ADDR_STATS  = 3'h1;
    localparam ADDR_TXDATA = 3'h2;
    localparam ADDR_RXDATA = 3'h3;
    localparam ADDR_BAUDIV = 3'h4;

    wire [2:0] addr_word = PADDR[4:2];

    reg tx_en, rx_en;
    reg tx_rst, rx_rst;
    reg [7:0] tx_data_reg;
    reg [7:0] rx_data_reg;
    reg [BAUD_WIDTH-1:0] bauddiv_reg;
    reg rx_valid;
    reg rx_frame_error;
    reg tx_complete;

    wire tx_done, tx_busy;
    wire rx_done, rx_busy, rx_error;
    wire [7:0] rx_data_wire;

    wire apb_write = PSEL && PENABLE && PWRITE && PREADY;
    wire apb_read  = PSEL && PENABLE && !PWRITE && PREADY;

    reg tx_start_reg;
    wire tx_start = tx_start_reg;

    // Detect reset edge for debug
    reg presetn_prev;
    reg rx_rst_prev;
    wire presetn_fall = presetn_prev && !PRESETn;
    wire rx_rst_pulse = rx_rst && !rx_rst_prev;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_start_reg <= 1'b0;
            presetn_prev <= 1'b0;
            rx_rst_prev  <= 1'b0;
        end else begin
            tx_start_reg <= apb_write && (addr_word == ADDR_TXDATA);
            presetn_prev <= PRESETn;
            rx_rst_prev  <= rx_rst;
        end
    end

    // Debug: Print only on reset edge or single rx_rst pulse
    always @(posedge PCLK) begin
        if (tx_start && tx_en) $display("[%0t] TX Start: tx_data_reg=%h", $time, tx_data_reg);
        if (rx_done) $display("[%0t] RX Done: rx_data_wire=%h, rx_error=%b", $time, rx_data_wire, rx_error);
        if (rx_done && !rx_error && !rx_valid) $display("[%0t] Setting rx_valid=1", $time);
        if (rx_valid && (apb_read && addr_word == ADDR_RXDATA)) $display("[%0t] Clearing rx_valid on RXDATA read", $time);
        if (presetn_fall || rx_rst_pulse) $display("[%0t] Clearing rx_valid on reset", $time);
        if (apb_read && addr_word == ADDR_STATS) $display("[%0t] STATUS Read: PRDATA=%h, rx_valid=%b", $time, PRDATA, rx_valid);
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_en          <= 1'b0;
            rx_en          <= 1'b0;
            tx_rst         <= 1'b0;
            rx_rst         <= 1'b0;
            tx_data_reg    <= 8'h00;
            rx_data_reg    <= 8'h00;
            bauddiv_reg    <= BAUD_DIV[BAUD_WIDTH-1:0];
            rx_valid       <= 1'b0;
            rx_frame_error <= 1'b0;
            tx_complete    <= 1'b0;
        end else begin
            tx_rst <= 1'b0;
            rx_rst <= 1'b0;

            if (apb_write) begin
                case (addr_word)
                    ADDR_CTRL: begin
                        tx_en <= PWDATA[0];
                        rx_en <= PWDATA[1];
                        if (PWDATA[2]) tx_rst <= 1'b1;
                        if (PWDATA[3]) rx_rst <= 1'b1;
                    end
                    ADDR_TXDATA: begin
                        tx_data_reg <= PWDATA[7:0];
                    end
                    ADDR_BAUDIV: begin
                        bauddiv_reg <= PWDATA[BAUD_WIDTH-1:0];
                    end
                endcase
            end

            if (tx_start && tx_en) begin
                tx_complete <= 1'b0;
            end else if (tx_done) begin
                tx_complete <= 1'b1;
            end

            if (rx_done && !rx_error && !rx_valid) begin
                rx_data_reg <= rx_data_wire;
                rx_valid    <= 1'b1;
            end else if (rx_done && rx_error) begin
                rx_frame_error <= 1'b1;
            end

            if (apb_read && (addr_word == ADDR_RXDATA)) begin
                rx_valid       <= 1'b0;
                rx_frame_error <= 1'b0;
            end

            if (tx_rst) begin
                tx_complete <= 1'b0;
            end
            if (rx_rst) begin
                rx_valid       <= 1'b0;
                rx_frame_error <= 1'b0;
            end
        end
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 32'h0;
            PREADY <= 1'b0;
        end else begin
            PREADY <= PSEL && PENABLE;
            PRDATA <= 32'h0;
            if (PSEL && PENABLE && !PWRITE) begin
                case (addr_word)
                    ADDR_CTRL:   PRDATA <= {28'h0, rx_rst, tx_rst, rx_en, tx_en};
                    ADDR_STATS:  PRDATA <= {27'h0, rx_frame_error, rx_valid, tx_complete, rx_busy, tx_busy};
                    ADDR_TXDATA: PRDATA <= {24'h0, tx_data_reg};
                    ADDR_RXDATA: PRDATA <= {24'h0, rx_data_reg};
                    ADDR_BAUDIV: PRDATA <= {{(32-BAUD_WIDTH){1'b0}}, bauddiv_reg};
                endcase
            end
        end
    end

    Top_module_TX #(
        .width(BAUD_WIDTH),
        .div(16)
    ) u_tx (
        .clk      (PCLK),
        .rst      (tx_rst),
        .arst     (PRESETn),
        .tx_en    (tx_start && tx_en),
        .data     (tx_data_reg),
        .done     (tx_done),
        .busy     (tx_busy),
        .tx       (uart_tx)
    );

    Top_module_RX #(
        .width(BAUD_WIDTH),
        .div(16)
    ) u_rx (
        .clk      (PCLK),
        .rst      (rx_rst),
        .arst     (PRESETn),
        .rx_en    (rx_en),
        .rx       (uart_rx),
        .data_out (rx_data_wire),
        .done     (rx_done),
        .busy     (rx_busy),
        .error    (rx_error)
    );

endmodule
