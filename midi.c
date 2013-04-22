#include <pic/pic16f690.h>
#include <stdlib.h>
#include <stdint.h>
#include <limits.h>

#define OSCILLATORS 6

#define NOP _asm nop _endasm

typedef unsigned int config;
config at 0x2007 __CONFIG=_EC_OSC&_WDT_OFF&_PWRTE_OFF&_MCLRE_OFF&_CP_OFF&_BOR_OFF&_IESO_OFF&_FCMEN_OFF;

enum REGISTER {
	REG_TONEA_L,
	REG_TONEA_H,
	REG_TONEB_L,
	REG_TONEB_H,
	REG_TONEC_L,
	REG_TONEC_H,
	REG_NOISE,
	REG_CONTROL,
	REG_AMPA,
	REG_AMPB,
	REG_AMPC,
	REG_ENVPERIOD_L,
	REG_ENVPERIOD_H,
	REG_ENVCONTROL,
};

struct OSCILLATOR {
	unsigned char note;
	unsigned char channel;
	unsigned int time;
} oscillator[OSCILLATORS];

unsigned int current;

const unsigned short midi_freqdiv[]={
	0x3bb9,
	0x385f,
	0x3535,
	0x3238,
	0x2f67,
	0x2cbe,
	0x2a3b,
	0x27dc,
	0x259f,
	0x2383,
	0x2185,
	0x1fa3,
	0x1ddd,
	0x1c2f,
	0x1a9a,
	0x191c,
	0x17b3,
	0x165f,
	0x151d,
	0x13ee,
	0x12d0,
	0x11c1,
	0x10c2,
	0xfd2,
	0xeee,
	0xe18,
	0xd4d,
	0xc8e,
	0xbda,
	0xb2f,
	0xa8f,
	0x9f7,
	0x968,
	0x8e1,
	0x861,
	0x7e9,
	0x777,
	0x70c,
	0x6a7,
	0x647,
	0x5ed,
	0x598,
	0x547,
	0x4fc,
	0x4b4,
	0x470,
	0x431,
	0x3f4,
	0x3bc,
	0x386,
	0x353,
	0x324,
	0x2f6,
	0x2cc,
	0x2a4,
	0x27e,
	0x25a,
	0x238,
	0x218,
	0x1fa,
	0x1de,
	0x1c3,
	0x1aa,
	0x192,
	0x17b,
	0x166,
	0x152,
	0x13f,
	0x12d,
	0x11c,
	0x10c,
	0xfd,
	0xef,
	0xe1,
	0xd5,
	0xc9,
	0xbe,
	0xb3,
	0xa9,
	0x9f,
	0x96,
	0x8e,
	0x86,
	0x7f,
	0x77,
	0x71,
	0x6a,
	0x64,
	0x5f,
	0x59,
	0x54,
	0x50,
	0x4b,
	0x47,
	0x43,
	0x3f,
	0x3c,
	0x38,
	0x35,
	0x32,
	0x2f,
	0x2d,
	0x2a,
	0x28,
	0x26,
	0x24,
	0x22,
	0x20,
	0x1e,
	0x1c,
	0x1b,
	0x19,
	0x18,
	0x16,
	0x15,
	0x14,
	0x13,
	0x12,
	0x11,
	0x10,
	0xf,
	0xe,
	0xd,
	0xd,
	0xc,
	0xb,
	0xb,
	0xa,
};

void iodelay() {
	NOP;
}

void loadreg(unsigned char chip, unsigned char reg) {
	if(chip) {
		RA2=0x1;
		PORTC=reg;
		RA4=0x1;
		iodelay();
		RA4=0x0;
		RA2=0x0;
		iodelay();
	} else {
		RA0=0x1;
		PORTC=reg;
		RA1=0x1;
		iodelay();
		RA1=0x0;
		RA0=0x0;
		iodelay();
	}
}

void write(unsigned char chip, unsigned char dat) {
	if(chip) {
		RA2=0x0;
		PORTC=dat;
		RA4=0x1;
		iodelay();
		RA4=0x0;
	} else {
		RA0=0x0;
		PORTC=dat;
		RA1=0x1;
		iodelay();
		RA1=0x0;
	}
}

unsigned char recv() {
	unsigned char c;
	if(OERR||FERR) {
		CREN=0;
		CREN=1;
		return 0;
	}
	while(!RCIF);
	c=RCREG;
	return c;
}

void midi_note_on(unsigned char note, unsigned char vol, unsigned int channel) {
	unsigned char i, j=0;
	unsigned int tim=current;
	unsigned short freqdiv=midi_freqdiv[note];
	unsigned char chip;
	if(channel==9)
		return;
	for(i=0; i<OSCILLATORS; i++) {
		if(oscillator[i].note==0xFF) {
			chip=i/3;
			oscillator[i].note=note;
			oscillator[i].time=current;
			oscillator[i].channel=channel;
			i%=3;
			loadreg(chip, i<<1);
			write(chip, freqdiv);
			loadreg(chip, (i<<1)+1);
			write(chip, freqdiv>>8);
			loadreg(chip, REG_AMPA+i);
			write(chip, (vol>>4)+8);
			return;
		} else {
			if(oscillator[i].time<tim) {
				j=i;
				tim=oscillator[i].time;
			}
		}
	}
	chip=j/3;
	oscillator[j].note=note;
	oscillator[j].time=current;
	oscillator[j].channel=channel;
	j%=3;
	loadreg(chip, j<<1);
	write(chip, freqdiv);
	loadreg(chip, (j<<1)+1);
	write(chip, freqdiv>>8);
	loadreg(chip, REG_AMPA+j);
	write(chip, (vol>>4)+8);
}

