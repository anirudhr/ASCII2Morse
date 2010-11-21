;this segment contains the translation table from ASCII to morse code representation
data segment
A  dw 0001100000000000b
B  dw 0100000010000000b
C  dw 0100010010000000b
D  dw 0100001000000000b
E  dw 0010000000000000b
F  dw 0000010010000000b
G  dw 0101001000000000b
H  dw 0000000010000000b
I  dw 0000100000000000b
J  dw 0001010110000000b
K  dw 0100011000000000b
L  dw 0001000010000000b
M  dw 0101100000000000b
N  dw 0100100000000000b
O  dw 0101011000000000b
P  dw 0001010010000000b
Q  dw 0101000110000000b
R  dw 0001001000000000b
S  dw 0000001000000000b
T  dw 0110000000000000b
U  dw 0000011000000000b
V  dw 0000000110000000b
W  dw 0001011000000000b
X  dw 0100000110000000b
Y  dw 0100010110000000b
Z  dw 0101000010000000b
n0 dw 0101010101100000b
n1 dw 0001010101100000b
n2 dw 0000010101100000b
n3 dw 0000000101100000b
n4 dw 0000000001100000b
n5 dw 0000000000100000b
n6 dw 0100000000100000b
n7 dw 0101000000100000b
n8 dw 0101010000100000b
n9 dw 0101010100100000b

BUFFERLENGTH EQU 100

outbmarker dw 0         	;marks the byte position upto which the output has been read
bitlocr db 0            	;stores the bit location within the byte to be read from
outblen dw 0            	;stores the position of the byte in outb to be written
outb db BUFFERLENGTH dup (0) 	;output buffer of length 100
bitloc db 0             	;stores the bit location within the byte to write to output buffer
data ends