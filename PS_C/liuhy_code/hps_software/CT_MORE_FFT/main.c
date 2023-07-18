
// Client side C/C++ program to demonstrate Socket programming 
/*
 * Include Files.
 */
#define soc_cv_av
#include <netdb.h> 
#include <stdio.h> 
#include <stdlib.h> 
#include <string.h> 
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
 #include <inttypes.h>
#include <sys/socket.h> 
#include <netinet/in.h> 

#include <sys/mman.h>
#include <sys/time.h>

#include "soc_cv_av/socal/socal.h"
#include "soc_cv_av/socal/hps.h"
#include "soc_cv_av/socal/alt_gpio.h"
#include "hwlib.h"
// #include "soc_system.h"
#include "hps_0.h"
#define HW_MEM_BASE ( 0xC0000000 ) //h2f_axi_master base address
#define HW_MEM_OFF  ( 0x00040000 )
#define HW_MEM_SPAN ( 0x08000000 ) //need to modifiy
#define HW_MEM_MASK ( HW_MEM_SPAN - 1 )

#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )


// MASK For communicaiton between hps and fpga
#define MASK_TRIGGER_TO_FPGA ((uint16_t)0x1000)
#define MASK_COMMAND_TYPE_TO_FPGA ((uint16_t)0x0f00)
#define MASK_RESET_MEM ((uint16_t)0x8000)
#define MASK_COMMAND_DATA_TO_FPGA ((uint16_t)0x00FF)
#define MASK_COMMAND_ALL_TO_FPGA ((uint16_t)0x0FFF)
#define MASK_READY_FROM_FPGA ((uint16_t)0x0100)
#define MASK_DATA_FROM_FPGA ((uint16_t)0x7FFF) //data is 15-bit write idx

#define MASK_MEM_CNT ((uint16_t)0x7FFF) //Address is 15 bits,65536 bytes with 32768 blocks
#define SHIFT_MEM_CNT 12
#define GET_MEM_WRITE_IDX(x) (((*(uint16_t *)x)&MASK_MEM_CNT)>>SHIFT_MEM_CNT) //8192  bytes a block, totally 8 blocks for 65536 bytes, also this address points to 16bits cell
#define SHIFT_MEM_IDX_TO_ADDR 12 //here for hps memory cell is 16bits 
#define MAX_IDX_MEM 8
//Communication between TCPIP

#define SIZE_COMMAND_HEADER_TCPIP 1
#define SIZE_COMMAND_DATA_TCPIP 2
#define CMD_COMM_FPGA 1
#define CMD_STREAM_MEM 2
#define CMD_TERMINATE 4
#define GET_CMD_HEADER(x)  x
#define SIZE_TCPIP_SEND_BUF_TRUNK (8192) // 4096 data points, 8192 bytes for one data-sending operation via tcp/ip totally 16 times for one sending

//internal state
#define ST_IDLE 1
#define ST_COMM_FPGA 2
#define ST_STREAM_MEM 3
#define ST_TERMINATE 4

void communicate_fpga (void *, void *, uint16_t * , uint16_t * );

/*
 * Client Main.
 */
