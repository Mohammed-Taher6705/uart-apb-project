module Top_module_TX# (
    parameter width = 16,
    parameter div = 16'd10417
)(
   input  wire       clk,
   input  wire       rst,    
   input  wire       arst,   
   input  wire       tx_en,
   input  wire [7:0] data,
   output wire       done,
   output wire       busy,
   output wire       tx
);

    // Internal signals
    wire tick;
    wire [3:0] idx;
    wire [9:0] frame_bits;
    wire load_frame;

    assign load_frame = tx_en && !busy;

    // Baud rate counter
    baud_counter_TX #(
        .width(width),
        .div(div)
    ) u_baud_counter (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .enable(tx_en || busy),
        .tick(tick)
    );

    // Bit selection for TX
    bit_select u_bit_select (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .tick(tick),
        .start(tx_en),
        .sel(idx),
        .done(done),
        .busy(busy)
    );

    // Frame loader: adds start/stop bits
    frame u_frame (
        .clk(clk),
        .rst_n(arst),   // async reset active low
        .rst(rst),      // sync reset active high
        .load(load_frame),
        .data(data),
        .frame(frame_bits)
    );

    // TX multiplexer
    Mux10x1 u_mux (
        .in(frame_bits),
        .sel(idx),
        .Tx(tx)
    );

endmodule
