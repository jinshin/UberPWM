		.model tiny
		.code
		org 100h
begin:		jmp start

int08_offset	equ 08h*4
old08		dw 0,0

int08_handler:

;4Bh    01001011
;Connect speaker to channel 2
;It sets it to High or Low depending of channel state
                mov     al,cl
                out     61h,al
;Disconnect from channel 2         
;ChatGPT says it will stay in state of channel 2
                dec     al		
		out     61h,al

;load value, increase pointer, decrease counter
                mov	al,[bx]

		inc	bx
		dec	bp
                jz      short terminate

;original code: out     41h,ax
;this translated to out 41h,al; mov al,ah; out 42h,al
;Three commands in one


;Mode 1: Programmable One-Shot
;Mode 1 operates as a square wave generator.
;The timer counts down from the initial count value to zero, then toggles its output state
;and automatically reloads the count value for the next cycle.

;Load MSB value to channel 2 counter
;Generate a Low for duration, then stay High until reloaded
;at this time, Channel 2 is not connected to speaker
		out	42h,al

		mov	al,ch
		;Signal EOI		
                out     20h,al
		;avoid stack overflow
        	add	sp,si
                sti
                hlt

ethernal_wait:                 
                in      al,20h
                and     al,1
                jnz     short ethernal_wait
                hlt
                jmp     short ethernal_wait

;Outro
terminate:
                cli

                mov     al,54h
                out     43h,al         
                mov     al,12h
                out     41h,al         
                mov     al,36h
                out     43h,al
                mov     al,0
                out     40h,al 
                out     40h,al 
                mov     al,0B6h
                out     43h,al         
                mov     ax,533h
                out     42h,al         
                mov     al,ah
                out     42h,al         
                mov     al,48h
                out     61h,al
                mov     al,0BCh
                out     21h,al
                mov     al,20h
                out     20h,al

		cld
		xor	ax,ax
		mov	es,ax
		mov	di,int08_offset
		mov	ax,old08		
		stosw
		mov	ax,old08+2
		stosw

		sti 

;Bye!
                int     20h             

start:

		cli
		cld
		xor 	ax,ax
	        mov     ds,ax
       		push    cs
        	pop     es
        	mov     si,int08_offset
        	mov     di,offset old08
        	movsw
        	movsw
        	push    ds
        	pop     es
        	mov     di,int08_offset
        	mov     ax,offset int08_handler
        	stosw
        	mov     ax,cs
        	stosw

		;Original code used bx as a pointer
		mov	bx,offset wavestart
		;Counter
		mov     bp,offset waveend - offset wavestart

		mov	al,36h
;Set timer channel 0,Square wave,LSB and MSB
;Chann  Seq     Mode    Bin/BCD
;00	11	011	0
		out	43h,al

;Set channel 0 to 18356Hz
;1193180/18356 = 65

		mov	ax,41h
		out	40h,al
		mov	al,ah
		out	40h,al

;Mode 1: Programmable One-Shot
;Mode 1 operates as a square wave generator.
;The timer counts down from the initial count value to zero, then toggles its output state to High

;Channel 2, MSB only, Square Wave One-Shot

		mov	al,92h
		;10 01 001 0
		out	43h,al

		in	al,61h
		;Turn speaker on
		or	al,2
		out	61h,al

		mov	al,0ah ;?
		out	20h,al

		xor	dx,dx
		mov	dh,1

		mov	ch,20h ;555Hz?

		mov	cl,4Bh ;value for port 61h

		;Clever trick to avoid stack overflow
		;SI will be added to SP in int08 handler
		mov	si,6 

		push	cs
		pop	ds

		sti
		jmp ethernal_wait
		
wavestart:
		include chimes4.inc
waveend:

		end begin	
