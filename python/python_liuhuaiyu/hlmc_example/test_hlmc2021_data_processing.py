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
import shutil

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
MASK_SIGN=0b00010000
MASK_LSB_P=0b11110000

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
    osr=128 
    fres=fs/len_fft #bin width for frequency resolution
    sigband_bins=1+round((fs/(2*osr))/fres)
    #sigband_bins=1+round(50000/fres)
    sigband_power=fres*sum(fft_data[psd_window:sigband_bins])
    sig_bin=1+round(sin_freq/fres)
    sig_bin_min=max(1,sig_bin-psd_window)
    sig_bin_max=sig_bin+psd_window
    sig_power=fres*sum(fft_data[sig_bin_min:sig_bin_max])
    dc_power=fres*sum(fft_data[psd_window:round(1000/fres)])
    sndr=np.sqrt(sig_power/(sigband_power-sig_power-dc_power))
    sndr_db=20*np.log10(sndr)
    enob=(sndr_db-1.76)/6.02
    return (fft_freq.tolist(),fft_data.tolist(),sndr_db,enob)
 
desdir = r"d:\adc_results"
strPathSave = desdir +"/" +"data_save"
    
str_file_read = strPathSave+ "/" + "ADC_DATA_SAVED_1" + ".bin"
with open(str_file_read, mode='rb') as h_file_results:
    array_adc_data_rec1=[]
    array_adc_data_rec2=[]
    array_adc_data_rec3=[]
    array_adc_data_rec4=[]
    array_adc_data_rec5=[]
    array_adc_data_rec6=[]
    array_adc_data_rec7=[]
    data = h_file_results.read(BYTES_FILE)          
    adc_data_rec = [] #recovered adc data
    for idx_bytes in range(0,len(data),2):
        adc_data_rec1=((data[idx_bytes] & MASK_LSB_P)>>4)
        adc_data_rec2=(((data[idx_bytes] & MASK_LSB_N))+0)
        adc_data_rec3=(data[idx_bytes+1] & MASK_CNT)
        adc_data_rec4=adc_data_rec1-adc_data_rec2
        adc_data_rec5=(((data[idx_bytes+1] & MASK_CNT))*2 -13)/15 \
                      +( ((((data[idx_bytes] & MASK_LSB_P)>>4)\
                      - (data[idx_bytes] & MASK_LSB_N))*1.375)/225) 
        adc_data_rec6=(((data[idx_bytes] & MASK_LSB_P)>>4)\
                      - (data[idx_bytes] & MASK_LSB_N))/15
        adc_data_rec7=(data[idx_bytes+1] & MASK_SIGN)>>4
        array_adc_data_rec1.append(adc_data_rec1) 
        array_adc_data_rec2.append(adc_data_rec2) 
        array_adc_data_rec3.append(adc_data_rec3)  
        array_adc_data_rec4.append(adc_data_rec4)
        array_adc_data_rec5.append(adc_data_rec5)
        array_adc_data_rec6.append(adc_data_rec6)
        array_adc_data_rec7.append(adc_data_rec7)                
    h_file_results.close()


plt.suptitle('2-order VCO based ADC Test',fontsize=30)
#(axTime, axFreq) = plt.subplots(1, 2)
axTime1 = plt.subplot(4, 2, 1)
axTime2 = plt.subplot(4, 2, 3)
axTime3 = plt.subplot(4, 2, 4)
axTime4 = plt.subplot(4, 2, 2)
axTime5 = plt.subplot(4, 2, 5)
axTime7 = plt.subplot(4, 2, 6)
axFreq = plt.subplot(4, 2, 7)
fs = 2560000
colors = ['b', 'g', 'r', 'c', 'm', 'xkcd:neon green', 'k', 'xkcd:tan', 'xkcd:grey', 'xkcd:peach']
list_time_plot = list([a/fs for a in range(NUM_DATA_POINTS_READ)])
#list_freq_plot = list([(a+1)*fs/num_frames_read for a in range(int(float(num_frames_read)/2))])
axTime1.plot(list_time_plot,\
                         array_adc_data_rec1,c=colors[0],label="Time Domain")
axTime2.plot(list_time_plot,\
                         array_adc_data_rec2,c=colors[1],label="Time Domain")
axTime3.plot(list_time_plot,\
                         array_adc_data_rec3,c=colors[2],label="Time Domain")
axTime4.plot(list_time_plot,\
                         array_adc_data_rec4,c=colors[3],label="Time Domain")
axTime5.plot(list_time_plot,\
                         array_adc_data_rec5,c=colors[4],label="Time Domain")
axTime7.plot(list_time_plot,\
                         array_adc_data_rec7,c=colors[5],label="Time Domain")
list_freq_plot,fft_recording,sndr_db,enob=fft_clean(array_adc_data_rec6,fs,2,6015.6,8)
axFreq.plot(list_freq_plot,\
                          fft_recording,c=colors[6],label="FFT")
#plt.show()
sndr_result_text='SNDR = '+format(sndr_db,'0.2f')+'dB \n ENOB = '+format(enob,'0.2f')
axTime1.set_title('Time Domain Waveform',fontsize=20)
axTime1.set_xlabel('Time',fontsize=20)
axTime1.set_ylabel('Recovered Data',fontsize=20)
#axTime.set_ylim([-0.3,0.3])

axFreq.set_title('FFT Result \n'+sndr_result_text,fontsize=20)
axFreq.set_xlabel('Frequency',fontsize=20)
axFreq.set_ylabel('PSD',fontsize=20)    
axFreq.set_yscale('log')
axFreq.set_xscale('log') 
axFreq.set_xlim([fs/NUM_DATA_POINTS_READ/4,fs/2])
#axFreq.text(100,1,sndr_result_text)
plt.pause(1)
#plt.clf()

