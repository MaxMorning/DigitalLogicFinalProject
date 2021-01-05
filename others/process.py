import numpy as npy

def convert(num):
    if abs(num - 1.0) < 1.0 / 128:
        return '10'
    elif abs(num) < 1.0 / 128:
        return '00'
    elif num < 0:
        num = -num
        num *= 128
        num += 128
        num = int(num)
        n_str = str(hex(num))[2:]
        if len(n_str) == 1:
            n_str = '0' + n_str
        return n_str
    else:
        num *= 128
        num = int(num)
        n_str = str(hex(num))[2:]
        if len(n_str) == 1:
            n_str = '0' + n_str
        return n_str


file = open('tensor.coe', 'w')
file_str = "memory_initialization_radix=16;\nmemory_initialization_vector=\n"

fc1_w = npy.load('dense_kernel_0.npy')
for r in range(128):
    cnt_128 = 0
    unit_128_8 = ''
    for c in range(1024):
        unit_128_8 += convert(fc1_w[c][r])
        if cnt_128 < 127:
            cnt_128 += 1
        else:
            cnt_128 = 0
            file_str += unit_128_8 + ',\n'
            unit_128_8 = ''

fc1_b = npy.load('dense_bias_0.npy')
unit_128_8 = ''
for i in range(128):
    unit_128_8 += convert(fc1_b[i])
file_str += unit_128_8 + ',\n'

fc2_w = npy.load('dense_1_kernel_0.npy')
for r in range(10):
    unit_128_8 = ''
    for c in range(128):
        unit_128_8 += convert(fc2_w[c][r])
    unit_128_8 += ',\n'
    file_str += unit_128_8

fc2_b = npy.load('dense_1_bias_0.npy')
unit_128_8 = ''
for i in range(128):
    if i < 10:
        unit_128_8 += convert(fc2_b[i])
    else:
        unit_128_8 += '00'
file_str += unit_128_8 + ';'

file.write(file_str)