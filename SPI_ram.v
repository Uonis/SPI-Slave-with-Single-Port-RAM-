module SPI_ram 
#(
    parameter MEM_DEPTH = 256,
    parameter MEM_WIDTH = 8,
    parameter ADDR_SIZE = 8,
    parameter N = 10,
    parameter W = 8
)
(
    input [N-1:0] din,
    input rx_valid, clk, rst_n,
    output reg tx_valid,
    output reg [W-1:0] dout 
);

reg [MEM_WIDTH-1:0] mem [MEM_DEPTH-1:0];
reg [ADDR_SIZE-1:0] addr;

always @(posedge clk) begin
    if (~rst_n) begin
        dout <= 8'd0;
        tx_valid <= 0;
    end else begin
        if (rx_valid) begin
            case (din[9:8])
                2'b00: addr <= din[7:0];
                2'b01: mem[addr] <= din[7:0];
                2'b10: addr <= din[7:0];
                2'b11: begin 
                    tx_valid <= 1; 
                    dout <= mem[addr]; 
                end
            endcase
        end else begin    
            tx_valid <= 0;
        end
    end
end

endmodule

