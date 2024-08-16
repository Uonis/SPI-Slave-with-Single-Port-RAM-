module spi (
    input mosi,
    input ss_n,
    input clk,
    input rst_n,
    output miso
);

// Wires to connect SPI Slave to RAM
wire [9:0] rx_data;
wire rx_valid;
wire [7:0] tx_data;
wire tx_valid;

// Instantiation of SPI_slave
SPI_slave spi_slave_inst (
    .mosi(mosi),
    .ss_n(ss_n),
    .clk(clk),
    .rst_n(rst_n),
    .miso(miso),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .tx_data(tx_data),
    .tx_valid(tx_valid)
);

// Instantiation of SPI_ram
SPI_ram spi_ram_inst (
    .din(rx_data),
    .rx_valid(rx_valid),
    .clk(clk),
    .rst_n(rst_n),
    .tx_valid(tx_valid),
    .dout(tx_data)
);

endmodule

