ZASM="../../rc2014/z80-asm/zasm-4.0/Linux/zasm" 

all: monitor.rom

monitor.hex: monitor.asm
	$(ZASM) -u -x --8080 --asm8080 monitor.asm

monitor.rom: monitor.asm
	$(ZASM) -u -b --8080 --asm8080 monitor.asm
	mv monitor.rom monitor.tmp
	dd if=monitor.tmp of=monitor.rom skip=59392 bs=1

scrunch.rom: monitor.rom
	dd if=monitor.rom of=scrunch.rom bs=1 count=768
	dd if=/dev/zero of=scrunch.rom bs=1 count=1280 oflag=append conv=notrunc 
	dd if=monitor.rom of=scrunch.rom bs=1 skip=4096 oflag=append conv=notrunc 

monitor.patch:
	cp ../mon80-1.3/monIIv13.asm monIIv13-orig.asm
	cp monitor.asm monIIv13-scott.asm
	diff -Naur monIIv13-orig.asm monIIv13-scott.asm > monitor.patch || true
	rm monIIv13-orig.asm
	rm monIIv13-scott.asm

clean:
	rm -f *.hex *.rom *.patch


