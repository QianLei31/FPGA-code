import socket
import binascii
import matplotlib.pyplot as plt
import tkinter as tk
import os
import datetime
import time
# 创建 GUI 窗口
window = tk.Tk()

# 设置窗口标题
window.title("TEST_CHIP")

# 设置窗口大小
window.geometry("800x600")

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
