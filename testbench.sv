`timescale 1ns/1ps

module tb_i2c;

    reg clk   = 1'b0;
    reg rst   = 1'b1;
    reg start = 1'b0;

    wire scl;
    wire sda_low;
    wire sda_in;
    wire done;
    wire error;

    // SDA has a pull-up; released SDA reads HIGH.
    tri1 sda;

    // Master open-drain output.
    assign sda = sda_low ? 1'b0 : 1'bz;

    // Test slave ACKs during the master's ACK states.
    // This is a simple simulation model, not a physical slave implementation.
    wire slave_ack_low;
    assign slave_ack_low =
        (master.state == 4'd5) || // ACK_HIGH
        (master.state == 4'd6) || // ACK_CHECK
        (master.state == 4'd7);   // ACK_LOW

    assign sda = slave_ack_low ? 1'b0 : 1'bz;
    assign sda_in = sda;

    reg [7:0] captured_data = 8'd0;
    integer data_bit_count = 0;

    i2c_master master (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(7'h50),
        .data_in(8'hA5),
        .sda_in(sda_in),
        .scl(scl),
        .sda_low(sda_low),
        .done(done),
        .error(error)
    );

    always #5 clk = ~clk;

    // Sample each data bit while the master holds SCL HIGH.
    // DATA_HIGH is state 9 in the design.
    always @(negedge clk) begin
        if (!rst && master.state == 4'd9) begin
            captured_data = {captured_data[6:0], sda};
            data_bit_count = data_bit_count + 1;
        end
    end

    initial begin
        $dumpfile("i2c_write.vcd");
        $dumpvars(0, tb_i2c);

        repeat (3) @(negedge clk);
        rst = 1'b0;

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Prevent the test from waiting forever if the FSM gets stuck.
        fork
            begin
                wait(done == 1'b1);
            end
            begin
                repeat (250) @(negedge clk);
                $display("TIMEOUT: master did not finish");
                $finish;
            end
        join_any
        disable fork;

        #1;
        $display("Slave captured data = %h", captured_data);
        $display("Data bits captured  = %0d", data_bit_count);
        $display("Master error        = %b", error);

        if (captured_data == 8'hA5 &&
            data_bit_count == 8 &&
            error == 1'b0)
            $display("I2C TEST: PASS");
        else
            $display("I2C TEST: FAIL");

        #20;
        $finish;
    end

endmodule
