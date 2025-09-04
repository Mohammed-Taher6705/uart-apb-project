`timescale 1ns/1ps

module Rx_TB;
    // Parameters
    localparam width       = 16;
    localparam div         = 16'd10417;
    localparam CLK_PERIOD  = 10;
    localparam BIT_PERIOD  = div * CLK_PERIOD;

    reg        clk;
    reg        rst;
    reg        arst;
    reg        rx_en;
    reg        rx;
    wire [7:0] data_out;
    wire       done;
    wire       busy;
    wire       error;

    Top_module_RX #(
        .div(div),
        .width(width)
    ) uut (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .rx_en(rx_en),
        .rx(rx),
        .data_out(data_out),
        .done(done),
        .busy(busy),
        .error(error)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // Task to send one UART byte (LSB first)
    task send_uart_byte(input [7:0] d);
        integer i;
    begin
        $display("[%0t] Sending UART byte: %02h", $time, d);

        // --- start bit ---
        rx <= 1'b0;  
        #(BIT_PERIOD+BIT_PERIOD/2);

        // --- data bits ---
        for (i=0; i<8; i=i+1) begin
            rx <= d[i];
            #(BIT_PERIOD);
        end

        // --- stop bit ---
        rx <= 1'b1;
        #(BIT_PERIOD);
    end
    endtask

    // Task for checking results
    task check_result(input [7:0] expected);
    begin
        wait(done);
        if (data_out === expected && error == 0) begin
            $display("[%0t] RX Done: Got=%02h Expected=%02h  PASS", 
                     $time, data_out, expected);
        end else begin
            $display("[%0t] RX Done: Got=%02h Expected=%02h  FAIL (error=%b)", 
                     $time, data_out, expected, error);
        end
    end
    endtask

    initial begin
        // --- Init ---
        clk   = 0;
        rst   = 1;
        arst  = 0;
        rx_en = 0;
        rx    = 1;

        // --- Release resets ---
        #20 arst = 1;
        #20 rst  = 0;
        #10 rx_en = 1;
        #100;

        // --- Scenario 1: Normal byte ---
        $display("\n--- Scenario 1: Normal RX ---");
        send_uart_byte(8'hA5);
        check_result(8'hA5);

        // --- Scenario 2: Another byte ---
        #(BIT_PERIOD*12);
        $display("\n--- Scenario 2: Normal RX ---");
        send_uart_byte(8'h3C);
        check_result(8'h3C);

        // --- Scenario 3: All zeros ---
        #(BIT_PERIOD*12);
        $display("\n--- Scenario 3: All zeros ---");
        send_uart_byte(8'h00);
        check_result(8'h00);

        // --- Scenario 4: All ones ---
        #(BIT_PERIOD*12);
        $display("\n--- Scenario 4: All ones ---");
        send_uart_byte(8'hFF);
        check_result(8'hFF);

        // --- Scenario 5: Soft reset mid-frame ---
        #(BIT_PERIOD*12);
        $display("\n--- Scenario 5: Soft reset mid-frame ---");
        fork
            send_uart_byte(8'hC3);
            begin
                #(BIT_PERIOD*4);
                rst <= 1;             // assert soft reset (sync)
                $display("[%0t] SYNC RESET asserted!", $time);
                #(CLK_PERIOD*2);
                rst <= 0;             // release
                $display("[%0t] SYNC RESET deasserted!", $time);
            end
        join
        // No check here → data may be corrupted

        // --- Scenario 6: Hard reset mid-frame ---
        #(BIT_PERIOD*12);
        $display("\n--- Scenario 6: Hard reset mid-frame ---");
        fork
            send_uart_byte(8'h96);
            begin
                #(BIT_PERIOD*4);
                arst <= 0;             // assert hard reset (async)
                $display("[%0t] ASYNC RESET asserted!", $time);
                #(BIT_PERIOD);
                arst <= 1;             // release
                $display("[%0t] ASYNC RESET deasserted!", $time);
            end
        join
        // No check here → data should be flushed
       
        // End simulation
        #(BIT_PERIOD*50);
        $display("\n--- Simulation finished ---");
        $stop;
    end

endmodule