void midi_note_off(unsigned char note) {
	unsigned char i;
	unsigned char chip;
	for(i=0; i<OSCILLATORS; i++) {
		if(oscillator[i].note==note) {
			chip=i/3;
			oscillator[i].note=0xFF;
			oscillator[i].time=0;
			loadreg(chip, REG_AMPA+(i%3));
			write(chip, 0x0);
			return;
		}
	}
}

void midi_pitch_bend(unsigned short pitch, unsigned char channel) {
	unsigned char i;
	unsigned char note;
	//might need long ;_;
	unsigned short freqdiv1, freqdiv2;
	unsigned char chip;
	unsigned long temp;
	for(i=0; i<OSCILLATORS; i++) {
		if(oscillator[i].note!=0xFF&&oscillator[i].channel==channel) {
			chip=i/3;
			note=oscillator[i].note;
			if(pitch==0x2000) {
				freqdiv2=midi_freqdiv[note];
			} else if(pitch>0x2000) {
				/*bend up*/
				pitch-=0x2000;
				freqdiv1=midi_freqdiv[note];
				freqdiv2=midi_freqdiv[note+2];
				//freqdiv2=freqdiv1-pitch*(freqdiv1-freqdiv2)/0x2000;
				freqdiv2=(freqdiv1-freqdiv2);
				temp=freqdiv2;
				temp*=pitch;
				temp>>=13;
				freqdiv2=temp;
				freqdiv2=freqdiv1-freqdiv2;
			} else {
				/*bend down*/
				pitch=0x2000-pitch;
				freqdiv1=midi_freqdiv[note-2];
				freqdiv2=midi_freqdiv[note];
				//freqdiv2=freqdiv2-pitch*(freqdiv1-freqdiv2)/0x2000;
				freqdiv1=(freqdiv1-freqdiv2);
				temp=freqdiv1;
				temp*=pitch;
				temp>>=13;
				freqdiv1=temp;
				freqdiv2=freqdiv2+freqdiv1;
			}
			
			loadreg(chip, (i%3)<<1);
			write(chip, freqdiv2);
			loadreg(chip, ((i%3)<<1)+1);
			write(chip, freqdiv2>>8);
		}
	}
}

void isr() interrupt 0 {
	unsigned char chip;
	if(RABIF) {
		if(RB6) {
			char i;
			for(i=0; i<OSCILLATORS; i++) {
				chip=i/3;
				oscillator[i].note=0xFF;
				oscillator[i].time=0;
				loadreg(chip, REG_AMPA+(i%3));
				write(chip, 0x0);
			}
		}
		RABIF=0;
	}
}

void main() {
	unsigned char event=0, c, a, b;
	unsigned long varlen;
	SCS=0;
	
	TRISA=0x0;
	ANSEL=0x0;
	ANSELH=0x0;
	TRISB=0x50;
	TRISC=0x0;
	PORTA=0;
	PORTB=0;
	PORTC=0;
	
	for(a=0; a<OSCILLATORS; a++) {
		oscillator[a].note=0xFF;
		oscillator[a].time=0x0;
	}
	
	iodelay();
	
	/*midi baudrate, 31250*/
	//SPBRG=14;
	SPBRG=51;
	BRGH=1;
	TXEN=1;
	CREN=1;
	SYNC=0;
	SPEN=1;
	
	iodelay();
	
	for(a=0; a<(OSCILLATORS+(OSCILLATORS%3))/3; a++) {
		loadreg(a, REG_AMPA);
		write(a, 0x0);
		loadreg(a, REG_AMPB);
		write(a, 0x0);
		loadreg(a, REG_AMPC);
		write(a, 0x0);
		loadreg(a, REG_CONTROL);
		write(a, 0xF8);
	}
	
	IOCB6=1;
	INTCON=0x88;
	
	for(;;) {
		c=recv();
		if(c&0x80) {
			event=c;
			a=recv();
		} else
			a=c;
		switch(event&0xF0) {
			case 0x80:
				/*key release*/
				b=recv();
				midi_note_off(a);
				break;
			case 0x90:
				/*key press*/
				b=recv();
				if(b)
					midi_note_on(a, b, event&0xF);
				else
					midi_note_off(a);
				break;
			case 0xA0:
				/*key after-touch*/
			case 0xB0:
				/*control change*/
				b=recv();
				break;
			case 0xE0:
				/*pitch wheel change*/
				b=recv();
				if(RB4)
					midi_pitch_bend((((short) b)<<7)|a, event&0xF);
				break;
			case 0xC0:
				/*program change*/
			case 0xD0:
				/*channel after-touch*/
				break;
			case 0xF0:
				/*sysex*/
				for(varlen=a&0x7F; (a=recv())&0x80; varlen=(varlen<<7)+(a&0x7F));
				
				while(varlen--)
					recv();
				break;
		}
		current++;
	}
}
