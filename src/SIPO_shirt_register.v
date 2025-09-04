module SIPO_shift_register (
    input clk,
    input rst, 
    input arst,
    input enable,
    input rx,
    output reg [7:0] data
);

always @(posedge clk or negedge arst) begin
    if (!arst)
        data <= 8'd0;
    else if (rst)
        data <= 8'd0;
    else if (enable) begin
        data <= {rx, data[7:1]};   // shift right, LSB-first
    end
end

endmodule
