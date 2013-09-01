#include <pic/pic16f690.h>
#include <stdlib.h>
#include <stdint.h>
#include <limits.h>

#include "midi.h"

#define OSCILLATORS 6

#define CHIP1BC1 RA1
#define CHIP1BDIR RA0
#define CHIP2BC1 RA2
#define CHIP2BDIR RA4

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

void iodelay() {
	NOP;
	NOP;
	NOP;
	NOP;
	NOP;
	NOP;
	NOP;
	NOP;
	NOP;
	NOP;
}

void loadreg(unsigned char chip, unsigned char reg) {
	if(chip) {
		CHIP2BC1=0x1;
		PORTC=reg;
		CHIP2BDIR=0x1;
		iodelay();
		CHIP2BDIR=0x0;
		CHIP2BC1=0x0;
		iodelay();
	} else {
		CHIP1BC1=0x1;
		PORTC=reg;
		CHIP1BDIR=0x1;
		iodelay();
		CHIP1BDIR=0x0;
		CHIP1BC1=0x0;
		iodelay();
	}
}

void write(unsigned char chip, unsigned char dat) {
	if(chip) {
		CHIP2BC1=0x0;
		PORTC=dat;
		CHIP2BDIR=0x1;
		iodelay();
		CHIP2BDIR=0x0;
	} else {
		CHIP1BC1=0x0;
		PORTC=dat;
		CHIP1BDIR=0x1;
		iodelay();
		CHIP1BDIR=0x0;
	}
}

unsigned char recv() {
	unsigned char c;
	do
		if(OERR||FERR) {
			CREN=0;
			c=RCREG;
			c=RCREG;
			SPEN=0;
			SPEN=1;
			CREN=1;
		}
	while(!RCIF);
		
	c=RCREG;
	return c;
}

void midi_note_on(unsigned char note, unsigned char vol, unsigned int channel) {
	/*some ugly hand optimizations*/
	unsigned char i, j=0;
	unsigned int tim=current;
	unsigned short freqdiv=midi_freqdiv[note];
	unsigned char chip1=0, reg1=0;
	unsigned char chip2, reg2;
	if(channel==9)
		return;
	for(i=0; i<OSCILLATORS; i++) {
		if(oscillator[i].note==0xFF) {
			//chip=i/3;
			oscillator[i].note=note;
			oscillator[i].time=current;
			oscillator[i].channel=channel;
			//i%=3;
			loadreg(chip1, REG_AMPA+(reg1>>1));
			write(chip1, (vol>>4)+8);
			loadreg(chip1, reg1);
			write(chip1, freqdiv);
			reg1++;
			loadreg(chip1, reg1);
			write(chip1, freqdiv>>8);
			return;
		} else {
			if(oscillator[i].time<tim) {
				j=i;
				reg2=reg1;
				chip2=chip1;
				tim=oscillator[i].time;
			}
		}
		reg1+=2;
		if(reg1==6) {
			reg1=0;
			chip1++;
		}
	}
	oscillator[j].note=note;
	oscillator[j].time=current;
	oscillator[j].channel=channel;
	loadreg(chip2, REG_AMPA+(reg2>>1));
	write(chip2, (vol>>4)+8);
	loadreg(chip2, reg2);
	write(chip2, freqdiv);
	reg2++;
	loadreg(chip2, reg2);
	write(chip2, freqdiv>>8);
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

void midi_pitch_bend(unsigned char channel, unsigned short pitch) {
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
		if(RA3) {
			char i;
			for(i=0; i<OSCILLATORS; i++) {
				chip=i/3;
				oscillator[i].note=0xFF;
				oscillator[i].time=0;
				loadreg(chip, REG_AMPA+(i%3));
				write(chip, 0x0);
			}
		}
		CREN=0;
		SPEN=0;
		SPEN=1;
		CREN=1;
		RABIF=0;
	}
}

void main() {
	unsigned char event=0, c, a, b;
	SCS=0;
	
	TRISA=0x8;
	ANSEL=0x0;
	ANSELH=0x0;
	TRISB=0x0;
	TRISC=0x0;
	PORTA=0;
	PORTB=0;
	PORTC=0;
	
	for(a=0; a<OSCILLATORS; a++) {
		oscillator[a].note=0xFF;
		oscillator[a].time=0x0;
	}
	
	/*midi baudrate, 31250*/
	SPBRG=9;
	//SPBRG=51;
	BRGH=0;
	TXEN=0;
	CREN=0;
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
	
	IOCA3=1;
	INTCON=0x88;
	
	CREN=1;
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
				//if(RB4)
				midi_pitch_bend(event&0xF, (((short) b)<<7)|a);
				break;
			case 0xC0:
				/*program change*/
			case 0xD0:
				/*channel after-touch*/
				break;
			case 0xF0:
				/*sysex*/
				while(a!=0xF7)
					a=recv();
				break;
		}
		current++;
	}
}
