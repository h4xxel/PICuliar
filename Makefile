CFLAGS	=	-mpic14 -p16f690 --opt-code-speed
OBJFILES	=	midi.o
BINFILE	=	midi.hex

.PHONY: all install run stop clean

all: midilookup
	sdcc -o midi.o $(CFLAGS) -c midi.c
	sdcc -o $(BINFILE) $(CFLAGS) $(OBJFILES)
install:
	pk2cmd -Ppic16f690 -F $(BINFILE) -M
run:
	pk2cmd -Ppic16f690 -T
stop:
	pk2cmd -Ppic16f690
clean:
	rm -f *.o *.hex *.lst *.cod

midilookup:
	./genmidilookup.py > midi.h

.c.o:
	sdcc -o $*.o $(CFLAGS) -c $*.c
