#include <stdio.h>
#include "xparameters.h"
#include "netif/xadapter.h"
#include "platform.h"
#include "platform_config.h"
#include "lwip/tcp.h"
#include "xil_cache.h"

#if LWIP_IPV6 == 1
#include "lwip/ip.h"
#else
#if LWIP_DHCP == 1
#include "lwip/dhcp.h"
#endif
#endif

/* defined by each RAW mode application */
void print_app_header();
int start_application();
int transfer_data();
void tcp_fasttmr(void);
void tcp_slowtmr(void);

/* missing declaration in lwIP */
void lwip_init();

#if LWIP_IPV6 == 0
#if LWIP_DHCP == 1
extern volatile int dhcp_timoutcntr;
err_t dhcp_start(struct netif *netif);
#endif
#endif

extern volatile int TcpFastTmrFlag;
extern volatile int TcpSlowTmrFlag;
extern volatile unsigned tcp_client_connected;
static struct netif server_netif;
struct netif *echo_netif;

#if LWIP_IPV6 == 1
void print_ip6(char *msg, ip_addr_t *ip)
{
	print(msg);
	xil_printf(" %x:%x:%x:%x:%x:%x:%x:%x\n\r",
			   IP6_ADDR_BLOCK1(&ip->u_addr.ip6),
			   IP6_ADDR_BLOCK2(&ip->u_addr.ip6),
			   IP6_ADDR_BLOCK3(&ip->u_addr.ip6),
			   IP6_ADDR_BLOCK4(&ip->u_addr.ip6),
			   IP6_ADDR_BLOCK5(&ip->u_addr.ip6),
			   IP6_ADDR_BLOCK6(&ip->u_addr.ip6),
			   IP6_ADDR_BLOCK7(&ip->u_addr.ip6),
			   IP6_ADDR_BLOCK8(&ip->u_addr.ip6));
}
#else
void print_ip(char *msg, ip_addr_t *ip)
{
	print(msg);
	xil_printf("%d.%d.%d.%d\n\r", ip4_addr1(ip), ip4_addr2(ip),
			   ip4_addr3(ip), ip4_addr4(ip));
}

void print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw)
{

	print_ip("Board IP: ", ip);
	print_ip("Netmask : ", mask);
	print_ip("Gateway : ", gw);
}
#endif

/*****user define***/
#define TX_SIZE 10
static struct tcp_pcb *connected_pcb = NULL;
unsigned client_connected = 0;
//
uint tcp_trans_done = 0;

// u_char data[TX_SIZE] = {0,1,2,3,4,5,6,7,8,9};

static err_t tcp_sent_callback(void *arg, struct tcp_pcb *tpcb, u16_t len)
{
	tcp_trans_done++;
	return ERR_OK;
}
static err_t tcp_connected_callback(void *arg, struct tcp_pcb *tpcb, err_t err)
{
	/* store state */
	connected_pcb = tpcb;

	/* set callback values & functions */
	tcp_arg(tpcb, NULL);

	// tcp_sent_callback
	tcp_sent(tpcb, tcp_sent_callback);

	client_connected = 1;

	/* initiate data transfer */
	return ERR_OK;
}
int client_application()
{
	struct tcp_pcb *pcb;
	ip_addr_t ipaddr;
	err_t err;
	unsigned port = 7;

	/* create new TCP PCB structure */
	pcb = tcp_new();
	if (!pcb)
	{
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}
	else
		xil_printf("creating PCB.\n\r");
	/* connect to iperf tcp server */
	IP4_ADDR(&ipaddr, 192, 168, 2, 89); //

	// tcp_connected_callback
	err = tcp_connect(pcb, &ipaddr, port, tcp_connected_callback);
	if (err != ERR_OK)
	{
		xil_printf("txperf: tcp_connect returned error: %d\r\n", err);
		return err;
	}
	else
		xil_printf("txperf: tcp_connect returned : %d\r\n", err);
	pcb = tcp_listen(pcb);
	if (!pcb)
	{
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}
	else
		xil_printf("creating PCB.\n\r");

	return 0;
}

