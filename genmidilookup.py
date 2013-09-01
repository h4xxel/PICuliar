#!/usr/bin/env python
#Generate lookup table for playing midi notes on AY-3-8912
#Axel Isaksson 2013

#Frequency of soundchip in herz
frequency=1250000.0;
#Frequency of A4 note
a=440.0

print "#ifndef MIDI_H"
print "#define MIDI_H"
print
print "const unsigned short midi_freqdiv[]={"
for i in range(0, 128):
	print "	0x%x," % round((frequency/16.0)/((a/32.0)*(2.0**((float(i) - 9.0)/12.0))))
print "};"
print
print "#endif"
