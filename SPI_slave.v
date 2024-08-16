module SPI_slave 
#(
    parameter IDLE = 3'b000,
    parameter CHK_CMD = 3'b001,
    parameter WRITE = 3'b010,
    parameter READ_ADD = 3'b011,
    parameter READ_DATA = 3'b100
)
(
    input mosi, ss_n, // in from master
    input clk, rst_n,
    output reg miso,

    output reg [9:0] rx_data,
    output reg rx_valid,

    input  [7:0] tx_data,
    input  tx_valid 
);

(*fsm_encoding="one_hot"*) 
reg [2:0] cs, ns;
reg read_add;
reg [3:0] bit_counter_sipo;
reg [2:0] bit_counter_piso;
reg [9:0] shift_register_sipo;
reg [7:0] shift_register_piso;
integer i;
reg wating_for_start_sipo;
reg wating_for_start_piso;
reg start_sipo;
reg start_piso;
reg load_piso;

// Serial-In Parallel-Out (SIPO)
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        bit_counter_sipo <= 4'd0;
        shift_register_sipo <= 10'd0;
        wating_for_start_sipo <= 1'b1;
        start_sipo <= 1'b0;
    end else begin
        if (wating_for_start_sipo) begin
            if (~mosi) begin
                wating_for_start_sipo <= 1'b0;
                start_sipo <= 1'b1;
            end
        end else if (start_sipo) begin
            for (i = 9; i > 0; i = i - 1) begin
                shift_register_sipo[i] <= shift_register_sipo[i-1];
            end
            shift_register_sipo[0] <= mosi;
            if (bit_counter_sipo == 4'd9) begin
                bit_counter_sipo <= 4'd0;
            end else begin
                bit_counter_sipo <= bit_counter_sipo + 1;
            end
        end
    end
end

// Parallel-In Serial-Out (PISO)
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        bit_counter_piso <= 3'd0;
        wating_for_start_piso <= 1'b1;
        start_piso <= 1'b0;
        shift_register_piso <= 8'd0;
    end else begin
        if (wating_for_start_piso) begin
            if (mosi) begin
                wating_for_start_piso <= 1'b0;
                start_piso <= 1'b1;
            end
        end else if (start_piso && rst_n) begin
            if (load_piso) begin
                shift_register_piso <= tx_data;
            end else begin
                miso <= shift_register_piso[7]; // Output the MSB of the shift register
                for (i = 7; i > 0; i = i - 1) begin
                    shift_register_piso[i] <= shift_register_piso[i - 1];
                end
                shift_register_piso[0] <= 1'b0; 
                if (bit_counter_piso == 3'd7) begin
                    start_piso <= 1'b0; 
                end else begin
                    bit_counter_piso <= bit_counter_piso + 1;
                end
            end
        end
    end
end

// FSM
// Next state logic
always @(*) begin
    case(cs)
        IDLE: ns = (~ss_n) ? CHK_CMD : IDLE;
        CHK_CMD: begin
            if (~ss_n) begin
                ns = (~mosi) ? WRITE : ((~read_add) ? READ_ADD : READ_DATA);
            end else begin
                ns = IDLE;
            end
        end
        WRITE: ns = (ss_n) ? IDLE : WRITE;
        READ_ADD: ns = (ss_n) ? IDLE : READ_ADD;
        READ_DATA: ns = (ss_n) ? IDLE : READ_DATA;
        default: ns = IDLE;
    endcase
end

// State memory
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cs <= IDLE;
    end else begin
        cs <= ns;
    end
end

// Output logic
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rx_valid <= 1'b0;
        load_piso <= 1'b0;  // Reset load signal
    end else begin
        if (cs == WRITE && ss_n == 0) begin
            rx_valid <= 1;
            rx_data <= shift_register_sipo;
        end else if (cs == READ_ADD && ss_n == 0 && ~read_add) begin
            load_piso <= 1'b1;  // Set load signal
        end else if (cs == READ_DATA && ss_n == 0 && read_add && tx_valid) begin
            load_piso <= 1'b1;  // Set load signal
        end else begin
            rx_valid <= 1'b0;
            load_piso <= 1'b0;  // Reset load signal
        end
    end
end

endmodule
