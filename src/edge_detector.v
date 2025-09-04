module edge_detector (
    input  clk,
    input  rst,   
    input  arst,   
    input  rx,
    output reg start_edge
);

    reg rx_p, rx_c; 

    always @(posedge clk or negedge arst) begin
        if (!arst) begin
            rx_p       <= 1'b1;
            rx_c       <= 1'b1;
            start_edge <= 1'b0;
        end else if (rst) begin
            rx_p       <= 1'b1;
            rx_c       <= 1'b1;
            start_edge <= 1'b0;
        end else begin
            rx_p       <= rx_c;
            rx_c       <= rx;
            start_edge <= (rx_c == 1'b0 && rx_p == 1'b1);
        end
    end
endmodule
