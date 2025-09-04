module bit_select 
(
    input clk,
    input rst,
    input arst,
    input tick,
    input start,
    output reg [3:0]sel,
    output reg done,
    output reg busy
);

always @(posedge clk or negedge arst or posedge rst) 
begin
    if(!arst)
    begin
        sel<=4'd0;
        busy <=0;
        done <=0;
    end
    else if(rst)
    begin
        sel<=4'd0;
        busy <=0;
        done <=0;
    end
    else if (start && !busy)
    begin
        done<=0;
        sel<=4'd0;
        busy <=1;
    end
    else if (tick && busy)
    begin
        if(sel == 4'd9)
        begin
        busy<=0;
        done<=1;
        end 
        else
        sel <= sel + 1'b1;
    end
end
    
    
endmodule
