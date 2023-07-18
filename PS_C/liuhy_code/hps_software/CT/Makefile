#
TARGET = test_hlmc_ct

#
CROSS_COMPILE = arm-linux-gnueabihf-

#CROSS_COMPILE = arm-altera-eabi-

INC_PATH1=/cygdrive/d/intelFPGA/17.1/embedded/ip/altera/hps/altera_hps/hwlib/include/
INC_PATH2=/cygdrive/d/intelFPGA/17.1/embedded/host_tools/cygwin/usr/include/

INC=-I${INC_PATH1} -I${INC_PATH2}
#CFLAGS = -static -g -Wall -I${INC_PATH1} -I${INC_PATH2} #-I/cygdrive/C/intelFPGA/18.1/embedded/host_tools/cygwin/usr/include
CFLAGS = -static -g -Wall -I ${SOCEDS_DEST_ROOT}/ip/altera/hps/altera_hps/hwlib/include
LDFLAGS =  -g -Wall  
CC = $(CROSS_COMPILE)gcc
ARCH= arm


build: $(TARGET)
$(TARGET): main.o 
	$(CC) $(LDFLAGS)   $^ -o $@  
%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(TARGET) *.a *.o *~ 
