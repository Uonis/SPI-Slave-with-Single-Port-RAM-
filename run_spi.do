vlib work
vlog SPI.v tb_spi.v
vsim -voptargs=+acc work.tb_spi
add wave *
add wave /tb_spi/uut/spi_ram_inst/mem
run -all
#quit -sim