`timescale 1ns/1ps

module Tx_TB;

    localparam width = 16;
    localparam div   = 16'd10417;

    reg        clk;
    reg        rst;      // synchronous soft reset, active high
    reg        arst;     // asynchronous hard reset, active low
    reg        tx_en;
    reg  [7:0] data;
    wire       done;
    wire       busy;
    wire       tx;

    // Instantiate the top TX module
    Top_module_TX #(
        .width(width),
        .div(div)
    ) uut (
        .clk(clk),
        .rst(rst),
        .arst(arst),
        .tx_en(tx_en),
        .data(data),
        .done(done),
        .busy(busy),
        .tx(tx)
    );

    // Clock generation: 100 MHz
    always #5 clk = ~clk;

    // --- Task to send a single byte ---
    task send_byte(input [7:0] d);
    begin
        @(posedge clk);
        tx_en <= 1;
        data  <= d;
        @(posedge clk);
        tx_en <= 0;
        $display("[%0t] TX Start: %02h", $time, d);
        // Wait until transmission is complete
        wait(done);
        $display("[%0t] TX Done : %02h", $time, d);
    end
    endtask

    initial begin
        // --- Initialize signals ---
        clk   = 0;
        rst   = 1;
        arst  = 0;
        tx_en = 0;
        data  = 8'h00;

        // --- Release async reset ---
        #20 arst = 1;

        // --- Release sync reset after a short delay ---
        #20 rst  = 0;

        // --- Allow system to stabilize ---
        #100;

        // --- Scenario 1: Normal byte transmission ---
        $display("\n--- Scenario 1: Normal transmission ---");
        send_byte(8'hA5);

        // --- Scenario 2: Transmit another byte ---
        #1_200_000; 
        $display("\n--- Scenario 2: Normal transmission ---");
        send_byte(8'h3C);
        
        // --- Scenario 3: All zeros ---
        #1_200_000; 
        $display("\n--- Scenario 3: All zeros ---");
        send_byte(8'h00);

        // --- Scenario 4: All ones ---
        #1_200_000; 
        $display("\n--- Scenario 4: All ones ---");
        send_byte(8'hFF);

        // --- Scenario 5: Async reset during transmission ---
        #1_200_000; 
        $display("\n--- Scenario 5: Async reset during transmission ---");
        @(posedge clk);
        tx_en <= 1;
        data  <= 8'hC3;
        @(posedge clk);
        tx_en <= 0;
        $display("[%0t] TX Start: %02h", $time, 8'hC3);
        #400_000; // Let some bits transmit
        arst <= 0; // Assert async reset
        $display("[%0t] ASYNC RESET asserted!", $time);
        #200;
        arst <= 1; // Deassert async reset
        $display("[%0t] ASYNC RESET deasserted!", $time);

        // --- Wait a little for stabilization ---
        #100;

        // --- Scenario 6: Sync reset during transmission ---
        #1_200_000;
        $display("\n--- Scenario 6: Sync reset during transmission ---");
        @(posedge clk);
        tx_en <= 1;
        data  <= 8'h96;
        @(posedge clk);
        tx_en <= 0;
        $display("[%0t] TX Start: %02h", $time, 8'h96);
        #400_000; // Let some bits transmit
        rst <= 1;  // Assert sync reset
        $display("[%0t] SYNC RESET asserted!", $time);
        #200;
        rst <= 0;  // Deassert sync reset
        $display("[%0t] SYNC RESET deasserted!", $time);

        // --- Scenario 7: Attempt overlapping transmissions ---
        #1_200_000;
        $display("\n--- Scenario 7: Overlapping transmissions ---");
        @(posedge clk);
        tx_en <= 1;
        data  <= 8'h12;
        @(posedge clk);
        tx_en <= 0;
        $display("[%0t] TX Start: %02h", $time, 8'h12);

        // During ongoing transmission, attempt to start another frame
        #100_000;
        @(posedge clk);
        tx_en <= 1;
        data  <= 8'hFA;
        @(posedge clk);
        tx_en <= 0;
        $display("[%0t] Attempted overlapping TX: %02h (should be ignored)", $time, 8'hFA);

        wait(done);
        $display("[%0t] TX Done : %02h", $time, 8'h12);

        // --- Finish simulation ---
        #2_000_000;
        $display("\n--- Simulation finished ---");
        $stop;
    end

endmodule
