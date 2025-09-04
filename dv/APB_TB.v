`timescale 1ns/1ps

module APB_TB;
    localparam BAUD_DIV    = 16'd10417;
    localparam BAUD_WIDTH  = 16;
    localparam CLK_PERIOD  = 10;
    localparam BIT_PERIOD  = BAUD_DIV * CLK_PERIOD;

    reg         PCLK;
    reg         PRESETn;
    reg  [31:0] PADDR;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg  [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;

    wire uart_tx;
    assign uart_rx = uart_tx;

    reg [7:0]  rec_byte;
    reg        rec_err;
    reg [31:0] status;
    reg [31:0] rdata;
    integer    timeout;

    integer pass_count = 0;
    integer fail_count = 0;

    APB_UART #(
        .BAUD_DIV(BAUD_DIV),
        .BAUD_WIDTH(BAUD_WIDTH)
    ) uut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    always #(CLK_PERIOD/2) PCLK = ~PCLK;

    // --- APB helpers ---
    task apb_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge PCLK);
        PADDR   = addr; PWDATA = data;
        PSEL    = 1;    PWRITE = 1; PENABLE = 0;
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0; PENABLE = 0;
    end
    endtask

    task apb_read(input [31:0] addr, output [31:0] rdata_out);
    begin
        @(posedge PCLK);
        PADDR   = addr; PSEL = 1; PWRITE = 0; PENABLE = 0;
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        #1 rdata_out = PRDATA;
        @(posedge PCLK);
        PSEL    = 0; PENABLE = 0;
    end
    endtask

    // --- TX helper ---
    task send_byte(input [7:0] d);
    begin
        apb_read(32'h04, status);
        if (!status[0]) apb_write(32'h08, {24'h0, d});
    end
    endtask

    // --- RX helper ---
    task recv_byte(output [7:0] d, output err);
        reg timeout_flag;
    begin
        timeout = 0; timeout_flag = 0; status[3] = 0;
        while (status[3]==0 && !timeout_flag) begin
            apb_read(32'h04, status);
            #CLK_PERIOD;
            timeout = timeout + 1;
            if (timeout > (BIT_PERIOD*20/CLK_PERIOD)) timeout_flag = 1;
        end
        if (!timeout_flag) begin
            err = status[4];
            apb_read(32'h0C, rdata);
            d = rdata[7:0];
        end else begin
            d = 8'hXX; err = 1;
        end
    end
    endtask

    // --- Result printer ---
    task show(input integer scen, input [7:0] s, input [7:0] r, input ok);
    begin
        if (ok) pass_count = pass_count+1;
        else    fail_count = fail_count+1;
        $display("[%0t] Scenario %0d Sent=%02h Rec=%02h %s",
                 $time, scen, s, r, ok ? "PASS" : "FAIL");
    end
    endtask

    initial begin
        PCLK=0; PRESETn=0; PADDR=0; PSEL=0; PENABLE=0; PWRITE=0; PWDATA=0;
        #20 PRESETn=1;
        #100 apb_write(32'h00, 32'h3); // enable
        #100;

        // Scenario 1
        send_byte(8'hA5); #(BIT_PERIOD*12); recv_byte(rec_byte,rec_err);
        show(1, 8'hA5, rec_byte, (rec_byte==8'hA5 && !rec_err));

        // Scenario 2
        #(BIT_PERIOD*12); send_byte(8'h3C); #(BIT_PERIOD*12);
        recv_byte(rec_byte,rec_err);
        show(2, 8'h3C, rec_byte, (rec_byte==8'h3C && !rec_err));

        // Scenario 3
        #(BIT_PERIOD*12); send_byte(8'h00); #(BIT_PERIOD*12);
        recv_byte(rec_byte,rec_err);
        show(3, 8'h00, rec_byte, (rec_byte==8'h00 && !rec_err));

        // Scenario 4
        #(BIT_PERIOD*12); send_byte(8'hFF); #(BIT_PERIOD*12);
        recv_byte(rec_byte,rec_err);
        show(4, 8'hFF, rec_byte, (rec_byte==8'hFF && !rec_err));

        // Scenario 5: Overlap
        #(BIT_PERIOD*12); send_byte(8'h12); #(BIT_PERIOD*3);
        send_byte(8'hFA); #(BIT_PERIOD*12);
        recv_byte(rec_byte,rec_err);
        show(5, 8'h12, rec_byte, (rec_byte==8'h12 && !rec_err));

        // Summary
        $display("--------------------------------------------------");
        $display("TEST SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("--------------------------------------------------");

        #(BIT_PERIOD*20) $stop;
    end
endmodule
