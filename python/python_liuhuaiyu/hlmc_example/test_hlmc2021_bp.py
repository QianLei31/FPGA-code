# -*- coding: utf-8 -*-
"""
Created on Thu Apr 18 14:42:01 2019

@author: huaiyu
"""

import csv
import sys
import socket
import numpy as np
import time
import datetime
import os
from scipy import signal

import matplotlib.pyplot as plt

#CMD_COMM_FPGA=1
CMD_STREAM_MEM=2
CMD_TERMINATE=4

# HEADER_SPI_DAC = 0x01
# HEADER_SPI_DUT = 0x00
# HEADER_RESET_DAC = 0x03
# HEADER_RESET_DUT = 0x02
# HEADER_READ_MEM = 0x05y
# NUM_ROWS=32
# NUM_COLS=32
# NUM_PIXELS = NUM_ROWS * NUM_COLS
# BYTES_PER_PIXEL = 2
SIZE_TCPIP_SEND_BUF_TRUNK=8192
BYTES_DATA_POINTS=2
NUM_DATA_POINTS_READ=65536
BYTES_FILE=NUM_DATA_POINTS_READ*BYTES_DATA_POINTS
#BYTES_FRAME = NUM_PIXELS * BYTES_PER_PIXEL


# MASK_SIGN_LSB = 0b00100000
MASK_LSB_N=0b00001111
MASK_CNT=0b00001111
MASK_LSB_P=0b11110000

# CMD_WRITE_FPGA_REG=0b1000;

def fft_clean(data_time,fs,num_fftavg):  #do multiple times and get average fft results
    data_time = np.asarray(data_time)
    len_fft=int(round(len(data_time)/num_fftavg)) #divide the time-domain data
    avgdata=sum(data_time)/float(len(data_time))
    data_norm=data_time-avgdata
    len_fftdisplay=int(round(len_fft/2))
    
    fft_data=np.array([0]*(len_fftdisplay))
    ffttemp=np.array([0]*(len_fftdisplay))
    #w = signal.flattop(len_fft-1)    these are the windows
   # w=1
    w=signal.blackmanharris(len_fft-1, sym=False)
    for ii in range(num_fftavg):
        ffttemp=abs(np.fft.fft(np.multiply(data_norm[ii*len_fft:(ii+1)*len_fft-1],w)))[0:len_fftdisplay] #we only use half the data
#        ffttemp=abs(np.fft.fft(data_norm[ii*len_fft:(ii+1)*len_fft-1]))[0:len_fftdisplay]
        fft_data=fft_data+(ffttemp)**2
#    fft_data=fft_data/num_fftavg/(len_fft**2)
#    fft_data=fft_data/num_fftavg/(len_fft)/fs
    fft_data=fft_data/num_fftavg/(len_fftdisplay) ## why divided by lenth of data? scale?
    resolution=fs/len_fft
    fft_freq=np.linspace(resolution,round(fs/2),num=len_fftdisplay) #we can also use np.fft.fft_freq 
    return (fft_freq.tolist(),fft_data.tolist())
    

def send_tcpip (conn,data_to_send):
    totalsent = 0
    while totalsent < len(data_to_send):
        sent = conn.send(data_to_send[totalsent:])
        if sent == 0:
            raise RuntimeError("socket connection broken")
        totalsent = totalsent + sent
    return totalsent
        
def recieve_tcpip (conn,num_to_recieve,max_attemp=-1):
    
    cnt_attemp=0
    data=bytearray()
    while ((num_to_recieve >0) and (cnt_attemp<=max_attemp or max_attemp==-1)):
        rx_data = []
        cnt_attemp = cnt_attemp + 1
        
        rx_data = conn.recv(min(num_to_recieve,SIZE_TCPIP_SEND_BUF_TRUNK))
        if rx_data == b'':
                raise RuntimeError("socket connection broken")
        
#            print("Unexpected error:", sys.exc_info())
        data.extend(rx_data) 
        len_recv_data=len(rx_data)
            
             
        num_to_recieve=num_to_recieve-len_recv_data
    return data
        
        
