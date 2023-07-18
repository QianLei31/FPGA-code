import socket
import binascii
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
NUM_DATA_POINTS_READ=4096*1024
len_remain_data = SIZE_TCPIP_SEND_BUF_TRUNK
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
def process_data(data):
    hex_values = []
    for i in range(0, len(data), 4):
        hex_value = int.from_bytes(data[i:i+4], 'little')
        hex_values.append(hex_value)
    return hex_values

def read_mode():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # 连接服务
        s.connect((HOST, PORT))
        block_data=entry_block.get()
        binary_data = bytearray(int(block_data[i:i+8], 2) for i in range(0, len(block_data), 8))
        hex_data = binascii.hexlify(binary_data).decode()
        message = "read"+ hex_data

        while(True):
            s.sendall(message.encode())
            data_rec=np.zeros(NUM_DATA_POINTS_READ)
            # 接收服务器返回的数据
            cnt_read_mem = 0
            while cnt_read_mem < (NUM_DATA_POINTS_READ * BYTES_DATA_POINTS / SIZE_TCPIP_SEND_BUF_TRUNK):

                recv_data = s.recv(SIZE_TCPIP_SEND_BUF_TRUNK) 
                console_output.insert(tk.END, f"Received amount: {len(recv_data)}\n")
                # 将数据解析为整数列表
                data_list = np.array(process_data(recv_data))/4095*1.8
                console_output.insert(tk.END, f"Max: {max(data_list)}\n")
                data_rec[cnt_read_mem*SIZE_TCPIP_SEND_BUF_TRUNK//4:(cnt_read_mem+1)*SIZE_TCPIP_SEND_BUF_TRUNK//4]=data_list
                cnt_read_mem = cnt_read_mem + 1
                # 绘制图形
            fs=40000
            time_sample=list([a/fs for a in range(NUM_DATA_POINTS_READ)])
            fig, ax = plt.subplots()
            ax.plot(data_rec,c='r')
            ax.set_xlabel('TIME (s)')
            ax.set_ylabel('ADC VALUE (V)')
            plt.show()
            plt.pause(1)
            plt.clf()
                



                
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
            hex_data_pr=bin(int(hex_data, 16)).zfill(32)
            bina_data[0:8]=hex_data_pr[26:34]
            bina_data[8:16]=hex_data_pr[18:26]
            bina_data[16:24]=hex_data_pr[10:18]
            bina_data[24:32]=hex_data_pr[2:10]
            bina_data = ''.join(bina_data)
            ADC_data=bina_data[20:32]
            if bina_data[0:6]=='010011':
                console_output.insert(tk.END, f"Received:  Code: {bina_data[0:6]} , Adder: {bina_data[6:16]} , Data: {bina_data[16:32]} , Value: {int(ADC_data,2)/4095*1.8} hex: {hex_data} , idx: {i}\n")
            else:
                console_output.insert(tk.END, f"Received:  Code: {bina_data[0:6]} , Adder: {bina_data[6:16]} , Data: {bina_data[16:32]} , hex: {hex_data} , idx: {i}\n")
    except Exception as e:
        console_output.insert(tk.END, f"Connect Error: {e}\n")

    finally:
        # 关闭连接
        s.close()
def spi1000_mode():
    try:
        # 创建 TCP/IP socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # 连接服务
        s.connect((HOST, PORT))

        spy_cmd = entry_spi_cmd.get()  # 获取文本框中的SPI 命令
        binary_data = bytearray(int(spy_cmd[i:i + 8], 2) for i in range(0, len(spy_cmd), 8))
        hex_data = binascii.hexlify(binary_data).decode()
        message = "spi" + hex_data
        console_output.insert(tk.END, f"{message}\n")
        # Sending the command 1000 times
        for i in range(1000):
            s.sendall(message.encode())
            # Add a 0.05-second delay between commands
            time.sleep(0.05)
        data = s.recv(4100)
        console_output.insert(tk.END, f"Received amount: {len(data)}\n")
        for j in range(0, len(data), 4):
                show_data = data[j:j + 4]
                hex_data = binascii.hexlify(show_data).decode()
                console_output.insert(tk.END, f"Received: {hex_data}, idx: {j}\n")

    except Exception as e:
        console_output.insert(tk.END, f"Connect Error: {e}\n")

    finally:
        # 关闭连接
        s.close()
def send_console_input():
    console_input_text = entry_console_input.get()
    console_output.insert(tk.END, f"Console Input: {console_input_text}\n")
    
    if console_input_text == "spi1000":
        spi1000_mode()
    else:
        # 可根据输入内容执行相应的操作
        pass

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

# 添加按钮：Read 模式
button_read = tk.Button(bottom_frame, text="Read ADC", command=read_mode)
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
