TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN
	SAUM			db		'Segment address of unavailable memory:     ',0dh,0ah,'$'
	SAE				db		'Segment address of environment:     ',0dh,0ah,'$'
	TCS				db		'Tail of command string:','$'
	CE				db		'Contents of the environment: ' , '$'
	WtM				db		'Way to module: ' , '$'
	ENDL			db		0dh,0ah,'$'

TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC near
; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; в AL старшая цифра
		pop		cx 			; в AH младшая
		ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC	near
; первод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
; Определение первого байта недоступной памяти
SegAdrUnavMem		PROC	near
		push	ax
		mov 	ax,es:[2]
		lea		di,SAUM
		add 	di,42
		call	WRD_TO_HEX
		pop		ax
		ret
SegAdrUnavMem		ENDP
; Определение сегментного адреса среды передаваемой программе
SegAdrEnv		PROC	near
		push	ax
		mov 	ax,es:[2Ch]
		lea		di,SAE
		add 	di,35
		call	WRD_TO_HEX
		pop		ax
		ret
SegAdrEnv		ENDP
; Определение хвоста командной строки в символьном виде
TailComStr		PROC	near 
		push	ax
		push	cx
		lea 	dx, TCS   
    	call 	Write 
    	xor 	ax, ax
		xor 	cx, cx
		mov 	cl, es:[80h]
		test 	cl, cl
		je		empty
		xor 	di,	di
NextSymb:
		mov 	dl, es:[81h+di]
		mov 	ah, 02h
		int 	21h
		inc 	di
		loop	NextSymb

empty:
		lea		dx, ENDL
		call	Write
    	pop		cx
    	pop		ax
		ret
TailComStr		ENDP
; Определение содержимого области среды и пути к модулю
ContentsEnv	PROC	near
		push 	es 
		push	ax 
		push	bx 
		push	cx 
		lea		dx,CE 
		call	Write  
		mov		bx,1 ; checker
		mov		es,es:[2ch] 
		mov		si,0
NextEl:
		lea		dx,ENDL
		call	Write
		mov		ax,si 
EndNotFound:
		cmp 	byte ptr es:[si], 0
		je 		EndElemArea 
		inc		si
		jmp 	EndNotFound 
EndElemArea:
		push	es:[si]
		mov		byte ptr es:[si], '$' 
		push	ds 
		mov		cx,es 
		mov		ds,cx 
		mov		dx,ax 
		call	Write 
		pop		ds 
		pop		es:[si] 
		cmp		bx,0 
		je 		FINAL
		inc		si
		cmp 	byte ptr es:[si], 01h 
    	jne 	NextEl 
    	lea		dx,WtM 
    	call	Write 
    	mov		bx,0
    	add 	si,2 
    	jmp 	NextEl
FINAL:
		pop		cx 
		pop		bx 
		pop		ax 
		pop		es 
		ret
ContentsEnv	ENDP

Write		PROC	near
		mov		ah,09h
		int		21h
		ret
Write		ENDP

BEGIN:
		call	SegAdrUnavMem 
		call	SegAdrEnv 
		lea		dx,SAUM   
		call	Write  
		lea		dx,SAE   
		call	Write 
    	call	TailComStr 
		call	ContentsEnv 
		
		mov AH, 01h 
		int 21h
; выход в DOS
		xor		al,al
		mov 	ah, 04Ch
		int 	21h
		ret
TESTPC	ENDS
		END 	START