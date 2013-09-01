;config
	list	p=16f690
	radix	dec
	include	"p16f690.inc"
	
;flags
C	EQU 0
DC	EQU 1
Z 	EQU 2
IRP 	EQU 7

;macros
addshort macro a, b, c
	movf	a, W
	addwf	b, W
	movwf	c
	movf	(b+1), W
	movwf	(c+1)
	movf	(a+1), W
	btfsc	STATUS, C
	incf	(a+1), W
	btfss	STATUS, Z
	addwf	(c+1), F
	endm

subshort macro a, b, c
	movf	a, W
	subwf	b, W
	movwf	c
	movf	(a+1), W
	btfss	STATUS, C
	incf	(a+1), W
	subwf	(b+1), W
	movwf	(c+1)
	endm

;externs
	extern PSAVE
	extern SSAVE
	extern WSAVE
	extern STK12
	extern STK11
	extern STK10
	extern STK09
	extern STK08
	extern STK07
	extern STK06
	extern STK05
	extern STK04
	extern STK03
	extern STK02
	extern STK01
	extern STK00
	
	extern _oscillator

;data
data_pitchbend udata
channel	res 1
note	res 1
pitch	res 2
temp	res 4

;code
code_pitchbend code
;void midi_pitchbend(unsigned char channel, unsigned short pitch)
_midi_pitch_bend
	banksel channel
	movwf	channel
	movf	STK00, W
	movwf	pitch
	movf	STK01, W
	movwf	(pitch+1)
	
	
	movf	_oscillator, W
	addlw	6*4
	movwf	FSR
	
next_oscillator
	movlw	3
	subwf	FSR, F
	
	;channel
	banksel channel
	movf	channel, W
	banksel	_oscillator
	xorwf	INDF, W
	btfss	STATUS, Z
	goto	next_oscillator
	
	decf	FSR, F
	;note
	movf	INDF, W
	movwf	note
	xorlw	0xFF
	btfsc	STATUS, Z
	goto	next_oscillator
	banksel channel
	
	
	
	movf	FSR, W
	sublw	_oscillator
	btfss	STATUS, Z
	goto next_oscillator
	
	return
	