HOST = '192.168.31.77'  # Standard loopback interface address (localhost)
PORT = 8170        # Port to listen on (non-privileged ports are > 1023)

data=[]

size_packet=1
if 's' in globals():
    s.close()
    del s
s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind((HOST, PORT))
s.listen(1)
s.settimeout(1)
s.setblocking(False) 

done_ini = 0


while done_ini !=1:
    try:             
        conn, addr=s.accept()
        print(addr)
        conn.settimeout(1)
        done_ini=1
    except:
        done_ini=0
        None
#        print("Unexpected error when accept:", sys.exc_info())
print("Connected!")       
# #dac setup
# done_ini = 0;      
# len_remain_data = 8*8  
# cnt_data=0.0;
# len_data=0.0;
# data=[]
# data16k=[]
# rx_data=[]

# dacArr=[1.5,#isfet vdd
        # 2.49,#vref Iin
        # 1.5,# vss
        # 2.47,#Irefc2f
        # 0, #avddc2f
        # 1.50, #irefi = v/3k
        # 1.1, #avcom also for vref in triangle
        # 2.4,# irefn
        # ]

# list_dac_cmd = dac_value_to_cmd(dacArr)
# #print(list_dac_cmd)
    
# for cmd_now in list_dac_cmd:
    # int_input = cmd_now
    # send_tcpip(conn,bytearray([CMD_COMM_FPGA,int_input %256, int_input>>8 % 256]))
    # data=recieve_tcpip (conn,2)
    # time.sleep(0.001)
    
    
#    print('Response for DAC setting is '+str(data))
done_ini = 1;
        

# cmd_set=[]
# cmd_set.extend([0x0040,0x000e,0x0000]) #ratio to 1
# cmd_set.extend([0x0040,0x0005,0x0002]) #ds slewrate of do
# cmd_set.extend([0x0040,0x0006,0x0002]) #ds slewrate of po
# cmd_set.extend([0x0040,0x000b,0x0002]) #ds slewrate of clks
# cmd_set.extend([0x0040,0x000c,0x0002]) #ds slewrate of swflga

# cmd_set.extend([(CMD_WRITE_FPGA_REG<<8)+0,(CMD_WRITE_FPGA_REG<<8)+1]) #RESET AND SET

# cmd_set.extend([(CMD_WRITE_FPGA_REG<<8)+0,(CMD_WRITE_FPGA_REG<<8)+0]) #RESET AND SET

# for cmd_now in cmd_set:
    # int_input = cmd_now
    # send_tcpip(conn,bytearray([CMD_COMM_FPGA,int_input %256, int_input>>8 % 256]))
    # recieve_tcpip (conn,2)
    # time.sleep(0.001)
    
    
str_input=input('Please input y to stream ADC DATA  \n')
while str_input[0] != 'y':
	str_input=input('Stupid boy!!! Just input y to continue!!!:  \n')
# len_remain_data = 2
# while str_input[0] != 'n':
    # try:             
        # cnt_data=0.0;
        # len_data=0.0;
        # data=[]
        # data16k=[]
        # rx_data=[]
        
        # int_input = int('0x'+str_input,0)
        
        # send_tcpip(conn,bytearray([CMD_COMM_FPGA,int_input %256, int_input>>8 % 256]))
        # data=recieve_tcpip(conn,len_remain_data)
        # str_input=input('Enter data to be sent, n for stop \n');
        
        
    # except:
        # print("Unexpected error:", sys.exc_info())
        # str_input=input('Enter data to be sent, n for stop \n');
        
print("Start to read ADC DATA continously\n")
len_remain_data = SIZE_TCPIP_SEND_BUF_TRUNK
cnt_read_mem = 0
desdir = r"d:\adc_results"
time_start    =  datetime.datetime.now()
strPathSave = desdir +"/" + time_start.strftime("%Y%m%d")+"/"+time_start.strftime("%H%M%S")
os.makedirs(strPathSave, exist_ok=True)

