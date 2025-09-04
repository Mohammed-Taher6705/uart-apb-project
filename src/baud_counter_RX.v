module baud_counter_RX #(parameter div = 16'd10417, parameter width = 16)
(
    input clk,
    input rst,    
    input arst,   
    input enable,
    input kick,
    output reg tick
);

reg [width-1:0] cnt;

always @(posedge clk or negedge arst) begin
    if (!arst) begin
        cnt  <= div;
        tick <= 0;
    end else if (rst) begin
        cnt  <= div;
        tick <= 0;
    end else if (!enable) begin
        cnt  <= div;
        tick <= 0; 
    end else if (kick) begin
        cnt  <= div + (div >> 1);
        tick <= 0;
    end else if (cnt == 0) begin
        tick <= 1;
        cnt  <= div;
    end else begin
        cnt  <= cnt - 1;
        tick <= 0;
    end
end
    
endmodule
