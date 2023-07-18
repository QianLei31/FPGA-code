import socket
import struct
import binascii
import matplotlib.pyplot as plt
import tkinter as tk

HOST = '192.168.2.10'  # 服务器的 IP 地址
PORT = 7  # 服务器监听的端口号
def process_data(data):
    hex_values = []
    for i in range(0, len(data), 4):
        hex_value = int.from_bytes(data[i:i+4], 'little')
        hex_values.append(hex_value)
    return hex_values
def read_mode():
    try:
        # 创建一个 TCP 套接字
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # 连接服务器
        s.connect((HOST, PORT))

        message = "read"
        s.sendall(message.encode())
        

        # 接收服务器返回的数据
        data = s.recv(4096)
        print("Received:", data)
        # 将数据解析为整数列表
        data_list = process_data(data)

        # 绘制图形
        fig, ax = plt.subplots()
        ax.plot(data_list)
        plt.show()

    except Exception as e:
        print("Error:", e)

    finally:
        # 关闭连接
        s.close()

def spi_mode():
    try:
        # 创建一个 TCP 套接字
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # 连接服务器
        s.connect((HOST, PORT))

        spi_cmd = entry_spi_cmd.get()  # 获取文本框中的 spi_cmd
        binary_data = bytearray(int(spi_cmd[i:i+8], 2) for i in range(0, len(spi_cmd), 8))
        hex_data = binascii.hexlify(binary_data).decode()
        message = "spi" + hex_data
        print(message)
        s.sendall(message.encode())

        # 接收服务器返回的数据
        data = s.recv(8)
        print("Received:", data)

    except Exception as e:
        print("Error:", e)

    finally:
        # 关闭连接
        s.close()

# 创建 GUI 窗口
window = tk.Tk()

# 设置窗口标题
window.title("TEST_CHIP")

# 设置窗口大小
window.geometry("800x600")

# 创建一个 Frame 容器，并放在窗口底部
bottom_frame = tk.Frame(window)
bottom_frame.pack(side=tk.BOTTOM)

# 添加文本框
entry_spi_cmd = tk.Entry(bottom_frame, width=32)
entry_spi_cmd.pack(side=tk.LEFT)

# 添加按钮：SPI 模式
button_spi = tk.Button(bottom_frame, text="SPI Mode", command=spi_mode)
button_spi.pack(side=tk.LEFT, padx=10)

# 添加按钮：Read 模式
button_read = tk.Button(bottom_frame, text="Read Mode", command=read_mode)
button_read.pack(side=tk.LEFT, padx=10)

# 运行窗口主循环
window.mainloop()
