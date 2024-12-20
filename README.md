# Multibus Stuff

http://www.smbaker.com/

Collection of stuff from scott's multibus projects.

## Contents

* isistool/ ... a tool for manipulating ISIS-II images in place. Written in python. Runs in Linux (and maybe windows)

* ramboard/ ... scott's RAM/ROM/IOC board. This board includes up for 512K RAM, up to 512K ROM, 2 multimodule slots,
  and a rasbperry pi based IO Controller (IOC).

* pioc/ ... raspberry pi based IOC software.

* mon80-scott-pioc/ ... Custom series II monitor and ISIS boot loader. Some of the ports (8251, 8259, etc) on the 80/24
  are different than the port assignments on the Series II, so some reworking was necessary.

## Running ISIS-II on an 80/24 (or 80/24A multibus board)

The MDS Series II computer used a CPU board together with an IO Controller board (IOC). The IOC handled terminal (video/keyboard)
and disk operations for the Series II internal 8" SD disk drive. The CPU and IOC communicate via a simple 8-bit port with some
handshaking, and the protocol is well documented in the Series II Hardare Reference Manaual. There are commands for sending characters
to and from the terminal, and commands for perfomring disk operations.

The original IOC board contains its own 8080 CPU. Thus a Series II typically included multiple CPUS -- the main 8080 or 8085, the
slave 8080 CPU on the IOC board, and another 8741 microcontroller on the PIO board. Reimplementing the IOC is a daunting task as it
really involves entire 8080 along with all of its necessary support logic. So I implemented the IOC usinga raspberry pi.

The `ramboard` in this repository includes an IOC based on a raspberry pi. 

The `pioc` software in this repository is the python program that runs on the raspberry pi to implement the IOC.

The `mon80-scott-pioc` monitor is the Series II monitor that has been modified for the IO Ports on the 80/24.

The IOC communicated with the host processor via some latches and synchronizes via some flipflops.

To reproduce this project, you will need a suitable multibus CPU board such as an 80/20-4, 80/24, or 80/24A. I recommend the 80/24A.
Then you will need to build up the ramboard and install the appropriate software on the pi. Then you'll need to put a custom loader
EPROM on 80/24.

It's a little bit daunting, but you can do it.
