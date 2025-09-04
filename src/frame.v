module frame (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rst,
    input  wire       load,        // load new byte
    input  wire [7:0] data,
    output reg [9:0]  frame        // [stop][data][start]
);
    always @(posedge clk or negedge rst_n or posedge rst) begin
        if (!rst_n) 
        begin
            frame  <= 10'b11_1111_1111;
        end
        else if(rst)
        begin
            frame  <= 10'b11_1111_1111;
        end else if (load) begin
            frame  <= {1'b1, data, 1'b0}; // stop, data, start LMB
        end
    end
endmodule
