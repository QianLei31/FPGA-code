import numpy as np
from scipy import signal
def fft_clean(data_time, fs, num_fftavg, sin_freq, psd_window):
    # 输入参数：
    # data_time: 时间域数据，需要进行频谱分析的信号
    # fs: 采样率
    # num_fftavg: 进行多次FFT并平均的次数：1
    # sin_freq: 信号的频率
    # psd_window: 用于计算功率的窗口大小：8

    # 将输入的时间域数据转换为NumPy数组
    data_time = np.asarray(data_time)

    # 计算每次FFT的数据段长度
    len_fft = int(round(len(data_time) / num_fftavg))

    # 计算时间域数据的平均值和归一化的数据
    avgdata = sum(data_time) / float(len(data_time))
    data_norm = data_time - avgdata

    # 计算FFT结果中显示的长度
    len_fftdisplay = int(round(len_fft / 2))

    # 初始化存储FFT结果的数组
    fft_data = np.array([0] * len_fftdisplay)
    ffttemp = np.array([0] * len_fftdisplay)

    # 使用Blackman-Harris窗口
    w = signal.blackmanharris(len_fft - 1, sym=False)

    # 多次进行FFT计算并平均
    for ii in range(num_fftavg):
        # 使用窗口函数对数据进行加权
        ffttemp = abs(np.fft.fft(np.multiply(data_norm[ii * len_fft:(ii + 1) * len_fft - 1], w)))[0:len_fftdisplay]

        # 将FFT的平方累加到fft_data中
        fft_data = fft_data + (ffttemp) ** 2

    # 对fft_data进行标准化
    fft_data = fft_data / num_fftavg / len_fftdisplay

    # 计算频率分辨率
    resolution = fs / len_fft

    # 计算频率轴上的频率值
    fft_freq = np.linspace(resolution, round(fs / 2), num=len_fftdisplay)

    # 以下部分计算信号频带内的功率以及其他参数，用于信噪比和杂散噪声的计算

    osr = 64
    fres = fs / len_fft
    sigband_bins = 1 + round((fs / (2 * osr)) / fres)
    sigband_power = fres * sum(fft_data[psd_window:sigband_bins])

    sig_bin = 1 + round(sin_freq / fres)
    sig_bin_min = max(1, sig_bin - psd_window)
    sig_bin_max = sig_bin + psd_window
    sig_power = fres * sum(fft_data[sig_bin_min:sig_bin_max])

    K = ((0.001 ** 2) / 8) / sig_power
    dc_power = fres * sum(fft_data[psd_window:round(1 / fres)])
    IRN_power = sigband_power - dc_power
    IRN = np.sqrt(IRN_power * K)
    sndr = np.sqrt(sig_power / (sigband_power - sig_power - dc_power))
    sndr_db = 20 * np.log10(sndr)
    enob = (sndr_db - 1.76) / 6.02

    fft_data = fft_data * K

    # 返回结果
    return (fft_freq.tolist(), fft_data.tolist(), sndr_db, enob, K, IRN)
