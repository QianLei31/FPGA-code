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
#NUM_DATA_POINTS_READ=65536*16 #2.5Hz
NUM_DATA_POINTS_READ=65536*4 #10Hz
#NUM_DATA_POINTS_READ=65536 #40Hz
#NUM_DATA_POINTS_READ=4096*1024 #0.6Hz
BYTES_FILE=NUM_DATA_POINTS_READ*BYTES_DATA_POINTS
#BYTES_FRAME = NUM_PIXELS * BYTES_PER_PIXEL


# MASK_SIGN_LSB = 0b00100000
MASK_VCOP=0b00000100
MASK_VCON=0b00000010
MASK_LC_PATTERN=0b00000001
MASK_UP=0b11110000
MASK_CAL_STATE=0b11110000
MASK_CHIP_RST=0b00001000
MASK_DN=0b00001111


# CMD_WRITE_FPGA_REG=0b1000;

def fft_clean(data_time,fs,num_fftavg,sin_freq,psd_window):  #do multiple times and get average fft results    
    data_time = np.asarray(data_time)
    len_fft=int(round(len(data_time)/num_fftavg)) #divide the time-domain data
    avgdata=sum(data_time)/float(len(data_time))
    data_norm=data_time-avgdata
    len_fftdisplay=int(round(len_fft/2))
    
    fft_data=np.array([0]*(len_fftdisplay))
    ffttemp=np.array([0]*(len_fftdisplay))
    #w = signal.flattop(len_fft-1)    these are the windows
    #w=1
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
    osr=64 
    fres=fs/len_fft #bin width for frequency resolution
    sigband_bins=1+round((fs/(2*osr))/fres)
    #sigband_bins=1+round(50000/fres)
    sigband_power=fres*sum(fft_data[psd_window:sigband_bins])
    sig_bin=1+round(sin_freq/fres)
    sig_bin_min=max(1,sig_bin-psd_window)
    sig_bin_max=sig_bin+psd_window
    sig_power=fres*sum(fft_data[sig_bin_min:sig_bin_max])
    dc_power=fres*sum(fft_data[psd_window:round(1/fres)])
    sndr=np.sqrt(sig_power/(sigband_power-sig_power-dc_power))
    sndr_db=20*np.log10(sndr)
    enob=(sndr_db-1.76)/6.02
    return (fft_freq.tolist(),fft_data.tolist(),sndr_db,enob)
    

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
desdir = r"d:\adc_results"
strPathSave = desdir +"/" +"test_ct"
os.makedirs(strPathSave, exist_ok=True)

#send_tcpip(conn,bytearray([CMD_STREAM_MEM]))


data_all=bytearray()

#can add a big while loop here to plot continuously

plt.ion() #open plot window
plt.rcParams['figure.figsize']=(20, 15)