end
; 2 exit points
;	.line	287; "midi.c"	void midi_pitch_bend(unsigned short pitch, unsigned char channel) {
	BANKSEL	r0x101F
	MOVWF	r0x101F
	MOVF	STK00,W
	MOVWF	r0x1020
	MOVF	STK01,W
	MOVWF	r0x1021
;	.line	294; "midi.c"	for(i=0; i<OSCILLATORS; i++) {
	CLRF	r0x1022
;unsigned compare: left < lit(0x6=6), size=1
_00182_DS_
	MOVLW	0x06
	BANKSEL	r0x1022
	SUBWF	r0x1022,W
	BTFSC	STATUS,0
	GOTO	_00186_DS_
;genSkipc:3083: created from rifx:0x7ffff53d3e30
;	.line	295; "midi.c"	if(oscillator[i].note!=0xFF&&oscillator[i].channel==channel) {
	MOVLW	0x04
	MOVWF	STK00
	MOVF	r0x1022,W
	PAGESEL	__mulchar
	CALL	__mulchar
	PAGESEL	$
	BANKSEL	r0x1023
	MOVWF	r0x1023
	ADDLW	(_oscillator + 0)
	MOVWF	r0x1024
	MOVLW	high (_oscillator + 0)
	BTFSC	STATUS,0
	ADDLW	0x01
	MOVWF	r0x1025
	MOVF	r0x1024,W
	MOVWF	FSR
	BCF	STATUS,7
	BTFSC	r0x1025,0
	BSF	STATUS,7
	MOVF	INDF,W
	MOVWF	r0x1026
	XORLW	0xff
	BTFSC	STATUS,2
	GOTO	_00184_DS_
	MOVF	r0x1023,W
	ADDLW	(_oscillator + 0)
	MOVWF	r0x1024
	MOVLW	high (_oscillator + 0)
	BTFSC	STATUS,0
	ADDLW	0x01
	MOVWF	r0x1025
	INCF	r0x1024,F
	BTFSC	STATUS,2
	INCF	r0x1025,F
	MOVF	r0x1024,W
	MOVWF	FSR
	BCF	STATUS,7
	BTFSC	r0x1025,0
	BSF	STATUS,7
	MOVF	INDF,W
	MOVWF	r0x1026
	XORWF	r0x1021,W
	BTFSS	STATUS,2
	GOTO	_00184_DS_
;	.line	296; "midi.c"	chip=i/3;
	MOVLW	0x03
	MOVWF	STK00
	MOVF	r0x1022,W
	PAGESEL	__divuchar
	CALL	__divuchar
	PAGESEL	$
	BANKSEL	r0x1024
	MOVWF	r0x1024
;	.line	297; "midi.c"	note=oscillator[i].note;
	MOVF	r0x1023,W
	ADDLW	(_oscillator + 0)
	MOVWF	r0x1023
	MOVLW	high (_oscillator + 0)
	BTFSC	STATUS,0
	ADDLW	0x01
	MOVWF	r0x1025
	MOVF	r0x1023,W
	MOVWF	FSR
	BCF	STATUS,7
	BTFSC	r0x1025,0
	BSF	STATUS,7
	MOVF	INDF,W
	MOVWF	r0x1026
;	.line	298; "midi.c"	if(pitch==0x2000) {
	MOVF	r0x1020,W
	XORLW	0x00
	BTFSS	STATUS,2
	GOTO	_00177_DS_
	MOVF	r0x101F,W
	XORLW	0x20
	BTFSS	STATUS,2
	GOTO	_00177_DS_
;	.line	299; "midi.c"	freqdiv2=midi_freqdiv[note];
	MOVLW	0x02
	MOVWF	STK00
	MOVF	r0x1026,W
	
	RRF	r0x1026, 1
	BCF	STATUS, 1
	
	BANKSEL	r0x1023
	MOVWF	r0x1023
	CLRF	r0x1025
	MOVF	r0x1023,W
	ADDLW	(_midi_freqdiv + 0)
	MOVWF	r0x1023
	MOVLW	0x00
	BTFSC	STATUS,0
	INCFSZ	r0x1025,W
	ADDLW	high (_midi_freqdiv + 0)
	MOVWF	r0x1025
	MOVF	r0x1023,W
	MOVWF	STK01
	MOVF	r0x1025,W
	MOVWF	STK00
	MOVLW	0x80
	PAGESEL	__gptrget2
	CALL	__gptrget2
	PAGESEL	$
	BANKSEL	r0x1027
	MOVWF	r0x1027
	MOVF	STK00,W
	MOVWF	r0x1028
	GOTO	_00178_DS_
;swapping arguments (AOP_TYPEs 1/2)
;unsigned compare: left >= lit(0x2001=8193), size=2
_00177_DS_
;	.line	300; "midi.c"	} else if(pitch>0x2000) {
	MOVLW	0x20
	BANKSEL	r0x101F
	SUBWF	r0x101F,W
	BTFSS	STATUS,2
	GOTO	_00197_DS_
	MOVLW	0x01
	SUBWF	r0x1020,W
_00197_DS_
	BTFSS	STATUS,0
	GOTO	_00174_DS_
;genSkipc:3083: created from rifx:0x7ffff53d3e30
;	.line	302; "midi.c"	pitch-=0x2000;
	MOVLW	0xe0
	BANKSEL	r0x101F
	ADDWF	r0x101F,F
;	.line	303; "midi.c"	freqdiv1=midi_freqdiv[note];
	MOVLW	0x02
	MOVWF	STK00
	MOVF	r0x1026,W
	PAGESEL	__mulchar
	CALL	__mulchar
	PAGESEL	$
	BANKSEL	r0x1023
	MOVWF	r0x1023
	CLRF	r0x1025
	MOVF	r0x1023,W
	ADDLW	(_midi_freqdiv + 0)
	MOVWF	r0x1023
	MOVLW	0x00
	BTFSC	STATUS,0
	INCFSZ	r0x1025,W
	ADDLW	high (_midi_freqdiv + 0)
	MOVWF	r0x1025
	MOVF	r0x1023,W
	MOVWF	STK01
	MOVF	r0x1025,W
	MOVWF	STK00
	MOVLW	0x80
	PAGESEL	__gptrget2
	CALL	__gptrget2
	PAGESEL	$
	BANKSEL	r0x1029
	MOVWF	r0x1029
	MOVF	STK00,W
	MOVWF	r0x102A
;	.line	304; "midi.c"	freqdiv2=midi_freqdiv[note+2];
	MOVLW	0x02
	ADDWF	r0x1026,W
	MOVWF	r0x1023
	MOVLW	0x02
	MOVWF	STK00
	MOVF	r0x1023,W
	PAGESEL	__mulchar
	CALL	__mulchar
	PAGESEL	$
	BANKSEL	r0x102B
	MOVWF	r0x102B
	CLRF	r0x102C
	MOVF	r0x102B,W
	ADDLW	(_midi_freqdiv + 0)
	MOVWF	r0x1023
	MOVLW	high (_midi_freqdiv + 0)
	MOVWF	r0x102D
	MOVLW	0x00
	BTFSC	STATUS,0
	INCFSZ	r0x102C,W
	ADDWF	r0x102D,F
	MOVF	r0x1023,W
	MOVWF	STK01
	MOVF	r0x102D,W
	MOVWF	STK00
	MOVLW	0x80
	PAGESEL	__gptrget2
	CALL	__gptrget2
	PAGESEL	$
	BANKSEL	r0x1027
	MOVWF	r0x1027
	MOVF	STK00,W
;	.line	306; "midi.c"	freqdiv2=(freqdiv1-freqdiv2);
	MOVWF	r0x1028
	SUBWF	r0x102A,W
	MOVWF	r0x1028
	MOVF	r0x1027,W
	BTFSS	STATUS,0
	INCF	r0x1027,W
	SUBWF	r0x1029,W
	MOVWF	r0x102B
	MOVWF	r0x1027
;;133	MOVF	r0x1028,W
;;129	MOVF	r0x1027,W
;	.line	307; "midi.c"	temp=freqdiv2;
	CLRF	r0x102C
	CLRF	r0x102D
;;131	MOVF	r0x1020,W
;;123	MOVF	r0x101F,W
;	.line	308; "midi.c"	temp*=pitch;
	CLRF	r0x1030
	CLRF	r0x1031
;;130	MOVF	r0x102E,W
	MOVF	r0x1020,W
	MOVWF	r0x102E
	MOVWF	STK06
;;122	MOVF	r0x102F,W
	MOVF	r0x101F,W
	MOVWF	r0x102F
	MOVWF	STK05
	MOVLW	0x00
	MOVWF	STK04
	MOVLW	0x00
	MOVWF	STK03
;;132	MOVF	r0x1023,W
	MOVF	r0x1028,W
	MOVWF	r0x1023
	MOVWF	STK02
	MOVF	r0x102B,W
	MOVWF	STK01
	MOVLW	0x00
	MOVWF	STK00
	MOVLW	0x00
	PAGESEL	__mullong
	CALL	__mullong
	PAGESEL	$
	BANKSEL	r0x102D
	MOVWF	r0x102D
	MOVF	STK00,W
	MOVWF	r0x102C
	MOVF	STK01,W
	MOVWF	r0x102B
	MOVF	STK02,W
	MOVWF	r0x1023
;	.line	309; "midi.c"	temp>>=13;
	SWAPF	r0x102B,W
	ANDLW	0x0f
	MOVWF	r0x1023
	SWAPF	r0x102C,W
	MOVWF	r0x102B
	ANDLW	0xf0
	IORWF	r0x1023,F
	XORWF	r0x102B,F
	SWAPF	r0x102D,W
	MOVWF	r0x102C
	ANDLW	0xf0
	IORWF	r0x102B,F
	XORWF	r0x102C,F
	CLRF	r0x102D
;shiftRight_Left2ResultLit:4862: shCount=1, size=4, sign=0, same=1, offr=0
	BCF	STATUS,0
	RRF	r0x102D,F
	RRF	r0x102C,F
	RRF	r0x102B,F
	RRF	r0x1023,F
;;111	MOVF	r0x1023,W
;;113	MOVF	r0x102B,W
;;110	MOVF	r0x1028,W
;	.line	311; "midi.c"	freqdiv2=freqdiv1-freqdiv2;
	MOVF	r0x1023,W
	MOVWF	r0x1028
	SUBWF	r0x102A,W
	MOVWF	r0x1028
;;112	MOVF	r0x1027,W
	MOVF	r0x102B,W
	MOVWF	r0x1027
	BTFSS	STATUS,0
	INCF	r0x1027,W
	SUBWF	r0x1029,W
	MOVWF	r0x1027
	GOTO	_00178_DS_
_00174_DS_
;	.line	314; "midi.c"	pitch=0x2000-pitch;
	BANKSEL	r0x1020
	MOVF	r0x1020,W
	SUBLW	0x00
	MOVWF	r0x1020
	MOVF	r0x101F,W
	BTFSS	STATUS,0
	INCF	r0x101F,W
	SUBLW	0x20
	MOVWF	r0x101F
;	.line	315; "midi.c"	freqdiv1=midi_freqdiv[note-2];
	MOVLW	0xfe
	ADDWF	r0x1026,W
	MOVWF	r0x102E
	MOVLW	0x02
	MOVWF	STK00
	MOVF	r0x102E,W
	PAGESEL	__mulchar
	CALL	__mulchar
	PAGESEL	$
	BANKSEL	r0x102F
	MOVWF	r0x102F
	CLRF	r0x1030
	MOVF	r0x102F,W
	ADDLW	(_midi_freqdiv + 0)
	MOVWF	r0x102E
	MOVLW	high (_midi_freqdiv + 0)
	MOVWF	r0x1031
	MOVLW	0x00
	BTFSC	STATUS,0
	INCFSZ	r0x1030,W
	ADDWF	r0x1031,F
	MOVF	r0x102E,W
	MOVWF	STK01
	MOVF	r0x1031,W
	MOVWF	STK00
	MOVLW	0x80
	PAGESEL	__gptrget2
	CALL	__gptrget2
	PAGESEL	$
	BANKSEL	r0x1029
	MOVWF	r0x1029
	MOVF	STK00,W
	MOVWF	r0x102A
;	.line	316; "midi.c"	freqdiv2=midi_freqdiv[note];
	MOVLW	0x02
	MOVWF	STK00
	MOVF	r0x1026,W
	PAGESEL	__mulchar
	CALL	__mulchar
	PAGESEL	$
	BANKSEL	r0x102E
	MOVWF	r0x102E
	CLRF	r0x1031
	MOVF	r0x102E,W
	ADDLW	(_midi_freqdiv + 0)
	MOVWF	r0x1026
	MOVLW	high (_midi_freqdiv + 0)
	MOVWF	r0x102F
	MOVLW	0x00
	BTFSC	STATUS,0
	INCFSZ	r0x1031,W
	ADDWF	r0x102F,F
	MOVF	r0x1026,W
	MOVWF	STK01
	MOVF	r0x102F,W
	MOVWF	STK00
	MOVLW	0x80
	PAGESEL	__gptrget2
	CALL	__gptrget2
	PAGESEL	$
	BANKSEL	r0x1027
	MOVWF	r0x1027
	MOVF	STK00,W
;	.line	318; "midi.c"	freqdiv1=(freqdiv1-freqdiv2);
	MOVWF	r0x1028
	SUBWF	r0x102A,F
	MOVF	r0x1027,W
	BTFSS	STATUS,0
	INCFSZ	r0x1027,W
	SUBWF	r0x1029,F
;;128	MOVF	r0x102A,W
;;119	MOVF	r0x1029,W
;	.line	319; "midi.c"	temp=freqdiv1;
	CLRF	r0x102C
	CLRF	r0x102D
;;109	MOVF	r0x1020,W
;;121	MOVF	r0x101F,W
;	.line	320; "midi.c"	temp*=pitch;
	CLRF	r0x102F
	CLRF	r0x1030
;;108	MOVF	r0x1026,W
	MOVF	r0x1020,W
	MOVWF	r0x1026
	MOVWF	STK06
;;120	MOVF	r0x102E,W
	MOVF	r0x101F,W
	MOVWF	r0x102E
	MOVWF	STK05
	MOVLW	0x00
	MOVWF	STK04
	MOVLW	0x00
	MOVWF	STK03
;;127	MOVF	r0x1023,W
	MOVF	r0x102A,W
	MOVWF	r0x1023
	MOVWF	STK02
;;118	MOVF	r0x102B,W
	MOVF	r0x1029,W
	MOVWF	r0x102B
	MOVWF	STK01
	MOVLW	0x00
	MOVWF	STK00
	MOVLW	0x00
	PAGESEL	__mullong
	CALL	__mullong
	PAGESEL	$
	BANKSEL	r0x102D
	MOVWF	r0x102D
	MOVF	STK00,W
	MOVWF	r0x102C
	MOVF	STK01,W
	MOVWF	r0x102B
	MOVF	STK02,W
	MOVWF	r0x1023
;	.line	321; "midi.c"	temp>>=13;
	SWAPF	r0x102B,W
	ANDLW	0x0f
	MOVWF	r0x1023
	SWAPF	r0x102C,W
	MOVWF	r0x102B
	ANDLW	0xf0
	IORWF	r0x1023,F
	XORWF	r0x102B,F
	SWAPF	r0x102D,W
	MOVWF	r0x102C
	ANDLW	0xf0
	IORWF	r0x102B,F
	XORWF	r0x102C,F
	CLRF	r0x102D
;shiftRight_Left2ResultLit:4862: shCount=1, size=4, sign=0, same=1, offr=0
	BCF	STATUS,0
	RRF	r0x102D,F
	RRF	r0x102C,F
	RRF	r0x102B,F
	RRF	r0x1023,F
;;115	MOVF	r0x1023,W
;;117	MOVF	r0x102B,W
;;114	MOVF	r0x102A,W
;	.line	323; "midi.c"	freqdiv2=freqdiv2+freqdiv1;
	MOVF	r0x1023,W
	MOVWF	r0x102A
	ADDWF	r0x1028,F
;;116	MOVF	r0x1029,W
	MOVF	r0x102B,W
	MOVWF	r0x1029
	BTFSC	STATUS,0
	INCFSZ	r0x1029,W
	ADDWF	r0x1027,F
_00178_DS_
;	.line	326; "midi.c"	loadreg(chip, (i%3)<<1);
	MOVLW	0x03
	MOVWF	STK00
	BANKSEL	r0x1022
	MOVF	r0x1022,W
	PAGESEL	__moduchar
	CALL	__moduchar
	PAGESEL	$
	BANKSEL	r0x1023
	MOVWF	r0x1023
	BCF	STATUS,0
	RLF	r0x1023,W
	MOVWF	r0x1026
	MOVWF	STK00
	MOVF	r0x1024,W
	CALL	_loadreg
;	.line	327; "midi.c"	write(chip, freqdiv2);
	BANKSEL	r0x1028
	MOVF	r0x1028,W
	MOVWF	r0x1023
	MOVWF	STK00
	MOVF	r0x1024,W
	CALL	_write
;	.line	328; "midi.c"	loadreg(chip, ((i%3)<<1)+1);
	BANKSEL	r0x1026
	INCF	r0x1026,F
	MOVF	r0x1026,W
	MOVWF	STK00
	MOVF	r0x1024,W
	CALL	_loadreg
;;107	MOVF	r0x1027,W
;	.line	329; "midi.c"	write(chip, freqdiv2>>8);
	BANKSEL	r0x1026
	CLRF	r0x1026
;;106	MOVF	r0x1023,W
	MOVF	r0x1027,W
	MOVWF	r0x1023
	MOVWF	r0x1028
	MOVWF	STK00
	MOVF	r0x1024,W
	CALL	_write
_00184_DS_
;	.line	294; "midi.c"	for(i=0; i<OSCILLATORS; i++) {
	BANKSEL	r0x1022
	INCF	r0x1022,F
	GOTO	_00182_DS_
_00186_DS_
	RETURN	
; exit point of _midi_pitch_bend
