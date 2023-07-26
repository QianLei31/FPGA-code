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
#define ADC_DATA_BASEADDER 0x30000000

volatile unsigned tcp_client_connected = 0;
int data[1024];
int spi_data[1032];
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
	// printf("process tcp cmd\r\n");

	Xil_DCacheDisable();
	if (p_rx != NULL)
	{
		pData = (char *)p_rx->payload;
		// printf("recv tcp data\r\n");
		if (pData[0] == 'r' && pData[1] == 'e' && pData[2] == 'a' && pData[3] == 'd')
		{
			char *set_block = &pData[4];							  //
			uint32_t int_block = strtoul(set_block, NULL, 16);		  //
			SPI_RWDATA_mWriteReg(SPI_BASEADDER, SPI_REG2, int_block); //
			usleep(100000);
			int index = 0;
			while (1)
			{
				for (i = 0; i < 1024; i++)
				{
					data[i] = (int)(Xil_In32(ADC_DATA_BASEADDER + 4 * i + index * 4096));
				}
				err = tcp_write(tpcb, data, 4096, 1);
				tcp_output(tpcb);

				index++;
				if (index == 20)
				{
					printf("%x\n", data[1023]);
					break;
				}

				if (err == ERR_OK)
				{
					xil_printf("WRITE sdata successfully\r\n", err);
				}
				else
				{
					xil_printf("WRITE sdata failed\r\n", err);
				}
				printf("%x\n", index);
			}
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

	/* indicate that the packet has been received */
	tcp_recved(tpcb, p->len);
	/*transfer_data();*/
	process_cmd(tpcb, p);
	pbuf_free(p);

	return ERR_OK;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void *)(UINTPTR)connection);

	/* increment for subsequent accepted connections */
	connection++;

	//
	connected_pcb = newpcb;
	//
	tcp_nagle_disable(connected_pcb);
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

	xil_printf("TCP echo server started @ port %d\n\r", port);

	return 0;
}
