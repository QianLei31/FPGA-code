module MAIN_FSM (
	/* 38.4MHz domain */
	clk_50M,  //Chip clock 
    rst_n,    // Asynchronous rst_n
	chem_out, // input from probe

    p_data,     // from data_to_post in BLOCK of one row
	s_data,     // serially output to ex.
	data_valid, // data valid

	/* 3.2MHz domain */
	clk_3p2M,
    rst_n_block, // Asynchronous rst_n to BLOCK

	code,     // spi bus
	addr,     // spi bus
	data_in,  // spi bus
	data_out, // spi bus
	
	data_to_elec, // data to ELEC in probe
	clk_to_elec,  // clk to ELEC in probe
	data_to_elec_chem,  // data to ELEC CHEM in probe
	clk_to_elec_chem,   // data to ELEC CHEM in probe

	rst_n_to_probe, // Reset ALL ELEC in probe

    /*  Standard SPI interface */
    sck,  // SPI clock
    miso, // Master IN slave Out lsb first, Latched in in falling edge
    mosi, // Master Out slave IN lsb first, changed in falling edge
    cs_n  // Chip select (low active)
);

//`include "parameter.v"
parameter LEN_SPI = 32 ; //packet data only after decoding and header removeal
parameter SPI_ADDR_LEN = 10;
parameter SPI_DATA_LEN = 16;
parameter SPI_CODE_LEN = 6;
parameter ROW_NUM = 8;
parameter BITS_ADC = 12; // ADC data width
// SPI interface
input  sck, mosi, cs_n;
output miso;

// Internal parallel interface to FSM
input rst_n,clk_50M;
output clk_3p2M;
//code addr data_in
output [SPI_CODE_LEN-1:0] code;
output [SPI_ADDR_LEN-1:0] addr;
output [SPI_DATA_LEN-1:0] data_in;

inout [SPI_DATA_LEN-1:0] data_out;

output  data_to_elec;
output  clk_to_elec;
output  data_to_elec_chem;
output  clk_to_elec_chem;

output  rst_n_to_probe;

input [7:0] chem_out; // counter CHEM pulse

input  [ROW_NUM*(BITS_ADC+1)-1:0] p_data;
output [ROW_NUM-1:0] s_data;
output [ROW_NUM-1:0] data_valid;
output               rst_n_block;

wire [LEN_SPI-1:0] tx_input;
wire push_tx;
wire ack_fetch_spi;
wire [LEN_SPI-1:0] rx_output;
wire spi_busy;
wire rdy_spi;

RST_N_SYN rst_n_syn(
    .clk_sys(clk_50M),    // Chip clock 
    .rst_n(rst_n),        // Asynchronous rst_n
	.rst_syn_n(rst_syn_n)
);

RST_N_SYN rst_n_syn2block(
    .clk_sys(clk_3p2M),    // Chip clock 
    .rst_n(rst_syn_n),        // Asynchronous rst_n
	.rst_syn_n(rst_n_block)
);

CLK_12P clk_12p(
	.clk_50M(clk_50M),
	.rst_n(rst_syn_n),

	.clk_3p2M(clk_3p2M)
);

FSM fsm(
    .clk(clk_50M),        //Chip clock 
    .rst_n(rst_syn_n),    // Asynchronous rst_n
	
	.rx_output(rx_output),         // output to spi, spi cmd
	.rdy_spi(rdy_spi),             // output to spi, data ready
	.spi_busy(spi_busy),           // output to spi, data busy
	.push_tx(push_tx),             // output to spi, push data to buffer that output to ex. device
	.ack_fetch_spi(ack_fetch_spi), // output to spi

	.tx_input(tx_input),           // input from spi
	
	.code(code),         // spi bus
	.addr(addr),         // spi bus
	.data_in(data_in),   // spi bus
	.data_out(data_out), // spi bus
	
	.data_to_elec(data_to_elec), // data to ELEC in probe
	.clk_to_elec(clk_to_elec),  // clk to ELEC in probe
	.data_to_elec_chem(data_to_elec_chem),  // data to ELEC CHEM in probe
	.clk_to_elec_chem(clk_to_elec_chem),   // data to ELEC CHEM in probe

	.rst_n_to_probe(rst_n_to_probe), // Reset ALL ELEC in probe
	
	.clk_3p2M(clk_3p2M), // output to ALL BLOCK

	.chem_out(chem_out) // input from Probe
);

spi_std_slave spi_slave(
    // Standard SPI interface
    .sck(sck),        // SPI clock
    .miso(miso),       // Master IN slave Out lsb first, Latched in in falling edge
    .mosi(mosi),       // Master Out slave IN lsb first, changed in falling edge
    .cs_n(cs_n),        // Chip select (low active)

    // Internal parallel interface
    .clk(clk_50M),        //Chip clock 
    .rst_n(rst_syn_n),      // Asynchronous rst_n
    .tx_input(tx_input),   // Transmission data in FSM-> SPI -> SPI MASTER
    .rx_output(rx_output),  // Receiving data SPI MASTER -> SPI -> FSM
    .push_tx(push_tx),  //high to update data.
    .spi_busy(spi_busy),  // Transceiver is busy (high active), will be low if is idel or tx rx finished
    .ack_fetch_spi(ack_fetch_spi), //from fsm to inform the spi engine that fectch is done.
    .rdy_spi(rdy_spi) //transceiver is ready , data is valid during when rdy is high.
);

genvar x;
generate
	for (x = 0; x < ROW_NUM; x=x+1) begin : P2S_i
		P2S p2s(
			.p_data(p_data[x*(BITS_ADC+1)+:(BITS_ADC+1)]),
			.clk_50M(clk_50M),
			.clk_3p2M(clk_3p2M),
			.rst_n(rst_syn_n),
			.s_data(s_data[x]),
			.data_valid(data_valid[x])
		);
	end	
endgenerate

endmodule