int main(argc, argv)
int argc;
char **argv;
{
    unsigned short port;       /* port client will connect to         */
    char buf_tcpip[8];              /* data buffer for sending & receiving */
    struct hostent *hostnm;    /* server host name information        */
    struct sockaddr_in server; /* server address                      */
    int s;                     /* client socket                       */
	int i; 	/*loop index*/
	int idx_send; /* index for tcp/ip data sending times*/

    void *virtual_base;

    void *virtual_base_mem;     /* memory map  FROM  ALT_STM_OFST TO + HW_REGS_SPAN*/
    int fd;                 /* total memory map    */
    void *vaddr_data_hps_to_fpga;  //LED address map pointer
    void *vaddr_data_fpga_to_hps;  //LED address map pointer
    void *vaddr_base_buffer;  //Mmeory base addr
    void *addr_mem_read;  //Memory read and stream pointer tempely


    uint16_t idx_mem_write = 0;
    uint16_t idx_mem_read= idx_mem_write;
    uint8_t st_all;
    uint8_t cmd_from_tcpip;

    char str[20];   //input string
    uint16_t data_to_fpga,data_from_fpga;
    int offset_mem;
    data_to_fpga = 0;

    struct timeval start_time, stop_time,begin_time;
    float delta_us;


    uint16_t idx_row,idx_col;
    uint16_t msb,lsb;
    int data_pixel;
    uint32_t idx_frame;
    uint64_t data_temp,raw_4x;
    char buf_data [ SIZE_TCPIP_SEND_BUF_TRUNK];
    

    // map the address space for the LED registers into user space so we can interact with them.
    // we'll actually map in the entire CSR span of the HPS since we want to access various registers within that span

    if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
        printf( "ERROR: could not open \"/dev/mem\"...\n" );
        return( 1 );
    }

    virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );
    if( virtual_base == MAP_FAILED ) {
        printf( "ERROR: mmap() failed...\n" );
        close( fd );
        return( 1 );
    }


    virtual_base_mem = mmap( NULL, HW_MEM_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_MEM_BASE );
    if( virtual_base == MAP_FAILED ) {
        printf( "ERROR: mmap() failed...\n" );
        close( fd );
        return( 1 );
    }
    //vaddr_data_hps_to_fpga = virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST - HW_REGS_BASE + LED_PIO_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
    //vaddr_data_fpga_to_hps = virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST - HW_REGS_BASE + DIPSW_PIO_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
	vaddr_data_hps_to_fpga = virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + LED_PIO_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
    vaddr_data_fpga_to_hps = virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + DIPSW_PIO_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
    vaddr_base_buffer = virtual_base_mem + ( ( unsigned long  )( HW_MEM_OFF ) & ( unsigned long)( HW_MEM_MASK ) );

    // data_to_fpga = 0x0800;
    // communicate_fpga(vaddr_data_hps_to_fpga, vaddr_data_fpga_to_hps, &data_to_fpga, & data_from_fpga);
    // data_to_fpga = 0x0801;
    // communicate_fpga(vaddr_data_hps_to_fpga, vaddr_data_fpga_to_hps, &data_to_fpga, & data_from_fpga);

    printf("Please input y to connect: "); 
    scanf("%[^\n]%*c", str); 

    // for (idx_frame = 0; idx_frame<(MAX_IDX_MEM*128);++idx_frame) {
    //     addr_mem_read = (uint64_t*)vaddr_base_buffer + idx_frame;
    //     *((uint64_t *)addr_mem_read) = (uint64_t)idx_frame;
    // }
    while( strcmp(str,"y") ) {
        

        printf("Stupid boy!!! Just input y to connect !!!: "); 
        scanf("%[^\n]%*c", str); 


        
    } // while


    /*
     * Check Arguments Passed. Should be hostname and port.
     */
    if (argc != 3)
    {
        fprintf(stderr, "Usage: %s hostname port\n", argv[0]);
        exit(1);
    }

    /*
     * The host name is the first argument. Get the server address.
     */
    hostnm = gethostbyname(argv[1]);
    if (hostnm == (struct hostent *) 0)
    {
        fprintf(stderr, "Gethostbyname failed\n");
        exit(2);
    }

    /*
     * The port is the second argument.
     */
    port = (unsigned short) atoi(argv[2]);


    /*
     * Put the server information into the server structure.
     * The port must be put into network byte order.
     */
    server.sin_family      = AF_INET;
    server.sin_port        = htons(port);
    server.sin_addr.s_addr = *((unsigned long *)hostnm->h_addr);

    /*
     * Get a stream socket.
     */
    if ((s = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        perror("Socket()");
        exit(3);
    }


    /*
     * Put a message into the buffer.
     */
    for ( i = 0; i < sizeof(buf_tcpip); ++i)
    {
    	buf_tcpip[i]=((uint8_t)'0' + i%10);
    	/* code */
    }
    /*
     * Connect to the server.
     */

    printf("hostname %sport %s connecting\n", argv[1], argv[2]);
    if (connect(s, (struct sockaddr *)&server, sizeof(server)) < 0)
    {
        perror("Connect()");
        exit(4);
    }

    printf("hostname %sport %s connected\n", argv[1], argv[2]);

    idx_mem_write= GET_MEM_WRITE_IDX(vaddr_data_fpga_to_hps); //get current memory write addr
    idx_mem_read = idx_mem_write;
    st_all = ST_IDLE;
    while(st_all != ST_TERMINATE){
        switch (st_all){
            case ST_IDLE:
                buf_tcpip[0]=0;
				idx_send=0;
                recv(s, (uint8_t *)buf_tcpip, SIZE_COMMAND_HEADER_TCPIP, 0);
                cmd_from_tcpip = * ((uint8_t *) buf_tcpip);
                 printf("Command recieved from tcpip is %02X\n", cmd_from_tcpip);
                switch (GET_CMD_HEADER(cmd_from_tcpip)){
/*                     case CMD_COMM_FPGA:
                        st_all = ST_COMM_FPGA;
                    break; */

                    case CMD_TERMINATE:
                        st_all = ST_TERMINATE;
                    break;

                    case CMD_STREAM_MEM:     
                        st_all = ST_STREAM_MEM;
                        gettimeofday(&begin_time, NULL);
                    break;
                    default: 
                        st_all = ST_IDLE;
                    break;
                }
            break;
/*             case ST_COMM_FPGA:
                printf("Command data recieved from tcpip is ");
                recv(s, buf_tcpip, SIZE_COMMAND_DATA_TCPIP, 0); //recieve data to be sent 16b
                printf("%04X\n", *(uint16_t *)buf_tcpip);
                data_to_fpga = *(uint16_t *)buf_tcpip;
                communicate_fpga(vaddr_data_hps_to_fpga, vaddr_data_fpga_to_hps, &data_to_fpga, & data_from_fpga);
                send(s, (uint8_t *)& data_from_fpga, SIZE_COMMAND_DATA_TCPIP, 0);  //response back

                st_all = ST_IDLE;

            break; */
            case ST_STREAM_MEM:

                // gettimeofday(&start_time, NULL);
			    communicate_fpga(vaddr_data_hps_to_fpga, vaddr_data_fpga_to_hps, &data_to_fpga, & data_from_fpga);

                idx_mem_write= GET_MEM_WRITE_IDX(vaddr_data_fpga_to_hps); //get current memory write addr
            
                 printf("idx mem write %d\n", idx_mem_write);
                 printf("idx mem read %d\n", idx_mem_read);

                //check if current data is ready
                 while (((idx_mem_read>=(idx_mem_write-4))  && (idx_mem_write >=idx_mem_read)) || 
                    ((idx_mem_read>= (idx_mem_write+MAX_IDX_MEM-4))&& (idx_mem_write <idx_mem_read))){
				     communicate_fpga(vaddr_data_hps_to_fpga, vaddr_data_fpga_to_hps, &data_to_fpga, & data_from_fpga);
                     idx_mem_write= GET_MEM_WRITE_IDX(vaddr_data_fpga_to_hps);
					 printf("idx mem write %d\n", idx_mem_write);
                     printf("idx mem read %d\n", idx_mem_read);
                 }
                // printf("Read address offset is %04X", (idx_mem_read << SHIFT_MEM_IDX_TO_ADDR));
                // printf("Read index is %04X", (idx_mem_read));

                printf("Begin Write index is %04X\n", (idx_mem_write));
                printf("End Read index is %04X\n", (idx_mem_read));
                addr_mem_read = (uint16_t*)vaddr_base_buffer + (idx_mem_read << SHIFT_MEM_IDX_TO_ADDR);
                // memcpy((void *)buf_data,addr_mem_read,SIZE_TCPIP_SEND_BUF_TRUNK);

                //send via tcpip , one block (8196) bytes each packet.--4096 data points every time
                send(s, addr_mem_read, SIZE_TCPIP_SEND_BUF_TRUNK, 0) ;
				printf("read fpga memory data is %d\n", (*(uint16_t*)addr_mem_read));
                //increment memory read index
                idx_mem_read = idx_mem_read +1;
                if (idx_mem_read >= MAX_IDX_MEM) {
                    idx_mem_read = 0;
                }
                // gettimeofday(&stop_time, NULL);
                // delta_us = (stop_time.tv_sec - start_time.tv_sec) * 1000000 + (stop_time.tv_usec  - start_time.tv_usec);

                // printf("Time spend for this cycle is  %4.2f ", (delta_us));
                // delta_us = (stop_time.tv_sec - begin_time.tv_sec) * 1000000 + (stop_time.tv_usec  - begin_time.tv_usec);
                // printf("Total time spent from begining is %4.2f\n", (delta_us));
				idx_send++;
				if(idx_send<1024){  //this number determins total FFT number,16 for 65536(4096*16),512 for 2097152, thus, frequency res. is around 0.6Hz
					st_all = ST_STREAM_MEM;
				}
				else {
					st_all = ST_IDLE;
				}

                // printf("End of send Write index is %04X\n", (idx_mem_write));

            break;
            default :
                st_all = ST_IDLE;
            break;
            }

    }


	close(s); //close socket


    // clean up our memory mapping and exit
    if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
        printf( "ERROR: munmap() failed for LWio...\n" );
        close( fd );
        return( 1 );
    }
    if( munmap( virtual_base_mem, HW_MEM_SPAN ) != 0 ) {
        printf( "ERROR: munmap() failed for mem...\n" );
        close( fd );
        return( 1 );
    }
    close( fd );


    printf("Test finish Successfully\n");
    exit(0);
    return 0;

}

void communicate_fpga (void *ptr_tx, void *ptr_rx, uint16_t * data_to_fpga, uint16_t * data_from_fpga){



  //  *(uint32_t *)ptr_tx = ((uint32_t )*data_to_fpga) & ~MASK_TRIGGER_TO_FPGA; // turn off trigger
  //  *(uint32_t *)ptr_tx = ((uint32_t )*data_to_fpga) | MASK_TRIGGER_TO_FPGA; // trigger communication

  //      printf ("Data write to fpga is %08X\n",(*(uint32_t *) ptr_tx));
  //  while (0 == ((*(uint32_t *) ptr_rx) & MASK_READY_FROM_FPGA)){ //wait response ready
        // printf ("Data read from fpga is %08X\n",(*(uint32_t *) ptr_rx));
  //  }
    *data_from_fpga =(uint16_t) (*(uint16_t *)ptr_rx & MASK_DATA_FROM_FPGA); // receive data

  //  *(uint32_t *)ptr_tx = ((uint32_t )*data_to_fpga) & ~MASK_TRIGGER_TO_FPGA; // turn off trigger

    printf ("Data read from fpga is %08X\n",(*(uint32_t *) ptr_rx));
}