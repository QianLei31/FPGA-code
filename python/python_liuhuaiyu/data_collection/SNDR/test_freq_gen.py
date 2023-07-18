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

FFT_POINTS=65536
Fs=1280000

ideal_freq_array=np.asarray([300,1000,2000,3000,4000,5000,6000,7000,8000,9000])

array_real_freq=[]

for ideal_freq in ideal_freq_array:
    real_freq=round(ideal_freq/(Fs/FFT_POINTS))*(Fs/FFT_POINTS)
    array_real_freq.append(real_freq)
    