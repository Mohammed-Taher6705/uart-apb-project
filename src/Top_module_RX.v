module Top_module_RX #(
    parameter width    = 16,
    parameter div= 16'd10417
)(
    input  clk,
    input  rst,
    input  arst,
    input  rx_en,     
    input  rx,        
    output [7:0] data_out, 
    output done,       
    output busy,       
    output error       
);

    wire start_edge;
    wire tick;
    wire baud_en;
    wire kick;
    wire shift_enable;
    wire [7:0] shift_data;

    // --- Synchronizer (hard reset only) ---
    reg rx_sync1, rx_sync2;
    always @(posedge clk or negedge arst) begin
        if (!arst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end
    wire rx_clean = rx_sync2;

    // --- Edge detector ---
    edge_detector u_edge_detector (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .rx(rx_clean),
        .start_edge(start_edge)
    );

    // --- SIPO shift register ---
    SIPO_shift_register u_sipo (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .enable(shift_enable),
        .rx(rx_clean),
        .data(shift_data)
    );

    // --- Baud counter ---
    baud_counter_RX #(
        .div(div),
        .width(width)
    ) u_baud_counter (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .enable(baud_en),
        .kick(kick),
        .tick(tick)
    );

    // --- FSM ---
    FSM u_fsm (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .rx(rx_clean),          
        .rx_en(rx_en),
        .start_edge(start_edge),
        .tick(tick),
        .data(shift_data),
        .kick(kick),
        .baud_en(baud_en),
        .shift_enable(shift_enable),
        .data_out(data_out),
        .done(done),
        .busy(busy),
        .error(error)
    );

endmodule
