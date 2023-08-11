import socket
import binascii
from matplotlib.offsetbox import AnchoredText
import matplotlib.pyplot as plt
import tkinter as tk
import os
import datetime
import time
import numpy as np

HOST = '192.168.2.10'  
PORT = 7 
SIZE_TCPIP_SEND_BUF_TRUNK=4096
BYTES_DATA_POINTS=2
ADC_bits=12
len_remain_data = SIZE_TCPIP_SEND_BUF_TRUNK
TCP_TOTAL=1*1024*1024
dt_read_cnt=15
ct_read_cnt=15
NUM_DATA_POINTS_READ=dt_read_cnt*SIZE_TCPIP_SEND_BUF_TRUNK//4
Count_max=TCP_TOTAL//(ct_read_cnt*SIZE_TCPIP_SEND_BUF_TRUNK)
'''
desdir = r"d:\testchip_results"
strPathSave = desdir +"/" +"NL"
os.makedirs(strPathSave, exist_ok=True)
str_file_write= strPathSave+  "/"+ "ADC_DATA"+".bin"
cnt_read_mem = 0
data_all=bytearray()
time_start    =  datetime.datetime.now()
while cnt_read_mem < (NUM_DATA_POINTS_READ * BYTES_DATA_POINTS / SIZE_TCPIP_SEND_BUF_TRUNK):
    data=bytearray()
    data = bytearray()
    if (len(data)!=len_remain_data):
        print("Generated data file has data length of{:d} ".format(len(data)))
    data_all.extend(data)
    cnt_read_mem = cnt_read_mem + 1
with open(str_file_write,"ab+") as h_file_results:
    h_file_results.write(data_all)
    h_file_results.close()              
time_end =  datetime.datetime.now()
print("Speed transmisson for total data {:4f}  bytes is {:06.4f}MBytesPSec".\
    format(NUM_DATA_POINTS_READ * BYTES_DATA_POINTS,\
    NUM_DATA_POINTS_READ * BYTES_DATA_POINTS/\
        ((time_end-time_start).seconds*1000000+(time_end-time_start).microseconds)))
''' 
def getADC_bits(data_recv, resolution_bits):
    # 计算分辨率
    resolution = 2 ** resolution_bits
    data = data_recv % resolution
    # 统计每个数出现的次数
    data_min = np.min(data)
    data_max = np.max(data)
    x = np.arange(data_min, data_max + 1)
    y = np.zeros(len(x), dtype=int)
    for z in range(len(x)):
        y[z] = np.sum(data == x[z])
    # 绘制条形图
    plt.bar(x, y)
    plt.xlabel("12bit ADC 4096 steps")  # 添加横轴标签
    plt.ylabel("counts")   # 添加纵轴标签
    plt.title("12 bit SAR ADC resolution")  # 添加图表标题



def process_data(data):
    hex_values = []
    for i in range(0, len(data), 4):
        hex_value = int.from_bytes(data[i:i+4], 'little')
        hex_values.append(hex_value)
    return hex_values
def set_mode():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # 连接服务
        s.connect((HOST, PORT))
        block_data=entry_block.get()
        binary_data = bytearray(int(block_data[i:i+8], 2) for i in range(0, len(block_data), 8))
        hex_data = binascii.hexlify(binary_data).decode()
        message = "set"+ hex_data
        console_output.insert(tk.END, f"{message}\n")
        s.sendall(message.encode())            
    except Exception as e:
        console_output.insert(tk.END, f"Connect Error: {e}\n")
    finally:
        # 关闭连接
        s.close()
def recieve_tcpip (conn,num_to_recieve,max_attemp=-1):
    cnt_attemp=0
    data=bytearray()
    while ((num_to_recieve >0) and (cnt_attemp<=max_attemp or max_attemp==-1)):
        rx_data = []
        cnt_attemp = cnt_attemp + 1
        rx_data = conn.recv(min(num_to_recieve,SIZE_TCPIP_SEND_BUF_TRUNK))
        data.extend(rx_data) 
        len_recv_data=len(rx_data)   
        num_to_recieve=num_to_recieve-len_recv_data
    return data
