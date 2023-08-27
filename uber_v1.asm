		.model tiny
		.code
		org 100h
begin:		jmp start

int08_offset	equ 08h*4
old08		dw 0,0

int08_handler:
                ;4Bh    01001011
		;Connect speaker to channel 2
                mov     al,cl
                out     61h,al         
                dec     al
		;Disconnect from channel 2
                out     61h,al

		;new values are loaded every second call
                xor     dl,dh
                jnz     short load_next_byte

		;increase pointer, decrease counter
                inc	bx
		dec	bp
                jz      short terminate

                mov     al,ch  ;20h always
		;Notice AX out here
		;Changing to AL makes noise worse
                out     41h,ax
		;Signal EOI
                out     20h,al
		;avoid stack overflow
        	add	sp,si
                sti
                hlt

                jmp     short ethernal_wait

load_next_byte:
                mov     ax,[bx]
                add     al,ah
                shr     al,1

                out     42h,al

                mov     al,ch   ;20h always
                out     41h,al
		;Signal EOI
                out     20h,al
		;avoid stack overflow
                add	sp,si
                sti

                hlt

                jmp     short ethernal_wait


ethernal_wait:                 
                in      al,20h
                and     al,1
                jnz     short ethernal_wait
                hlt
                jmp     short ethernal_wait


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

		mov	al,36h ;Set timer channel 0,Square wave,LSB and MSB
		;Chann  Seq     Mode    Bin/BCD
		;00	11	01	0
		out	43h,al

;Set channel 0 to 18356Hz
;1193180/18356 = 65

		mov	ax,41h
		out	40h,al
		mov	al,ah
		out	40h,al

; Channel 2, MSB only, One-shot
; One-shot means speaker will be on until counter goes to 0 
		mov	al,92h
		;10 01 001 0
		out	43h,al

		in	al,61h
		;Turn speaker on
		or	al,2
		out	61h,al

;Channel 1, MSB only, Interrupt on count
 		
		mov	al,50h
		;01 01 000 0
		out	43h,al

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
		include chimes5.inc
waveend:

		end begin	


;43H  Write: set channel's mode of operation
;      ã7T6T5T4T3T2T1T0¬
;      ¦ch#¦r/l¦mode ¦ ¦
;      L-+-+-+-+-+-+-+T- bits mask
;       LT- LT- L-T-- L=>  0: 01H 0=process count as binary
;        ¦   ¦    ¦               1=process counts as BCD^
;        ¦   ¦    L=====>1-3: 0eH select timer mode:
;        ¦   ¦                    000 = mode 0: interrupt on terminal count
;        ¦   ¦                    001 = mode 1: programmable one-shot
;        ¦   ¦                    x10 = mode 2: rate generator
;        ¦   ¦                    x11 = mode 3: square-wave rate generator
;        ¦   ¦                    100 = mode 4: software-triggered strobe
;        ¦   ¦                    101 = mode 5: hardware-triggered strobe
;        ¦   L==========>4-5: 30H select read/load sequence:
;        ¦                        00 = latch counter for stable read
;        ¦                        01 = read/load most significant byte only
;        ¦                        10 = read/load least significant byte only
;        ¦                        11 = read/load LSB then MSB
;        L==============>6-7: c0H specify counter to affect:
;                                 00 = counter 0, 01= counter 1
;                                 10 = counter 2, 11= counter 3