while (True):
    send_tcpip(conn,bytearray([CMD_STREAM_MEM]))
    cnt_read_mem = 0
    time_start    =  datetime.datetime.now()
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
            if (cnt_read_mem == 0):#delete the old data
                  h_file_results.seek(0)
                  h_file_results.truncate()
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
    #         adc_data_rec=(((data[idx_bytes+1] & MASK_CNT))*2 -13)/15 \
    #                       +( ((((data[idx_bytes] & MASK_LSB_P)>>4)\
    #                       - (data[idx_bytes] & MASK_LSB_N))*1.25)/240)
    #         # adc_data_rec= (( ((((data[idx_bytes] & MASK_LSB_P)>>4)\
    #         #              - (data[idx_bytes] & MASK_LSB_N)*1.25))/240))                             
    #         array_adc_data_rec.append(adc_data_rec)               
    #     h_file_results.close()

    # Only MSB
    # str_file_read = str_file_write
    # with open(str_file_read, mode='rb') as h_file_results:
    #     array_adc_data_rec=[]
    #     data = h_file_results.read(BYTES_FILE)          
    #     adc_data_rec = [] #recovered adc data
    #     for idx_bytes in range(0,len(data),2):
    #         adc_data_rec=(((data[idx_bytes+1] & MASK_CNT)))                            
    #         array_adc_data_rec.append(adc_data_rec)               
    #     h_file_results.close()
    
 
    #only LSB
    str_file_read = str_file_write
    with open(str_file_read, mode='rb') as h_file_results:
        array_adc_data_rec1=[]
        array_adc_data_rec2=[]
        array_adc_data_rec3=[]
        array_adc_data_rec4=[]
        array_adc_data_rec5=[]
        array_adc_data_rec6=[]
        array_adc_data_rec7=[] #CAL_STATE
        array_adc_data_rec8=[] #CHIP_RST
        data = h_file_results.read(BYTES_FILE)          
        adc_data_rec = [] #recovered adc data
        for idx_bytes in range(0,len(data),2):
            adc_data_rec1=((data[idx_bytes+1] & MASK_VCOP)>>2)
            adc_data_rec2=((data[idx_bytes+1] & MASK_VCON)>>1)
            adc_data_rec3=(data[idx_bytes+1] & MASK_LC_PATTERN)
            adc_data_rec4=(data[idx_bytes]& MASK_UP)>>4
            adc_data_rec5=(data[idx_bytes]& MASK_DN)
            adc_data_rec6=(adc_data_rec4-adc_data_rec5)/11
            adc_data_rec7=((data[idx_bytes+1] & MASK_CAL_STATE)>>4)
            adc_data_rec8=((data[idx_bytes+1] & MASK_CHIP_RST)>>3)
            array_adc_data_rec1.append(adc_data_rec1) 
            array_adc_data_rec2.append(adc_data_rec2) 
            array_adc_data_rec3.append(adc_data_rec3)  
            array_adc_data_rec4.append(adc_data_rec4)
            array_adc_data_rec5.append(adc_data_rec5)
            array_adc_data_rec6.append(adc_data_rec6)
            array_adc_data_rec7.append(adc_data_rec7)
            array_adc_data_rec8.append(adc_data_rec8)              
        h_file_results.close()
    
    #dummy data read
    # str_file_read = str_file_write
    # with open(str_file_read, mode='rb') as h_file_results:
    #     array_adc_data_rec=[]
    #     data = h_file_results.read(BYTES_FILE)         
    #     adc_data_rec = [] #recovered adc datay
    #     for idx_bytes in range(0,len(data),2):
    #         adc_data_rec=(data[idx_bytes+1] <<8 )+(data[idx_bytes]) 
    #         array_adc_data_rec.append(adc_data_rec)               
    #     h_file_results.close()
    
    
    #plot recovered data and fft results
    
    #plt.close('all')
    plt.clf()
    plt.suptitle('Impedance Boosted VCO-based CTDSM Test',fontsize=30)
    #(axTime, axFreq) = plt.subplots(1, 2)
    axTime1 = plt.subplot(4, 2, 1)
    axTime2 = plt.subplot(4, 2, 3)
    axTime3 = plt.subplot(4, 2, 5)
    axTime7 = plt.subplot(4, 2, 7)
    axTime4 = plt.subplot(4, 2, 2)
    axTime5 = plt.subplot(4, 2, 4)
    axTime6 = plt.subplot(4, 2, 6)
    axFreq = plt.subplot(4, 2, 8)
    fs = 1280000
    colors = ['b', 'g', 'r', 'c', 'm', 'xkcd:neon green', 'k', 'xkcd:tan', 'xkcd:grey', 'xkcd:peach']
    list_time_plot = list([a/fs for a in range(NUM_DATA_POINTS_READ)])
    list_time_plot2 = list([a/fs for a in range(65535)])
    adc_data_to_filter=array_adc_data_rec6[0:67535]
    sos = signal.butter(8,[10,5000],'bandpass',fs=2560000,output='sos') # 16k low pass   2-order
    adc_data_filtered = signal.sosfilt(sos, adc_data_to_filter)
    VPP_data=((max(adc_data_filtered[1000:66535])-min(adc_data_filtered[1000:66535]))/12)*1000
    #list_freq_plot = list([(a+1)*fs/num_frames_read for a in range(int(float(num_frames_read)/2))])
    axTime1.plot(list_time_plot2,\
                             adc_data_filtered[1000:66535],c=colors[0],label="Time Domain")
    axTime2.plot(list_time_plot,\
                             array_adc_data_rec3,c=colors[1],label="Time Domain")
    axTime3.plot(list_time_plot,\
                             array_adc_data_rec8,c=colors[2],label="Time Domain")
    axTime4.plot(list_time_plot,\
                             array_adc_data_rec4,c=colors[3],label="Time Domain")
    axTime5.plot(list_time_plot,\
                             array_adc_data_rec5,c=colors[4],label="Time Domain")
    axTime6.plot(list_time_plot,\
                             array_adc_data_rec6,c=colors[5],label="Time Domain")
    axTime7.plot(list_time_plot,\
                             array_adc_data_rec7,c=colors[6],label="Time Domain")
    list_freq_plot,fft_recording,sndr_db,enob=fft_clean(array_adc_data_rec6,fs,1,2890.625,8)
    axFreq.plot(list_freq_plot,\
                              fft_recording,c=colors[6],label="FFT")
    #plt.show()
    sndr_result_text='SNDR = '+format(sndr_db,'0.2f')+'dB  ENOB = '+format(enob,'0.2f')
    amplitude_result_text='Vpp = '+format(VPP_data,'0.2f')+'mV'
    # axTime1.set_title('Time Domain Waveform',fontsize=20)
    # axTime1.set_xlabel('Time',fontsize=20)
    axTime1.set_ylabel('LOW PASSED DATA',fontsize=20)
    axTime2.set_ylabel('LC_PATTERN',fontsize=20)
    axTime3.set_ylabel('CHIP_RST',fontsize=20)
    axTime4.set_ylabel('UP_DATA',fontsize=20)
    axTime5.set_ylabel('DN_DATA',fontsize=20)
    axTime6.set_ylabel('RECOVERED DATA',fontsize=20)
    axTime7.set_ylabel('CAL_STATE',fontsize=20)
    axTime1.set_title(amplitude_result_text,fontsize=20)


    axFreq.set_title(sndr_result_text,fontsize=20)
    axFreq.set_xlabel('Frequency',fontsize=20)
    axFreq.set_ylabel('PSD',fontsize=20)    
    axFreq.set_yscale('log')
    axFreq.set_xscale('log') 
    axFreq.set_xlim([fs/NUM_DATA_POINTS_READ/4,fs/2])
    #axFreq.text(100,1,sndr_result_text)
    plt.pause(1)
 



send_tcpip(conn,bytearray([CMD_TERMINATE]))
s.close()
