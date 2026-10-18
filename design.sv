`timescale 1ns/1ps

// Beginner I2C Master: writes one byte to a 7-bit slave address.
// Open-drain SDA: sda_low=1 pulls SDA LOW; sda_low=0 releases it.
module i2c_master (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [6:0] slave_addr,
    input  wire [7:0] data_in,
    input  wire       sda_in,

    output reg        scl,
    output reg        sda_low,
    output reg        done,
    output reg        error
);

    localparam IDLE       = 4'd0;
    localparam START_BIT  = 4'd1;
    localparam ADDR_SETUP = 4'd2;
    localparam ADDR_HIGH  = 4'd3;
    localparam ADDR_LOW   = 4'd4;
    localparam ACK_HIGH   = 4'd5;
    localparam ACK_CHECK  = 4'd6;
    localparam ACK_LOW    = 4'd7;
    localparam DATA_SETUP = 4'd8;
    localparam DATA_HIGH  = 4'd9;
    localparam DATA_LOW   = 4'd10;
    localparam STOP_LOW   = 4'd11;
    localparam STOP_HIGH  = 4'd12;
    localparam STOP_END   = 4'd13;

    reg [3:0] state;
    reg [7:0] shift_byte;
    reg [2:0] bit_index;
    reg       data_phase;

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            scl        <= 1'b1;
            sda_low    <= 1'b0;
            done       <= 1'b0;
            error      <= 1'b0;
            shift_byte <= 8'd0;
            bit_index  <= 3'd0;
            data_phase <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    scl        <= 1'b1;
                    sda_low    <= 1'b0;
                    data_phase <= 1'b0;

                    if (start) begin
                        shift_byte <= {slave_addr, 1'b0}; // Write bit = 0
                        bit_index  <= 3'd7;
                        error      <= 1'b0;
                        state      <= START_BIT;
                    end
                end

                START_BIT: begin
                    // SDA falls while SCL is HIGH: START
                    scl     <= 1'b1;
                    sda_low <= 1'b1;
                    state   <= ADDR_SETUP;
                end

                ADDR_SETUP: begin
                    scl     <= 1'b0;
                    sda_low <= ~shift_byte[bit_index];
                    state   <= ADDR_HIGH;
                end

                ADDR_HIGH: begin
                    scl   <= 1'b1;
                    state <= ADDR_LOW;
                end

                ADDR_LOW: begin
                    scl <= 1'b0;

                    if (bit_index == 0) begin
                        sda_low <= 1'b0; // Release SDA for address ACK
                        state   <= ACK_HIGH;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                        state     <= ADDR_SETUP;
                    end
                end

                ACK_HIGH: begin
                    scl   <= 1'b1;
                    state <= ACK_CHECK;
                end

                ACK_CHECK: begin
                    // Slave ACK = SDA LOW; NACK = SDA HIGH
                    if (sda_in)
                        error <= 1'b1;

                    scl   <= 1'b0;
                    state <= ACK_LOW;
                end

                ACK_LOW: begin
                    if (error) begin
                        state <= STOP_LOW;
                    end else if (!data_phase) begin
                        // Address ACK: begin sending data byte
                        data_phase <= 1'b1;
                        shift_byte <= data_in;
                        bit_index  <= 3'd7;
                        state      <= DATA_SETUP;
                    end else begin
                        // Data ACK: finish transaction
                        state <= STOP_LOW;
                    end
                end

                DATA_SETUP: begin
                    scl     <= 1'b0;
                    sda_low <= ~shift_byte[bit_index];
                    state   <= DATA_HIGH;
                end

                DATA_HIGH: begin
                    scl   <= 1'b1;
                    state <= DATA_LOW;
                end

                DATA_LOW: begin
                    scl <= 1'b0;

                    if (bit_index == 0) begin
                        sda_low <= 1'b0; // Release SDA for data ACK
                        state   <= ACK_HIGH;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                        state     <= DATA_SETUP;
                    end
                end

                STOP_LOW: begin
                    scl     <= 1'b0;
                    sda_low <= 1'b1;
                    state   <= STOP_HIGH;
                end

                STOP_HIGH: begin
                    scl   <= 1'b1;
                    state <= STOP_END;
                end

                STOP_END: begin
                    // SDA rises while SCL is HIGH: STOP
                    scl     <= 1'b1;
                    sda_low <= 1'b0;
                    done    <= 1'b1;
                    state   <= IDLE;
                end

                default: begin
                    state   <= IDLE;
                    scl     <= 1'b1;
                    sda_low <= 1'b0;
                end
            endcase
        end
    end

endmodule
