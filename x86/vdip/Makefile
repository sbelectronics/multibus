BUILD=../build
MAP=../build
BUILD186=../build186

all: $(BUILD)/vdir.cmd \
     $(BUILD)/vget.cmd \
	 $(BUILD)/vcd.cmd \
	 $(BUILD)/vput.cmd \
	 $(BUILD)/pdir.cmd \
	 $(BUILD)/pget.cmd \
	 $(BUILD)/pcd.cmd \
	 $(BUILD)/pput.cmd

h8-80186: \
	$(BUILD186)/vget.com \
	$(BUILD186)/vdir.com \
	$(BUILD186)/vcd.com \
	$(BUILD186)/vput.com
	cp $(BUILD186)/*.com /home/smbaker/projects/pi/h8/h8-80186/commands/

$(BUILD)/vget.cmd: vget.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/vget.cmd vget.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/vget.map -O2 -D SECONDARY_VDIP -D OLIVETTI

$(BUILD)/vdir.cmd: vdir.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/vdir.cmd vdir.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/vdir.map -O2 -D SECONDARY_VDIP -D OLIVETTI

$(BUILD)/vcd.cmd: vcd.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/vcd.cmd vcd.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/vcd.map -O2 -D SECONDARY_VDIP -D OLIVETTI

$(BUILD)/vput.cmd: vput.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/vput.cmd vput.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/vput.map -O2 -D SECONDARY_VDIP -D OLIVETTI

$(BUILD)/pget.cmd: vget.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/pget.cmd vget.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/pget.map -O2 -D OLIVETTI

$(BUILD)/pdir.cmd: vdir.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/pdir.cmd vdir.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/pdir.map -O2 -D OLIVETTI

$(BUILD)/pcd.cmd: vcd.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/pcd.cmd vcd.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/pcd.map -O2 -D OLIVETTI

$(BUILD)/pput.cmd: vput.c vutil.c vinc.c oliport.c vutil.h vinc.h oliport.h
	z8k-pcos-gcc -o $(BUILD)/pput.cmd vput.c vutil.c vinc.c oliport.c -Wl,-multi,-map,$(MAP)/pput.map -O2 -D OLIVETTI

$(BUILD186)/vget.com: vget.c vutil.c vinc.c vutil.h vinc.h
	WATCOM=/usr/bin/watcom INCLUDE=/usr/bin/watcom/h PATH=$PATH:/usr/bin/watcom/binl64 wcl -mt vget.c vutil.c vinc.c -dH8_80186 -fe=$(BUILD186)/vget.com

$(BUILD186)/vdir.com: vdir.c vutil.c vinc.c vutil.h vinc.h
	WATCOM=/usr/bin/watcom INCLUDE=/usr/bin/watcom/h PATH=$PATH:/usr/bin/watcom/binl64 wcl -mt vdir.c vutil.c vinc.c -dH8_80186 -fe=$(BUILD186)/vdir.com

$(BUILD186)/vcd.com: vcd.c vutil.c vinc.c vutil.h vinc.h
	WATCOM=/usr/bin/watcom INCLUDE=/usr/bin/watcom/h PATH=$PATH:/usr/bin/watcom/binl64 wcl -mt vcd.c vutil.c vinc.c -dH8_80186 -fe=$(BUILD186)/vcd.com

$(BUILD186)/vput.com: vput.c vutil.c vinc.c vutil.h vinc.h
	WATCOM=/usr/bin/watcom INCLUDE=/usr/bin/watcom/h PATH=$PATH:/usr/bin/watcom/binl64 wcl -mt vput.c vutil.c vinc.c -dH8_80186 -fe=$(BUILD186)/vput.com

clean:
	rm -f $(BUILD)/*.cmd