time_start    =  datetime.datetime.now()

send_tcpip(conn,bytearray([CMD_STREAM_MEM]))


data_all=bytearray()

#can add a big while loop here to plot continuously

while cnt_read_mem < (NUM_DATA_POINTS_READ * BYTES_DATA_POINTS / SIZE_TCPIP_SEND_BUF_TRUNK):
    data=bytearray()
    rx_data=[]
    #send_tcpip(conn,bytearray([CMD_STREAM_MEM]))
    data = recieve_tcpip (conn,len_remain_data)
    if (len(data)!=len_remain_data):
        print("Generated data file has data length of{:d} ".format(len(data)))
    data_all.extend(data)

    str_file_write= strPathSave+  "/"+ "ADC_DATA_"+".bin"
    
    #if ((cnt_read_mem%FRAMES_PER_FILE) == FRAMES_PER_FILE-1):
    with open(str_file_write,"ab+") as h_file_results:
        h_file_results.write(data_all)
        data_all=bytearray()
        h_file_results.close()
                
    cnt_read_mem = cnt_read_mem + 1
        

time_end =  datetime.datetime.now()
print("Speed transmisson for total data {:4f}  bytes is {:06.4f}MBytesPSec".\
      format(NUM_DATA_POINTS_READ * BYTES_DATA_POINTS,\
      NUM_DATA_POINTS_READ * BYTES_DATA_POINTS/\
      ((time_end-time_start).seconds*1000000+(time_end-time_start).microseconds)))


#process files and plots

#read files and recover data points

# here we only have 1 file

# str_file_read = str_file_write
# with open(str_file_read, mode='rb') as h_file_results:
#     array_adc_data_rec=[]
#     data = h_file_results.read(BYTES_FILE)          
#     adc_data_rec = [] #recovered adc data
#     for idx_bytes in range(0,len(data),2):
#         adc_data_rec=((data[idx_bytes+1] & MASK_CNT) << 4)\
#                     + ((data[idx_bytes] & MASK_LSB_P)>>4)\
#                     - (data[idx_bytes] & MASK_LSB_N)
#         array_adc_data_rec.append(adc_data_rec)               
#     h_file_results.close()

#dummy data read
str_file_read = str_file_write
with open(str_file_read, mode='rb') as h_file_results:
    array_adc_data_rec=[]
    data = h_file_results.read(BYTES_FILE)         
    adc_data_rec = [] #recovered adc data
    for idx_bytes in range(0,len(data),2):
        adc_data_rec=(data[idx_bytes+1] <<8 )+(data[idx_bytes]) 
        array_adc_data_rec.append(adc_data_rec)               
    h_file_results.close()



plt.close('all')
#fig1 = plt.figure(figsize=(12, 6))
fig1, (axTime, axFreq) = plt.subplots(1, 2)
plt.figure(fig1.number)
fs = 1280000
colors = ['b', 'g', 'r', 'c', 'm', 'xkcd:neon green', 'k', 'xkcd:tan', 'xkcd:grey', 'xkcd:peach']
list_time_plot = list([a/fs for a in range(NUM_DATA_POINTS_READ)])
#list_freq_plot = list([(a+1)*fs/num_frames_read for a in range(int(float(num_frames_read)/2))])
axTime.plot(list_time_plot,\
                         array_adc_data_rec,c=colors[0],label="Time Domain")
list_freq_plot,fft_recording=fft_clean(array_adc_data_rec,fs,4)
axFreq.plot(list_freq_plot,\
                         fft_recording,c=colors[1],label="FFT")
plt.show()
axFreq.set_yscale('log')
axFreq.set_xscale('log')
#axFreq.set_xscale('linear')
axFreq.set_xlim([fs/NUM_DATA_POINTS_READ/4,fs/2])
# axFreq.set_ylim([0,256]) #should modify it according to the real data

#plot recovered data and fft results

send_tcpip(conn,bytearray([CMD_TERMINATE]))
s.close()