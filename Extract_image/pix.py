import json
from array import *
import posixpath
from PIL import Image
import numpy as np

# export your ila waveform to csv in vivado and convert it to json using this online tool:
# https://csvjson.com/csv2json
# make sure to unselect "parse numbers" and "parse JSON"
waveform_file = './Extract_image/csvjson.json'

linelength = 720
num_samples = 131072
is_interlaced = True

end_of_line_signal_name     = "design_1_i/BT656_decode_M_AXIS_0_tlast"
data_valid_signal_name      = "design_1_i/BT656_decode_M_AXIS_0_tvalid"
data_signal_name            = "design_1_i/BT656_decode_M_AXIS_0_tdata[23:0]"

f = open(waveform_file)
data = json.load(f)

num_lines = np.ceil(num_samples/linelength).astype(int)

if is_interlaced:
    buffer = np.zeros((num_lines*2, linelength, 3), dtype=np.uint8)
else:
    buffer = np.zeros((num_lines, linelength, 3), dtype=np.uint8)

line = np.zeros((linelength, 3), dtype=np.uint16)
linebuffer = np.zeros((linelength, 3), dtype=np.uint16)
columncounter = 0
rowcounter = 0

def hex_to_rgb(value):
    value = value.lstrip('#')
    lv = len(value)
    return tuple(int(value[i:i + lv // 3], 16) for i in range(0, lv, lv // 3))

def average(lineA, lineB):
    avg = np.zeros((linelength, 3), dtype=np.uint8)
    for i in range(linelength):
        avg[i][0] = (lineA[i][0] + lineB[i][0])/2
        avg[i][1] = (lineA[i][1] + lineB[i][1])/2
        avg[i][2] = (lineA[i][2] + lineB[i][2])/2
    return avg

# interate over every clock cycle (pixels)
for i in range(num_samples):
    pixel = data[i]

    #if pixel is valid
    if pixel[data_valid_signal_name] == "1": 

        #write pixel to a line
        line[columncounter] = hex_to_rgb(pixel[data_signal_name])
        columncounter += 1

        #if line ended
        if pixel[end_of_line_signal_name] == "1":
            rowcounter += 1
            columncounter = 0

            if is_interlaced:
                buffer[rowcounter*2] = linebuffer
                buffer[rowcounter*2+1] = average(linebuffer, line) #deinterlace
            else:
                buffer[rowcounter] = linebuffer

            linebuffer = line.copy()

img = Image.fromarray(buffer, 'RGB')
img.save('my.png')
img.show()
f.close()