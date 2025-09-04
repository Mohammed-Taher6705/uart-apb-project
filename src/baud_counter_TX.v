module baud_counter_TX #(parameter width = 16, parameter div =16'd10417
)(
    input clk,
    input rst,
    input arst,
    input enable,
    output reg tick
);
 reg [width-1:0] cnt;
always@(posedge clk or  negedge arst)
begin
    if(!arst)
    begin
        cnt <= div;
        tick <=0;
    end
    else if(rst)
    begin
        cnt <= div;
        tick <=0;
    end
    else if(enable)
    begin
        if(cnt == 0)
        begin
            cnt <= div;
            tick <=1;
        end
        else
        begin
            cnt<=cnt-1;
            tick<=0;
        end
    end
    else
    begin
        cnt<=div;
        tick<=0;
    end

end
endmodule
