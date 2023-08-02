#include <stdio.h>
#include <string.h>
#include "lwip/err.h"
#include "lwip/tcp.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "xil_io.h"
#include "spi_rwdata.h"
#include <unistd.h>

static struct tcp_pcb *connected_pcb = NULL;
#define SPI_BASEADDER XPAR_SPI_RWDATA_S00_AXI_BASEADDR
#define SPI_REG0 SPI_RWDATA_S00_AXI_SLV_REG0_OFFSET
#define SPI_REG1 SPI_RWDATA_S00_AXI_SLV_REG1_OFFSET
#define SPI_REG2 SPI_RWDATA_S00_AXI_SLV_REG2_OFFSET
#define DT_ADC_DATA_BASEADDER 0x10000000
#define CT_ADC_DATA_BASEADDER 0x30000000
#define MAX_CONNECTIONS 32
#define TCP_SEND_BUFSIZE 4096
static struct tcp_pcb *c_pcb;
volatile unsigned tcp_client_connected = 0;
int data[1024];
int readflag = 0;
int spi_data[1032];
int cnt_snd = 0;
static char send_buf[TCP_SEND_BUFSIZE];
void delay(int count)
{

	int i;
	for (i = 1; i <= count; i++)
		;
}
int process_cmd(struct tcp_pcb *tpcb, struct pbuf *p_rx)
{
	char *pData;
	int i;
	int j;
	err_t err;
	err_t err1;
	int start;
	printf("process tcp cmd\r\n");

	Xil_DCacheDisable();
	if (p_rx != NULL)
	{
		pData = (char *)p_rx->payload;
		printf("recv tcp data\r\n");
		if (pData[0] == 'r' && pData[1] == 'e' && pData[2] == 'a' && pData[3] == 'd')
		{
			printf("dt read mode\r\n");
			int index = 0;
			int ADDER_NEW;
			while (index < 15)
			{
				err = tcp_write(tpcb, DT_ADC_DATA_BASEADDER + index * 4096, 4096, 1);
				tcp_output(tpcb);
				index++;
				if (err == ERR_OK)
				{
					xil_printf("WRITE sdata successfully\r\n", err);
				}
				else
				{
					xil_printf("WRITE sdata failed\r\n", err);
				}
			}
		}
		else if (pData[0] == 'c' && pData[1] == 't' && pData[2] == 'r' && pData[3] == 'e')
		{
			printf("ct read mode\r\n");
			readflag = 1;
		}
		else if (pData[0] == 's' && pData[1] == 'e' && pData[2] == 't')
		{
			char *set_block = &pData[3];							  //
			uint32_t int_block = strtoul(set_block, NULL, 16);		  //
			SPI_RWDATA_mWriteReg(SPI_BASEADDER, SPI_REG2, int_block); //
			printf("set block %x\n", int_block);
		}
		else if (pData[0] == 's' && pData[1] == 'p' && pData[2] == 'i')
		{
			//
			char *sliced_data = &pData[3]; //
			//
			uint32_t int_cmd_data = strtoul(sliced_data, NULL, 16);		 //
			SPI_RWDATA_mWriteReg(SPI_BASEADDER, SPI_REG0, int_cmd_data); //
			printf("%x\n", int_cmd_data);
			start = 0x00000000;
			SPI_RWDATA_mWriteReg(SPI_BASEADDER, SPI_REG1, start); //
			delay(5000);
			start = 0x00000001;
			SPI_RWDATA_mWriteReg(SPI_BASEADDER, SPI_REG1, start); //
			delay(5000);
			start = 0x00000000;
			SPI_RWDATA_mWriteReg(SPI_BASEADDER, SPI_REG1, start); //

			// combine spi_data and sliced_data
			spi_data[0] = int_cmd_data;
			for (j = 0; j < 1024; j++)
			{
				spi_data[j + 1] = (int)(Xil_In32(0x20000000 + 4 * j));
				// spi_data[j + 1] = (int)(j);
			}
			err1 = tcp_write(tpcb, (const void *)spi_data, 4100, 1);

			printf("%x\n", SPI_RWDATA_mReadReg(SPI_BASEADDER, SPI_REG1));
			printf("%x\n", SPI_RWDATA_mReadReg(SPI_BASEADDER, SPI_REG0));
			if (err1 == ERR_OK)
			{
				xil_printf("WRITE spi successfully\r\n", err1);
			}
			else
			{
				xil_printf("WRITE spi failed\r\n", err1);
			}
		}
	}
}

void print_app_header()
{
	xil_printf("\n\r\n\r-----lwIP TCP echo server ------\n\r");
	xil_printf("TCP packets sent to port 7 will be echoed back\n\r");
}

err_t recv_callback(void *arg, struct tcp_pcb *tpcb,
					struct pbuf *p, err_t err)
{
	/* do not read the packet if we are not in ESTABLISHED state */
	if (!p)
	{
		tcp_close(tpcb);
		tcp_recv(tpcb, NULL);
		return ERR_OK;
	}
	printf("recv_callback: %d\r\n");
	/* indicate that the packet has been received */
	tcp_recved(tpcb, p->len);
	/*transfer_data();*/
	process_cmd(tpcb, p);
	pbuf_free(p);

	return ERR_OK;
}
void transfer_data(key_flag)
{

	while (tcp_sndbuf(c_pcb) > TCP_SEND_BUFSIZE & readflag == 1)

	{

		err_t err = tcp_write(c_pcb, CT_ADC_DATA_BASEADDER + cnt_snd * TCP_SEND_BUFSIZE, TCP_SEND_BUFSIZE, 1);
		err = tcp_output(c_pcb);
		cnt_snd++;
	}

	if (key_flag == 0 || cnt_snd == 65536)
	{
		readflag = 0;
		printf("Last adder: %x\r\n", (CT_ADC_DATA_BASEADDER + cnt_snd * TCP_SEND_BUFSIZE));
	}
}
err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;
	c_pcb = newpcb;
	/* set the receive callback for this connection */
	tcp_recv(c_pcb, recv_callback);

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(c_pcb, (void *)(UINTPTR)connection);

	/* increment for subsequent accaepted connections */
	connection++;
	printf("accept callback successfully: %d\r\n");
	cnt_snd = 0;
	//
	tcp_client_connected = 1;

	return ERR_OK;
}

int start_application()
{
	struct tcp_pcb *pcb;
	err_t err;
	unsigned port = 7;

	/*PCB */
	pcb = tcp_new();
	if (!pcb)
	{
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}

	/**/
	err = tcp_bind(pcb, IP_ADDR_ANY, port);
	if (err != ERR_OK)
	{
		xil_printf("Unable to bind to port %d: err = %d\n\r", port, err);
		return -2;
	}

	/* we do not need any arguments to callback functions */
	tcp_arg(pcb, NULL);

	/**/
	pcb = tcp_listen(pcb);
	if (!pcb)
	{
		xil_printf("Out of memory while tcp_listen\n\r");
		return -3;
	}
	/**/
	tcp_accept(pcb, accept_callback);

	xil_printf("TCP server started @ port %d\n\r", port);
	/* initialize data buffer being sent with same as used in iperf */
	return 0;
}
