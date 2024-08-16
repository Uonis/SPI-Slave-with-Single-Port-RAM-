`timescale 1ns/1ps

module tb_spi();

  reg clk, rst_n, mosi, ss_n;
  wire miso;
  wire [9:0] rx_data;
  wire rx_valid;
  wire [7:0] tx_data;
  wire tx_valid;

  // Instantiate the SPI slave
  SPI_slave uut (
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

  // Instantiate the SPI RAM
  SPI_ram #(
    .MEM_DEPTH(256),
    .MEM_WIDTH(8),
    .ADDR_SIZE(8),
    .N(10),
    .W(8)
  ) spi_ram_inst (
    .din(rx_data),
    .rx_valid(rx_valid),
    .clk(clk),
    .rst_n(rst_n),
    .tx_valid(tx_valid),
    .dout(tx_data)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Stimulus
  initial begin
    // Reset
    rst_n = 0;
    mosi = 0;
    ss_n = 1;
    #20;
    rst_n = 1;

    // Test case 1: Write to RAM
    ss_n = 0;
    mosi_send(10'b0000000010); // Address 2
    mosi_send(10'b0100001010); // Write value 10 to address 2
    ss_n = 1;
    #20;

    // Test case 2: Read from RAM
    ss_n = 0;
    mosi_send(10'b1000000010); // Address 2
    mosi_send(10'b1100000000); // Read from address 2
    ss_n = 1;
    #20;

    $stop;
  end

  // SPI Send Task
  task mosi_send;
    input [9:0] data;
    integer i;
    begin
      for (i = 9; i >= 0; i = i - 1) begin
        mosi = data[i];
        #10; // Wait for one clock cycle
      end
    end
  endtask

  // Monitor
  initial begin
    $monitor("At time %t, rx_data = %h, rx_valid = %b, tx_data = %h, tx_valid = %b",
             $time, rx_data, rx_valid, tx_data, tx_valid);
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_spi.vcd");
    $dumpvars(0, tb_spi);
  end

endmodule

