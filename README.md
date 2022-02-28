# BT656_2_AXI4S

## TODO
- Deinterlace by scanline interpolation
- Upscale for hdmi (minimum 25MHz pixel clock)

## Setup
In my testing i used an [FCB-EX1010](https://www.image-sensing-solutions.eu/fcb_ex1010_p.html) analog camera block as video source and connected it to [this analog video decoder board](https://github.com/dylanmsu/ADV7180_to_Pmod). As the FPGA i used the Digilent Zybo Z7-20 development board, but any board with three pmod ports in a row should also work.

Send me a message if you want the video interface board and i'll ship you one.

## Working block diagram
### Top level
![top](./img/Block-Diagram-Top.png)
the clocking wizard is set to 11.36MHz instead of 13.5MHz (27MHZ/2) that is because we want only active pixels in the Internal logic analyzer. <br>
bt656 clock = 27MHz <br>
blanking period = 272 clks <br>
active pixels/line = 720Y + 720C = 1440 clks <br>
27MHz * (1440/(1440+272))/2 = 11.36MHz <br>


### BT656 decoder
![block-diagram](./img/Block-Diagram-BT656-V1.1.png)

### Detailed overview
TODO

## Disclaimer
This is in no way a rigorously tested design and sould NOT be used in an actual implementation. This is a personal project to learn more about VHDL and video processing. I got it to work on my specific setup and i cannot guarantee that it will work on other hardware.
