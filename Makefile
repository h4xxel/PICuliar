CFLAGS	=	-mpic14 -p16f690
OBJFILES	=	midi.o
BINFILE	=	midi.hex

all: $(OBJFILES)
	sdcc -o $(BINFILE) $(CFLAGS) $(OBJFILES)
install:
	pk2cmd -Ppic16f690 -F $(BINFILE) -M
run:
	pk2cmd -Ppic16f690 -T
stop:
	pk2cmd -Ppic16f690
clean:
	rm -f *.o *.hex *.lst *.cod

.c.o:
	sdcc -o $*.o $(CFLAGS) -c $*.c