int main()
{
	uint cycle;
#if LWIP_IPV6 == 0
	ip_addr_t ipaddr, netmask, gw;

#endif
	/* the mac address of the board. this should be unique per board */
	unsigned char mac_ethernet_address[] =
		{0x00, 0x0a, 0x35, 0x00, 0x01, 0x02};

	echo_netif = &server_netif;

	init_platform();

#if LWIP_IPV6 == 0
#if LWIP_DHCP == 1
	ipaddr.addr = 0;
	gw.addr = 0;
	netmask.addr = 0;
#else
	/* initliaze IP addresses to be used */
	IP4_ADDR(&ipaddr, 192, 168, 2, 10);
	IP4_ADDR(&netmask, 255, 255, 255, 0);
	IP4_ADDR(&gw, 192, 168, 2, 1);
#endif
#endif
	print_app_header();

	lwip_init();

#if (LWIP_IPV6 == 0)
	/* Add network interface to the netif_list, and set it as default */
	if (!xemac_add(echo_netif, &ipaddr, &netmask,
				   &gw, mac_ethernet_address,
				   PLATFORM_EMAC_BASEADDR))
	{
		xil_printf("Error adding N/W interface\n\r");
		return -1;
	}
#else
	/* Add network interface to the netif_list, and set it as default */
	if (!xemac_add(echo_netif, NULL, NULL, NULL, mac_ethernet_address,
				   PLATFORM_EMAC_BASEADDR))
	{
		xil_printf("Error adding N/W interface\n\r");
		return -1;
	}
	echo_netif->ip6_autoconfig_enabled = 1;

	netif_create_ip6_linklocal_address(echo_netif, 1);
	netif_ip6_addr_set_state(echo_netif, 0, IP6_ADDR_VALID);

	print_ip6("\n\rBoard IPv6 address ", &echo_netif->ip6_addr[0].u_addr.ip6);

#endif
	netif_set_default(echo_netif);

	/* now enable interrupts */
	platform_enable_interrupts();

	/* specify that the network if is up */
	netif_set_up(echo_netif);

#if (LWIP_IPV6 == 0)
#if (LWIP_DHCP == 1)
	/* Create a new DHCP client for this interface.
	 * Note: you must call dhcp_fine_tmr() and dhcp_coarse_tmr() at
	 * the predefined regular intervals after starting the client.
	 */
	dhcp_start(echo_netif);
	dhcp_timoutcntr = 24;

	while (((echo_netif->ip_addr.addr) == 0) && (dhcp_timoutcntr > 0))
		xemacif_input(echo_netif);

	if (dhcp_timoutcntr <= 0)
	{
		if ((echo_netif->ip_addr.addr) == 0)
		{
			xil_printf("DHCP Timeout\r\n");
			xil_printf("Configuring default IP of 192.168.2.10\r\n");
			IP4_ADDR(&(echo_netif->ip_addr), 192, 168, 2, 10);
			IP4_ADDR(&(echo_netif->netmask), 255, 255, 255, 0);
			IP4_ADDR(&(echo_netif->gw), 192, 168, 2, 1);
		}
	}

	ipaddr.addr = echo_netif->ip_addr.addr;
	gw.addr = echo_netif->gw.addr;
	netmask.addr = echo_netif->netmask.addr;
#endif

	print_ip_settings(&ipaddr, &netmask, &gw);

#endif
	/* start the application (web server, rxtest, txtest, etc..) */
	start_application();
	// client_application();
	/* receive and process packets */
	while (1)
	{
		if (TcpFastTmrFlag)
		{
			tcp_fasttmr();
			TcpFastTmrFlag = 0;
		}
		if (TcpSlowTmrFlag)
		{
			tcp_slowtmr();
			TcpSlowTmrFlag = 0;
		}
		xemacif_input(echo_netif);
	}

	/* never reached */
	cleanup_platform();

	return 0;
}