def dt_read_mode():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # 连接服务
        s.connect((HOST, PORT))
        message = "read"
        cnt=0
        s.sendall(message.encode())
        data_rec=np.zeros(NUM_DATA_POINTS_READ)
        # 接收服务器返回的数据
        cnt_read_mem = 0
        while cnt_read_mem < dt_read_cnt:
            recv_data = recieve_tcpip(s,SIZE_TCPIP_SEND_BUF_TRUNK)
            console_output.insert(tk.END, f"Received amount: {len(recv_data)}\n")
            # 将数据解析为整数列表
            data_list = np.array(process_data(recv_data))/4096*1.8
            
            data_rec[cnt_read_mem*SIZE_TCPIP_SEND_BUF_TRUNK//4:(cnt_read_mem+1)*SIZE_TCPIP_SEND_BUF_TRUNK//4]=data_list
            cnt_read_mem = cnt_read_mem + 1
            # 绘制图形
        fs=2000
        cnt=cnt+1
        time_sample=list([a/fs for a in range(NUM_DATA_POINTS_READ)])
        plt.ion()
        console_output.insert(tk.END, f"Max: {max(data_rec[1:])}\n")
        console_output.insert(tk.END, f"Min: {min(data_rec[1:])}\n")
        fig, ax = plt.subplots()  # 创建图形对象和轴对象
        len1=len(data_rec[1:])
        '''time_sample[0:len1],'''
        ax.plot(time_sample[1:],data_rec[1:],c='r')
        max_value = max(data_rec[1:])
        min_value = min(data_rec[1:])
        at = AnchoredText(f'Max: {max_value:.2f}\nMin: {min_value:.2f}', loc='upper right')
        at.patch.set_boxstyle("round,pad=0.,rounding_size=0.2")
        ax.add_artist(at)
        ax.set_xlabel('TIME (s)')
        ax.set_ylabel('ADC VALUE (V)')
        plt.title("ADC Data Reconfiguration")
        plt.pause(0.001)
        plt.figure(figsize=(8, 6))
        getADC_bits(data_rec[1:]/1.8*4096,ADC_bits)
        plt.show()
                       
    except Exception as e:
        console_output.insert(tk.END, f"Connect Error: {e}\n")
    finally:
        # 关闭连接
        s.close()


def ct_read_mode():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # 连接服务
        s.connect((HOST, PORT))
        message = "ctread"
        cnt=0
        s.sendall(message.encode())
        len_datarec=TCP_TOTAL//4
        data_rec=np.zeros(len_datarec)
        # 接收服务器返回的数据
        cnt_read_mem = 0
        cnt_ctread=0
        data_all=[]
        while cnt_ctread<Count_max:
            while cnt_read_mem < ct_read_cnt:
                recv_data = recieve_tcpip(s,SIZE_TCPIP_SEND_BUF_TRUNK)
                # 将数据解析为整数列表
                data_all.extend(recv_data)
                #data_rec[(cnt_ctread*(ct_read_cnt*SIZE_TCPIP_SEND_BUF_TRUNK)//4+cnt_read_mem*SIZE_TCPIP_SEND_BUF_TRUNK//4):((cnt_read_mem+1)*SIZE_TCPIP_SEND_BUF_TRUNK//4+cnt_ctread*(ct_read_cnt*SIZE_TCPIP_SEND_BUF_TRUNK)//4)]=data_list
                cnt_read_mem = cnt_read_mem + 1
                # 绘制图形
            cnt=cnt+1
            cnt_read_mem = 0
            cnt_ctread=cnt_ctread+1
        data_list = np.array(process_data(data_all))/4095*1.8
        fig, ax = plt.subplots()  # 创建图形对象和轴对象
        ax.plot(data_list[1:],c='r')
        ax.set_xlabel('Points')
        ax.set_ylabel('ADC VALUE (V)')
        plt.pause(0.001)

    except Exception as e:
        console_output.insert(tk.END, f"Connect Error: {e}\n")
    finally:
        # 关闭连接
        s.close()



def spi_mode():
    try:
        # 创建 TCP/IP socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # 连接服务
        s.connect((HOST, PORT))
        spi_cmd = entry_spi_cmd.get()  # 获取文本框中的SPI 命令
        spi_cmd=spi_cmd.replace("_","")
        spi_cmd = spi_cmd.zfill(32)
        binary_data = bytearray(int(spi_cmd[i:i+8], 2) for i in range(0, len(spi_cmd), 8))
        hex_data = binascii.hexlify(binary_data).decode()
        message = "spi" + hex_data
        console_output.insert(tk.END, f"{message}\n")
        console_output.insert(tk.END, f"Code: {spi_cmd[0:6]},Adder: {spi_cmd[6:16]},Data: {spi_cmd[16:32]}\n")
        s.sendall(message.encode())
        # 接收服务器返回的数据
        s.settimeout(10)
        data = s.recv(4100)
        
        console_output.insert(tk.END, f"Received amount: {len(data)}\n")
        for i in range(0, len(data), 4):
            show_data=data[i:i+4]
            bina_data = []
            hex_data = binascii.hexlify(show_data).decode()
            hex_data="".join(reversed([hex_data[i:i+2] for i in range(0, len(hex_data), 2)]))
            hex_data_pr=bin(int(hex_data, 16))[2:].zfill(32)
            #console_output.insert(tk.END, f"{hex_data}\n")
            #console_output.insert(tk.END, f"{hex_data_pr}\n")
            ADC_data=hex_data_pr[20:32]
            if hex_data_pr[0:6]=='010011':
                console_output.insert(tk.END, f"Received:  Code: {hex_data_pr[0:6]} , Adder: {hex_data_pr[6:16]} , Data: {hex_data_pr[16:32]} , Value: {int(ADC_data,2)/4095*1.8} hex: {hex_data} , idx: {i}\n")
            else:
                console_output.insert(tk.END, f"Received:  Code: {hex_data_pr[0:6]} , Adder: {hex_data_pr[6:16]} , Data: {hex_data_pr[16:32]} , hex: {hex_data} , idx: {i}\n")
    except Exception as e:
        console_output.insert(tk.END, f"Connect Error: {e}\n")

    finally:
        # 关闭连接
        s.close()

def send_console_input():
    console_input_text = entry_console_input.get()
    console_output.insert(tk.END, f"Console Input: {console_input_text}\n")
    # 清空控制台输入框
    entry_console_input.delete(0, tk.END)
def clear_console_output():
    console_output.delete(1.0, tk.END)

# 创建 GUI 窗口
window = tk.Tk()

# 设置窗口标题
window.title("TEST_CHIP")

# 设置窗口大小
window.geometry("1200x800")

# 创建顶部框架
bottom_frame = tk.Frame(window)
bottom_frame.pack(side=tk.BOTTOM)

# 添加文本框：SPI 命令输入
entry_spi_cmd = tk.Entry(bottom_frame, width=50)
entry_spi_cmd.pack(side=tk.LEFT)


# 添加文本框：BLOCK 输入
entry_block = tk.Entry(bottom_frame, width=20)
entry_block.pack(side=tk.LEFT)


# 添加按钮：SPI 模式
button_spi = tk.Button(bottom_frame, text="SPI", command=spi_mode)
button_spi.pack(side=tk.LEFT, padx=10)

# 添加按钮：SET 模式
button_set = tk.Button(bottom_frame, text="SET", command=set_mode)
button_set.pack(side=tk.LEFT, padx=10)

# 添加按钮：Read 模式dt_
button_read = tk.Button(bottom_frame, text="DT_Read", command=dt_read_mode)
button_read.pack(side=tk.LEFT, padx=10)

# 添加按钮：Read 模式ct_
button_read = tk.Button(bottom_frame, text="CT_Read", command=ct_read_mode)
button_read.pack(side=tk.LEFT, padx=10)

# 添加文本框：控制台输入
entry_console_input = tk.Entry(window, width=70)
entry_console_input.pack(side=tk.TOP, pady=10)

# 添加按钮：发送控制台输入
button_send_input = tk.Button(window, text="Send", command=send_console_input)
button_send_input.pack(side=tk.RIGHT, padx=5)

# 添加按钮：清空控制台
button_clear_output = tk.Button(window, text="Clear Console", command=clear_console_output)
button_clear_output.pack(side=tk.RIGHT, padx=5)

# 添加控制台输出框
console_output = tk.Text(window, height=10)
console_output.pack(fill=tk.BOTH, expand=True)

# 添加滚动
scrollbar = tk.Scrollbar(console_output)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
console_output.config(yscrollcommand=scrollbar.set)
scrollbar.config(command=console_output.yview)

# 运行窗口
window.mainloop()
