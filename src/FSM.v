module FSM (
    input  clk,
    input  rst,   
    input  arst,   
    input  rx,
    input  rx_en,
    input  start_edge,
    input  tick,
    input  [7:0] data,      
    output reg kick,
    output reg baud_en,
    output reg shift_enable,
    output reg [3:0] bit_cnt, 
    output reg [7:0] data_out,
    output reg done,
    output reg busy,
    output reg error
);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] state;

always @(posedge clk or negedge arst) begin
    if (!arst) begin
        // Hard reset
        state        <= IDLE;
        bit_cnt      <= 4'd0;
        shift_enable <= 1'b0;
        baud_en      <= 1'b0;
        kick         <= 1'b0;
        done         <= 1'b0;
        busy         <= 1'b0;
        error        <= 1'b0;
        data_out     <= 8'd0;
    end else if (rst) begin
        // Soft reset
        state        <= IDLE;
        bit_cnt      <= 4'd0;
        shift_enable <= 1'b0;
        baud_en      <= 1'b0;
        kick         <= 1'b0;
        done         <= 1'b0;
        busy         <= 1'b0;
        error        <= 1'b0;
    end else begin
        // defaults
        shift_enable <= 1'b0;
        kick         <= 1'b0;

        case (state)
            IDLE: begin
                busy    <= 1'b0;
                baud_en <= 1'b0;
                done    <= 1'b0;
                error   <= 1'b0;

                if (rx_en && start_edge) begin
                    state    <= START;
                    busy     <= 1'b1;
                    baud_en  <= 1'b1;
                    kick     <= 1'b1;     // preload 1.5-bit delay
                    bit_cnt  <= 4'd0;
                end
            end

            START: begin
                if (tick) begin
                    shift_enable <= 1'b1;
                    bit_cnt <= 4'd1;
                    state   <= DATA;
                end
            end

            DATA: begin
                if (tick) begin
                    shift_enable <= 1'b1;

                    if (bit_cnt == 4'd7) begin
                        state <= STOP;
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end
            end

            STOP: begin
                if (tick) begin
                    if (rx == 1'b1) begin
                        data_out <= data;
                        done     <= 1'b1;
                        error    <= 1'b0;
                    end else begin
                        error <= 1'b1;
                    end
                    state    <= IDLE;
                    busy     <= 1'b0;
                    baud_en  <= 1'b0;
                end
            end
        endcase
    end
end

endmodule
