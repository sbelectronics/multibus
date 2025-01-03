all: monitor.rom isis.rom multi.rom

# multi.com
#   bank 0: monitor / basic / forth isis
#   bank 1: isis direct start

multi.rom:
	dd if=monitor.rom of=multi.rom
	dd if=isis.rom of=multi.rom conv=notrunc oflag=append

# monitor.rom: contains 8080 monitor, with basic, forth, and isis booter/monitor

monitor.rom:
	tr '\000' '\377' < /dev/zero | head -c 65536 > monitor.rom
	dd if=../../8080-Monitor/00-8080.rom of=monitor.rom  conv=notrunc 
	dd if=../../8080-Monitor/01-basic.rom of=monitor.rom bs=1 seek=8192 conv=notrunc
	dd if=../../8080-Monitor/02-forth.rom of=monitor.rom bs=1 seek=16384 conv=notrunc
	dd if=../mon80-scott-pioc/monitor.rom of=monitor.rom bs=1 seek=24576 conv=notrunc
	dd if=../mon80-scott-pioc/monitor.rom of=monitor.rom bs=1 seek=59392 conv=notrunc

# monitor.rom: contains only isis booter/monitor. 0x0000 has a copy of the E800, and
# will jump to E800 and disable ROM.

isis.rom:
	tr '\000' '\377' < /dev/zero | head -c 65536 > isis.rom
	dd if=../mon80-scott-pioc/monitor.rom of=isis.rom bs=1 conv=notrunc
	dd if=../mon80-scott-pioc/monitor.rom of=isis.rom bs=1 seek=59392 conv=notrunc

clean:
	rm -f monitor.rom isis.rom multi.rom
