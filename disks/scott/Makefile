ISISTOOL="../../isistool/isistool.py"
APPS="../../isis-apps"

all: scott.img scottdd.img scottdd_patched.img

scott.img:
	cp ../../isistool/testdata/isis-43-min.img scott.img
	$(ISISTOOL) -f scott.img add $(APPS)/aysong
	$(ISISTOOL) -f scott.img add $(APPS)/basic
	$(ISISTOOL) -f scott.img add $(APPS)/brtprm
	$(ISISTOOL) -f scott.img add $(APPS)/forth
	$(ISISTOOL) -f scott.img add $(APPS)/life
	$(ISISTOOL) -f scott.img add $(APPS)/maze
	$(ISISTOOL) -f scott.img add $(APPS)/say
	$(ISISTOOL) -f scott.img add $(APPS)/song
	$(ISISTOOL) -f scott.img add $(APPS)/til311
	$(ISISTOOL) -f scott.img add $(APPS)/rtc
	$(ISISTOOL) -f scott.img add $(APPS)/type
	$(ISISTOOL) -f scott.img add $(APPS)/hang
	$(ISISTOOL) -f scott.img add $(APPS)/nixclk
	$(ISISTOOL) -f scott.img add $(APPS)/votrax
	$(ISISTOOL) -f scott.img add $(APPS)/drives
	$(ISISTOOL) -f scott.img add $(APPS)/sertes
	$(ISISTOOL) -f scott.img add $(APPS)/coptes
	$(ISISTOOL) -f scott.img add $(APPS)/dig
	$(ISISTOOL) -f scott.img add ../../isistool/testdata/cntry.txt

scottdd.img:
	cp ../../isistool/testdata/isis-43-dd.img scottdd.img
	$(ISISTOOL) -f scottdd.img add $(APPS)/aysong
	$(ISISTOOL) -f scottdd.img add $(APPS)/basic
	$(ISISTOOL) -f scottdd.img add $(APPS)/brtprm
	$(ISISTOOL) -f scottdd.img add $(APPS)/forth
	$(ISISTOOL) -f scottdd.img add $(APPS)/life
	$(ISISTOOL) -f scottdd.img add $(APPS)/maze
	$(ISISTOOL) -f scottdd.img add $(APPS)/say
	$(ISISTOOL) -f scottdd.img add $(APPS)/song
	$(ISISTOOL) -f scottdd.img add $(APPS)/til311
	$(ISISTOOL) -f scottdd.img add $(APPS)/rtc
	$(ISISTOOL) -f scottdd.img add $(APPS)/type
	$(ISISTOOL) -f scottdd.img add $(APPS)/hang
	$(ISISTOOL) -f scottdd.img add $(APPS)/nixclk
	$(ISISTOOL) -f scottdd.img add $(APPS)/votrax
	$(ISISTOOL) -f scottdd.img add $(APPS)/drives
	$(ISISTOOL) -f scottdd.img add $(APPS)/sertes
	$(ISISTOOL) -f scottdd.img add $(APPS)/coptes
	$(ISISTOOL) -f scottdd.img add $(APPS)/dig
	$(ISISTOOL) -f scottdd.img add ../../isistool/testdata/cntry.txt

scottdd_patched.img: scottdd.img
	python3 ../../pdisk/patchdisk.py scottdd.img scottdd_patched.img

scott.dir:
	$(ISISTOOL) -f scott.img dir

scottdd.dir:
	$(ISISTOOL) -f scottdd.img dir

clean:
	rm -f scott.img scottdd.img
