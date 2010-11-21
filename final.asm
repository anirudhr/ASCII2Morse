include c:\tasm\table.asm

;segment containing procedures to manipulate the output buffer
procedures segment
assume cs:procedures, ds:data
adjuster proc far
;adjuster checks if cl, which represents the position within the byte of the bit to be written,
;is greater than 8 (ie. if we need to switch to the next byte).
;If yes, it increments bp, which represents the position in the output buffer of the byte to be written
;and decrements cl by 8. If no, it does nothing.
        cmp cl,08
        jl ENDADJ
        inc bp
        sub cl,08
        cmp bp, BUFFERLENGTH
        jnz ENDADJ
        mov bp, 00h
ENDADJ:
ret
adjuster endp

adjuster2 proc far
;adjuster2 checks if cl, which represents the position within the byte
;of the bit to be read, is greater than 8 (ie. if we need to switch to the next byte).
;If yes, it increments bx, which represents the position in the output buffer of the byte
;being read and decrements cl by 8.
;If no, it does nothing.

        cmp cl,08
        jl ENDADJ2
        inc bx
        sub cl,08
        cmp bx, BUFFERLENGTH
        jnz ENDADJ2
        mov bx, 00h
ENDADJ2:
ret
adjuster2 endp

shlm1 proc far
;shlm1, "shift left manipulator 1", shifts 2 bits to the left by 6 minus the bitloc value using the shl command.
;The 2 bits represent a dot (10) or a space between the morse representation for two ASCII characters (00).
;It then adds the manipulated byte to the output buffer outb[], ie. to ax.
;(bitloc value for the various positions in a byte: 01234567)

        push cx
        push bp
        push ax
	push dx
                mov bp,outblen
                mov al,outb[bp+00]
                mov cl,06d
                sub cl,bitloc
                ;cl now has the value of the number of shl operations
                shl bl,cl

		mov dl, 0ffh
		mov cl, 08
		sub cl, bitloc
		shl dl, cl
		and al, dl

                or al,bl
                mov outb[bp+00],al
                mov cl,bitloc
                add cl,02
                call adjuster
                mov bitloc,cl
                mov outblen,bp
	pop dx
        pop ax
        pop bp
        pop cx
ret
shlm1 endp

shlm2 proc far
;shlm2, "shift left manipulator 2", is used when a dash (1110) needs to be written to the output buffer.
;It is a modification of shlm1 in order to manipulate 4 bits instead of 2.
        push cx
        push bp
        push ax
	push dx
                mov bp,outblen
                mov al,outb[bp+00]
                mov cl,06d
                sub cl,bitloc
                ;cl now has the value of the number of shl operations
                mov bl,11b
                shl bl,cl

;MASK BEGINS
		mov dl, 0ffh
		mov cl, 08
		sub cl, bitloc
		shl dl, cl
		and al, dl
;MASK ENDS
;Masking is done in order to clear the bits that have been read, without affecting the new ones.

                or al,bl
                mov outb[bp+00],al
                mov cl,bitloc
                add cl,02
                call adjuster
                mov bitloc,cl
;A few lines of code from shlm1 have been commented out,
;to show how we are optimising the program, by not
;calling shlm1 twice but writing a new procedure.

                	;mov outblen,bp
                	;mov bp,outblen
                	;mov ax,outb[bp+00]
        	        ;mov cl,06d
	                ;sub cl,bitloc
                mov al,06
                sub al,cl
                mov cl,al
                mov al,outb[bp+00]
                ;cl now has the value of the number of shl operations
                mov bl,10b
                shl bl,cl

		mov dl, 0ffh
		mov cl, 08
		sub cl, bitloc
		shl dl, cl
		and al, dl

                or al,bl
                mov outb[bp+00],al
                mov cl,bitloc
                add cl,02
                call adjuster
                mov bitloc,cl
                mov outblen,bp
	pop dx
        pop ax
        pop bp
        pop cx
ret
shlm2 endp
procedures ends

;segment containing procedures to output to the LED
output segment
assume cs:output, ds:data
dotproc proc near
        push ax
        push dx
        mov al, 7fh	;CWR for bit-set-reset mode to set bit 7 of Port C
        mov dx, 0e003h	;Address for the Port C

;        out dx, al 	;this is the output to the LED

        pop dx
        pop ax
        ret
dotproc endp

nopproc proc near
        push ax
        push dx
        mov al, 7eh	;CWR for bit-set-reset mode to clear bit 7 of Port C
        mov dx, 0e003h	;Address for the Port C

;	out dx, al 	;this is the (blank) output to the LED

        pop dx
        pop ax
        ret
nopproc endp

disp proc far
        push ax
        push bx
        push cx
        push dx
        mov bx, outbmarker
        mov al,outb[bx]
        mov cl,bitlocr
        cmp bx, outblen
        jnz fine
        cmp cl,bitloc
        jz stop

        fine: 		; actual output
        mov ch,80h	; to find out if output is dot(1) or character space(0)
        shr ch,cl
        and al,ch
        cmp al,00
        jz zero

        ;mov dl,'1'
        ;mov ah,06h
        ;int 21h

        call dotproc
        jmp endloop

        zero:

        ;mov dl,'0'
        ;mov ah,06h
        ;int 21h

        call nopproc
        endloop:
        mov cl,bitlocr
        inc cl
        call adjuster2
        mov bitlocr,cl
        mov outbmarker,bx

        stop:
        pop dx
        pop cx
        pop bx
        pop ax
