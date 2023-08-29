		.model tiny
		.code
		org 100h
begin:		jmp start

int08_offset	equ 08h*4
old08		dw 0,0

int08_handler:
		lodsb
		dec	bx
                jz      short terminate

		out	42h,al

		mov	al,ch
		;Signal EOI		
                out     20h,al
		;avoid stack overflow
        	add	sp,di
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

                mov     al,48h
                out     61h,al


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
		mov	si,offset wavestart
		;Counter
		mov     bx,offset waveend - offset wavestart

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
;Channel 2, LSB only, Square Wave One-Shot

;Mode 0 tryouts
;		mov	al,92h
		mov	al,90h
		;10 01 001 0
		out	43h,al

		in	al,61h
		;Turn speaker on and connect channel 2
		or	al,3
		out	61h,al

		mov	al,0ah ;?
		out	20h,al

		xor	dx,dx
		mov	dh,1

		mov	ch,20h ;555Hz?

		mov	cl,4Bh ;value for port 61h

		;Clever trick to avoid stack overflow
		;DI will be added to SP in int08 handler
		mov	di,6 

		push	cs
		pop	ds

		sti
		jmp ethernal_wait
		
wavestart:
		include chimes4.inc
waveend:

		end begin	                    