ret
disp endp
output ends

;
code segment
assume cs:code, ds: data
start:
        mov ax,data	 
        mov ds,ax	;initialise data segment

        mov si, 0h	; si and di used as counters to implement delay
        mov di, 1h

        hop2:
	;check whether or not a key is pressed
        mov ah,01h
        int 16h
        jz dispbit1

	;input
        mov ah,07h
        int 21h

        ;push ax
	;to flush keyboard buffer
        ;mov ax,0c00h
        ;int 21h
        ;pop ax
     
        xor ah,ah
        ;loads bx with the base value of the translation table, for xlat
        lea bx,A     
        ;checks if the input is the space key
                cmp al,' '
                jz spc
        ;checks if the input is an alphabet
        cmp al, 61h
        jl s1
        cmp al, 7ah
        jg dispbit1
        
        ;translates the alphabet into its equivalent morse code representation 
        sub al,'a'
        shl al,01
        mov ah,al
        inc al
        xlat
        xchg ah,al
        xlat
        jmp s2

        s1:
        ;if the input is the enter key
	cmp al, 30h
        jl entercheck
        cmp al, 39h
        jg dispbit1

        ;translates the digit into its equivalent morse code representation 
        sub al,'0'
        shl al,01
        add al,52d
        mov ah,al
        inc al
        xlat
        xchg ah,al
        xlat
        jmp s2

        entercheck:
	;if the enter key is pressed then it quits the program 
	;after reading through the remaining contents of the output buffer
        cmp al, 0dh
        jz quit1
        jmp dispbit1

;circular queue implementation for the output buffer
s2:
        mov bx, outbmarker
        sub bx, outblen  ;R-W
        jg CMP2          ;the write head hasn't wrapped around/both have
        add bx, BUFFERLENGTH
;to reject inputs when the buffer is full
CMP2:
	cmp bx, 4
        jge s3           ;buffer not full, input and display functions continue normally
 
       ;REJECTOR
        push ax
        mov dl,'R'
        mov ah,06h
        int 21h
        jmp dispbit1
        pop ax


;after the xlat operations, ax has the morse (binary) word
;to compare two bits at a time and to switch the values as given: 00 = 10, 01 = 1110, 10 = 00
s3:

mov dx, ax
;to extract two bits at a time
mov bp, 0C000h ; 1100 0000 0000 0000 in binary


jmp l1

;used to accommodate far jumps
dispbit1: jmp dispbit
quit1: jmp quit
hop1: jmp hop2

l1:
mov cl, 02      ;each time, shift the data by two bits to the left
and dx,bp
cmp dx,0000h    ;if the buffer contains a 00 (dot)
je  dot
cmp dx,4000h    ;if the buffer contains a 01 (dash)
je  dash
cmp dx,8000h    ;if the buffer contains a 10 (character space)
je  chrspc
;at this point, it has jumped no matter what, because we control the value of dx internally
;for dot and chr space, we use procedure shlm1
;for dash, we use procedure shlm2

;a word space (if the space key is pressed) is equivalent to 3 character spaces
spc:
push cx
push ax
push dx
mov cx,02
lpspc:
        mov bx,00b
        call shlm1
        mov dl, 's'
        mov ah,06
        int 21h
loop lpspc
pop dx
pop ax
pop cx
jmp dispbit

dot:
;concatenate 10 to outb using shlm1 to represent a dot
mov bx,10b
call shlm1
push dx
push ax
mov dl, '.'
mov ah,06      ;outputs a dot onto the monitor
int 21h
pop ax
pop dx
jmp l2

dash:
;concatenate 1110 to outb using shlm2 to represent a dash
call shlm2
push dx
push ax
mov dl, '-'
mov ah,06      ;outputs a dash onto the monitor
int 21h
pop ax
pop dx
jmp l2

chrspc:
;concatenate 00 to outb using shlm1 to represent a character space
mov bx,00b
call shlm1
push ax
push dx
mov dl, 's'
mov ah,06      ;outputs an 's' onto the monitor to represent end of character
int 21h
pop dx
pop ax
jmp l3

hop3: jmp hop1
l2:
;loops back to the beginning of translation of morse code representation to the output
shl ax,cl
mov dx,ax
jmp l1

l3:
;to call the disp procedure for outputting to the LED
dispbit:
;to implement appropriate delay to make the morse output readable
        dec di
        cmp di, 00
        jnz DECREMENT
        cmp si, 00
        jnz DECREMENT
call disp
        mov si, 0004h ;0000h;
        mov di, 2fffh ;05fffh;
DECREMENT:
        cmp di, 00
        jnz hop3
        dec si
jmp hop3

quit:
;the entire program is run on an infinite loop until the enter key is pressed
loop1:
        call disp
        mov bx, outbmarker
        mov al,outb[bx]
        mov cl,bitlocr
        cmp bx, outblen
        jnz loop1
        cmp cl,bitloc
        jnz loop1
mov ax,4c00h
int 21h

code ends
end start